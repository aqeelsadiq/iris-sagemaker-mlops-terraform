import argparse
import boto3
import sagemaker
from sagemaker.sklearn.model import SKLearnModel
from botocore.exceptions import ClientError


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--region", required=True)
    p.add_argument("--execution-role-arn", required=True)
    p.add_argument("--model-package-group-name", required=True)
    p.add_argument("--endpoint-name", required=True)
    p.add_argument("--instance-type", default="ml.m5.large")
    p.add_argument("--approval-status", default="Approved")
    return p.parse_args()


def endpoint_exists(sm_client, endpoint_name):
    """Check if a SageMaker endpoint already exists."""
    try:
        sm_client.describe_endpoint(EndpointName=endpoint_name)
        return True
    except ClientError as e:
        if e.response["Error"]["Code"] == "ValidationException":
            return False
        raise


def main():
    args = parse_args()
    sm = boto3.client("sagemaker", region_name=args.region)

    # ── 1. Find the latest approved model package ──────────────────────────────
    list_kwargs = dict(
        ModelPackageGroupName=args.model_package_group_name,
        SortBy="CreationTime",
        SortOrder="Descending",
        MaxResults=10,
    )

    if args.approval_status != "Any":
        list_kwargs["ModelApprovalStatus"] = args.approval_status

    resp = sm.list_model_packages(**list_kwargs)

    if not resp.get("ModelPackageSummaryList"):
        raise RuntimeError(
            f"No model packages found in group '{args.model_package_group_name}' "
            f"with status '{args.approval_status}'."
        )

    pkg_arn = resp["ModelPackageSummaryList"][0]["ModelPackageArn"]
    desc = sm.describe_model_package(ModelPackageName=pkg_arn)

    model_data = desc["InferenceSpecification"]["Containers"][0]["ModelDataUrl"]
    approval = desc.get("ModelApprovalStatus", "Unknown")

    # Pull the version number from the ARN (e.g. ".../my-group/3" → "3")
    model_version = pkg_arn.split("/")[-1]

    print(f"Using model package : {pkg_arn}")
    print(f"ApprovalStatus      : {approval}")
    print(f"ModelDataUrl        : {model_data}")
    print(f"Model version       : {model_version}")

    # ── 2. Build the SKLearn model object ──────────────────────────────────────
    sess = sagemaker.Session(boto3.Session(region_name=args.region))

    model = SKLearnModel(
        model_data=model_data,
        role=args.execution_role_arn,
        entry_point="inference.py",
        source_dir="src",
        framework_version="1.2-1",
        py_version="py3",
        sagemaker_session=sess,
    )


    versioned_model_name = f"{args.endpoint_name}-v{model_version}"

    #  Create or update the endpoint ──────────────────────────────────────
    if endpoint_exists(sm, args.endpoint_name):
        print(f"Endpoint '{args.endpoint_name}' already exists → updating it ...")

        model.name = versioned_model_name
        model._create_sagemaker_model(
            instance_type=args.instance_type,
            accelerator_type=None,
            tags=None,
        )

        # Create a new endpoint config that points to the new model.
        endpoint_config_name = f"{args.endpoint_name}-cfg-v{model_version}"
        sm.create_endpoint_config(
            EndpointConfigName=endpoint_config_name,
            ProductionVariants=[
                {
                    "VariantName": "AllTraffic",
                    "ModelName": versioned_model_name,
                    "InitialInstanceCount": 1,
                    "InstanceType": args.instance_type,
                    "InitialVariantWeight": 1,
                }
            ],
        )
        print(f"Created endpoint config: {endpoint_config_name}")

        # Swap the live endpoint to the new config (zero-downtime blue/green).
        sm.update_endpoint(
            EndpointName=args.endpoint_name,
            EndpointConfigName=endpoint_config_name,
        )
        print(f"Endpoint update initiated: {args.endpoint_name}")

    else:
        print(f"Endpoint '{args.endpoint_name}' does not exist → creating it ...")
        model.deploy(
            endpoint_name=args.endpoint_name,
            initial_instance_count=1,
            instance_type=args.instance_type,
        )
        print(f"Endpoint created: {args.endpoint_name}")

    print("Done.")


if __name__ == "__main__":
    main()