
#this is working
# import argparse
# import boto3
# import sagemaker
# from sagemaker.sklearn.model import SKLearnModel


# def parse_args():
#     p = argparse.ArgumentParser()
#     p.add_argument("--region", required=True)
#     p.add_argument("--execution-role-arn", required=True)
#     p.add_argument("--model-package-group-name", required=True)
#     p.add_argument("--endpoint-name", required=True)
#     p.add_argument("--instance-type", default="ml.m5.large")

#     p.add_argument("--approval-status", default="Approved")
#     return p.parse_args()


# def main():
#     args = parse_args()
#     sm = boto3.client("sagemaker", region_name=args.region)

#     list_kwargs = dict(
#         ModelPackageGroupName=args.model_package_group_name,
#         SortBy="CreationTime",
#         SortOrder="Descending",
#         MaxResults=10,
#     )

#     if args.approval_status != "Any":
#         list_kwargs["ModelApprovalStatus"] = args.approval_status

#     resp = sm.list_model_packages(**list_kwargs)

#     if not resp.get("ModelPackageSummaryList"):
#         raise RuntimeError(
#             f"No model packages found in group '{args.model_package_group_name}' with status '{args.approval_status}'."
#         )

#     pkg_arn = resp["ModelPackageSummaryList"][0]["ModelPackageArn"]
#     desc = sm.describe_model_package(ModelPackageName=pkg_arn)

#     model_data = desc["InferenceSpecification"]["Containers"][0]["ModelDataUrl"]
#     approval = desc.get("ModelApprovalStatus", "Unknown")

#     print("Using model package:", pkg_arn)
#     print("ApprovalStatus:", approval)
#     print("ModelDataUrl:", model_data)

#     sess = sagemaker.Session(boto3.Session(region_name=args.region))

#     model = SKLearnModel(
#         model_data=model_data,
#         role=args.execution_role_arn,
#         entry_point="inference.py",
#         source_dir="src",
#         framework_version="1.2-1",
#         py_version="py3",
#         sagemaker_session=sess,
#     )

#     model.deploy(
#         endpoint_name=args.endpoint_name,
#         initial_instance_count=1,
#         instance_type=args.instance_type,
#     )

#     print("Deployed endpoint:", args.endpoint_name)


# if __name__ == "__main__":
#     main()



#test to check endpoint will update or not
import argparse
import time
import boto3
from botocore.exceptions import ClientError


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--region", required=True)
    p.add_argument("--execution-role-arn", required=True)
    p.add_argument("--model-package-group-name", required=True)
    p.add_argument("--endpoint-name", required=True)
    p.add_argument("--instance-type", default="ml.m5.large")
    p.add_argument("--initial-instance-count", type=int, default=1)
    p.add_argument("--approval-status", default="Any")  # Any | Approved | PendingManualApproval
    return p.parse_args()


def endpoint_exists(sm, endpoint_name: str) -> bool:
    try:
        sm.describe_endpoint(EndpointName=endpoint_name)
        return True
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("ValidationException", "ResourceNotFound"):
            return False
        raise


def wait_endpoint(sm, endpoint_name: str, timeout_sec: int = 1800):
    start = time.time()
    while True:
        desc = sm.describe_endpoint(EndpointName=endpoint_name)
        status = desc["EndpointStatus"]
        print("EndpointStatus:", status)

        if status == "InService":
            return
        if status in ("Failed", "OutOfService"):
            raise RuntimeError(f"Endpoint failed: {desc.get('FailureReason')}")

        if time.time() - start > timeout_sec:
            raise TimeoutError(f"Timed out waiting for endpoint {endpoint_name}")
        time.sleep(30)


def main():
    args = parse_args()
    sm = boto3.client("sagemaker", region_name=args.region)

    # 1) latest model package in the group
    list_kwargs = dict(
        ModelPackageGroupName=args.model_package_group_name,
        SortBy="CreationTime",
        SortOrder="Descending",
        MaxResults=10,
    )
    if args.approval_status != "Any":
        list_kwargs["ModelApprovalStatus"] = args.approval_status

    resp = sm.list_model_packages(**list_kwargs)
    pkgs = resp.get("ModelPackageSummaryList", [])
    if not pkgs:
        raise RuntimeError(
            f"No model packages found in '{args.model_package_group_name}' with status '{args.approval_status}'."
        )

    pkg_arn = pkgs[0]["ModelPackageArn"]
    desc = sm.describe_model_package(ModelPackageName=pkg_arn)

    container = desc["InferenceSpecification"]["Containers"][0]
    image_uri = container["Image"]
    model_data_url = container["ModelDataUrl"]

    print("Using model package:", pkg_arn)
    print("ApprovalStatus:", desc.get("ModelApprovalStatus"))
    print("Image:", image_uri)
    print("ModelDataUrl:", model_data_url)

    ts = int(time.time())
    model_name = f"{args.endpoint_name}-model-{ts}"
    endpoint_config_name = f"{args.endpoint_name}-cfg-{ts}"

    # 2) Create model using image + model artifacts (works even if package is PendingManualApproval)
    sm.create_model(
        ModelName=model_name,
        ExecutionRoleArn=args.execution_role_arn,
        PrimaryContainer={
            "Image": image_uri,
            "ModelDataUrl": model_data_url,
        },
    )
    print("Created model:", model_name)

    # 3) Create endpoint config
    sm.create_endpoint_config(
        EndpointConfigName=endpoint_config_name,
        ProductionVariants=[
            {
                "VariantName": "AllTraffic",
                "ModelName": model_name,
                "InitialInstanceCount": args.initial_instance_count,
                "InstanceType": args.instance_type,
                "InitialVariantWeight": 1.0,
            }
        ],
    )
    print("Created endpoint config:", endpoint_config_name)

    # 4) Update or create endpoint
    if endpoint_exists(sm, args.endpoint_name):
        print("Endpoint exists -> updating:", args.endpoint_name)
        sm.update_endpoint(
            EndpointName=args.endpoint_name,
            EndpointConfigName=endpoint_config_name,
        )
    else:
        print("Endpoint does not exist -> creating:", args.endpoint_name)
        sm.create_endpoint(
            EndpointName=args.endpoint_name,
            EndpointConfigName=endpoint_config_name,
        )

    # 5) Wait
    wait_endpoint(sm, args.endpoint_name)
    print("Endpoint is InService:", args.endpoint_name)


if __name__ == "__main__":
    main()