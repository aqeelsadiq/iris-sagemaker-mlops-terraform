import argparse
import boto3
import sagemaker
from sagemaker.sklearn.model import SKLearnModel


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--region", required=True)
    p.add_argument("--execution-role-arn", required=True)
    p.add_argument("--model-package-group-name", required=True)
    p.add_argument("--endpoint-name", required=True)
    p.add_argument("--instance-type", default="ml.m5.large")

    p.add_argument("--approval-status", default="Approved")
    return p.parse_args()


def main():
    args = parse_args()
    sm = boto3.client("sagemaker", region_name=args.region)

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
            f"No model packages found in group '{args.model_package_group_name}' with status '{args.approval_status}'."
        )

    pkg_arn = resp["ModelPackageSummaryList"][0]["ModelPackageArn"]
    desc = sm.describe_model_package(ModelPackageName=pkg_arn)

    model_data = desc["InferenceSpecification"]["Containers"][0]["ModelDataUrl"]
    approval = desc.get("ModelApprovalStatus", "Unknown")

    print("Using model package:", pkg_arn)
    print("ApprovalStatus:", approval)
    print("ModelDataUrl:", model_data)

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

    model.deploy(
        endpoint_name=args.endpoint_name,
        initial_instance_count=1,
        instance_type=args.instance_type,
    )

    print("Deployed endpoint:", args.endpoint_name)


if __name__ == "__main__":
    main()