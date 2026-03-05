
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
#!/usr/bin/env python3
"""
pipelines/deploy.py

Deploy (create/update) a SageMaker real-time endpoint from the latest
Model Package in a Model Package Group (Model Registry).

Key fixes vs your original:
- ✅ When creating the SageMaker Model, we also pass the model package container's
  Environment variables. Without these, the SageMaker sklearn container often fails
  /ping with errors like: AttributeError: 'NoneType' object has no attribute 'startswith'
- ✅ Waits if endpoint is already Updating/SystemUpdating before trying to update again.
- ✅ Better logging + clear failure handling.
- ✅ Adds tags to Model + EndpointConfig with ModelPackageArn for traceability.

Usage example:
python pipelines/deploy.py \
  --region us-east-1 \
  --execution-role-arn arn:aws:iam::123456789012:role/YourSageMakerExecRole \
  --model-package-group-name iris-model-group \
  --endpoint-name iris-endpoint-staging \
  --approval-status Any
"""

import argparse
import time
from typing import Any, Dict, Optional

import boto3
from botocore.exceptions import ClientError


# ----------------------------
# Args
# ----------------------------
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--region", required=True)
    p.add_argument("--execution-role-arn", required=True)
    p.add_argument("--model-package-group-name", required=True)
    p.add_argument("--endpoint-name", required=True)
    p.add_argument("--instance-type", default="ml.m5.large")
    p.add_argument("--initial-instance-count", type=int, default=1)
    p.add_argument(
        "--approval-status",
        default="Any",
        choices=["Any", "Approved", "PendingManualApproval"],
        help="Filter model packages by approval status.",
    )
    p.add_argument("--timeout-sec", type=int, default=3600)
    p.add_argument("--poll-sec", type=int, default=30)
    return p.parse_args()


# ----------------------------
# Helpers
# ----------------------------
def endpoint_desc(sm, endpoint_name: str) -> Dict[str, Any]:
    return sm.describe_endpoint(EndpointName=endpoint_name)


def endpoint_exists(sm, endpoint_name: str) -> bool:
    try:
        endpoint_desc(sm, endpoint_name)
        return True
    except ClientError as e:
        code = e.response["Error"]["Code"]
        # SageMaker can return different "not found" codes depending on SDK versions
        if code in ("ValidationException", "ResourceNotFoundException", "ResourceNotFound"):
            return False
        raise


def wait_endpoint(sm, endpoint_name: str, timeout_sec: int, poll_sec: int) -> Dict[str, Any]:
    """
    Wait for endpoint to become InService. If it becomes Failed/OutOfService, raise.
    """
    start = time.time()
    last_status: Optional[str] = None

    while True:
        desc = endpoint_desc(sm, endpoint_name)
        status = desc["EndpointStatus"]
        cfg = desc.get("EndpointConfigName")
        reason = desc.get("FailureReason")

        if status != last_status:
            print(f"[wait] EndpointStatus: {status} | EndpointConfigName: {cfg}")
            if reason:
                print(f"[wait] FailureReason (may be stale unless status=Failed): {reason}")
            last_status = status

        if status == "InService":
            return desc

        if status in ("Failed", "OutOfService"):
            raise RuntimeError(f"Endpoint is {status}: {reason}")

        if time.time() - start > timeout_sec:
            raise TimeoutError(f"Timed out waiting for endpoint '{endpoint_name}' to become InService")

        time.sleep(poll_sec)


def get_latest_model_package_arn(sm, group_name: str, approval_status: str) -> str:
    list_kwargs: Dict[str, Any] = dict(
        ModelPackageGroupName=group_name,
        SortBy="CreationTime",
        SortOrder="Descending",
        MaxResults=10,
    )
    if approval_status != "Any":
        list_kwargs["ModelApprovalStatus"] = approval_status

    resp = sm.list_model_packages(**list_kwargs)
    pkgs = resp.get("ModelPackageSummaryList", [])
    if not pkgs:
        raise RuntimeError(
            f"No model packages found in group '{group_name}' with status '{approval_status}'."
        )
    return pkgs[0]["ModelPackageArn"]


# ----------------------------
# Main deploy
# ----------------------------
def main() -> None:
    args = parse_args()
    sm = boto3.client("sagemaker", region_name=args.region)

    # If endpoint exists and is currently in a transition state, wait first
    if endpoint_exists(sm, args.endpoint_name):
        d = endpoint_desc(sm, args.endpoint_name)
        if d["EndpointStatus"] in ("Creating", "Updating", "SystemUpdating"):
            print(f"Endpoint '{args.endpoint_name}' currently {d['EndpointStatus']} -> waiting...")
            wait_endpoint(sm, args.endpoint_name, args.timeout_sec, args.poll_sec)

    # 1) Fetch latest model package
    pkg_arn = get_latest_model_package_arn(sm, args.model_package_group_name, args.approval_status)
    mp = sm.describe_model_package(ModelPackageName=pkg_arn)

    containers = mp.get("InferenceSpecification", {}).get("Containers", [])
    if not containers:
        raise RuntimeError(f"Model package has no inference containers: {pkg_arn}")

    container = containers[0]
    image_uri = container["Image"]
    model_data_url = container["ModelDataUrl"]

    # ✅ CRITICAL: pass Environment through (fixes /ping 500 in sklearn container)
    container_env = container.get("Environment", {}) or {}

    print("Using model package:", pkg_arn)
    print("ApprovalStatus:", mp.get("ModelApprovalStatus"))
    print("Image:", image_uri)
    print("ModelDataUrl:", model_data_url)
    print("Container Environment keys:", sorted(list(container_env.keys())))

    ts = int(time.time())
    model_name = f"{args.endpoint_name}-model-{ts}"
    endpoint_config_name = f"{args.endpoint_name}-cfg-{ts}"

    # 2) Create SageMaker Model (new name each deploy)
    print("Creating model:", model_name)
    sm.create_model(
        ModelName=model_name,
        ExecutionRoleArn=args.execution_role_arn,
        PrimaryContainer={
            "Image": image_uri,
            "ModelDataUrl": model_data_url,
            "Environment": container_env,  # ✅ FIX
        },
        Tags=[{"Key": "ModelPackageArn", "Value": pkg_arn}],
    )
    print("Created model:", model_name)

    # 3) Create endpoint config (new name each deploy)
    print("Creating endpoint config:", endpoint_config_name)
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
        Tags=[{"Key": "ModelPackageArn", "Value": pkg_arn}],
    )
    print("Created endpoint config:", endpoint_config_name)

    # 4) Update or create endpoint
    if endpoint_exists(sm, args.endpoint_name):
        print("Endpoint exists -> updating:", args.endpoint_name)
        sm.update_endpoint(EndpointName=args.endpoint_name, EndpointConfigName=endpoint_config_name)
    else:
        print("Endpoint does not exist -> creating:", args.endpoint_name)
        sm.create_endpoint(EndpointName=args.endpoint_name, EndpointConfigName=endpoint_config_name)

    # 5) Wait for deployment completion
    final_desc = wait_endpoint(sm, args.endpoint_name, args.timeout_sec, args.poll_sec)
    print("Endpoint is InService:", args.endpoint_name)

    # Sometimes SageMaker keeps an old FailureReason even after InService; print it for visibility.
    if final_desc.get("FailureReason"):
        print("NOTE: Endpoint has FailureReason text (may be from a previous failed attempt):")
        print(final_desc["FailureReason"])


if __name__ == "__main__":
    main()