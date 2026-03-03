import os
import time
import boto3
from botocore.exceptions import ClientError

# REGION = os.environ["AWS_REGION"]
MODEL_GROUP = os.environ["MODEL_PACKAGE_GROUP"]
PROD_ENDPOINT = os.environ["PROD_ENDPOINT_NAME"]
SAGEMAKER_EXEC_ROLE_ARN = os.environ["SAGEMAKER_EXEC_ROLE_ARN"]
INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE", "ml.m5.large")
INITIAL_INSTANCE_COUNT = int(os.environ.get("INITIAL_INSTANCE_COUNT", "1"))
REGION = os.environ.get("REGION") 
sm = boto3.client("sagemaker", region_name=REGION) if REGION else boto3.client("sagemaker")
# sm = boto3.client("sagemaker", region_name=REGION)

def endpoint_exists(name: str) -> bool:
    try:
        sm.describe_endpoint(EndpointName=name)
        return True
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("ValidationException", "ResourceNotFound"):
            return False
        raise

def latest_approved_package() -> str:
    resp = sm.list_model_packages(
        ModelPackageGroupName=MODEL_GROUP,
        ModelApprovalStatus="Approved",
        SortBy="CreationTime",
        SortOrder="Descending",
        MaxResults=1,
    )
    lst = resp.get("ModelPackageSummaryList", [])
    if not lst:
        raise RuntimeError(f"No APPROVED model package found in group: {MODEL_GROUP}")
    return lst[0]["ModelPackageArn"]

def safe_name(prefix: str) -> str:
    ts = time.strftime("%Y%m%d-%H%M%S", time.gmtime())
    name = f"{prefix}-{ts}"
    return name[:63]

def handler(event, context):
    # EventBridge event: SageMaker Model Package State Change
    detail = event.get("detail", {})
    approval = detail.get("ModelApprovalStatus")
    group = detail.get("ModelPackageGroupName")

    # Only deploy when approved and it is our group
    if approval != "Approved":
        return {"status": "ignored", "reason": f"approval={approval}"}
    if group and group != MODEL_GROUP:
        return {"status": "ignored", "reason": f"wrong_group={group}"}

    pkg_arn = latest_approved_package()
    desc = sm.describe_model_package(ModelPackageName=pkg_arn)

    containers = desc["InferenceSpecification"]["Containers"]
    c0 = containers[0]
    image = c0["Image"]
    model_data_url = c0["ModelDataUrl"]
    env = c0.get("Environment", {})

    model_name = safe_name("iris-prod-model")
    endpoint_config_name = safe_name("iris-prod-epc")

    sm.create_model(
        ModelName=model_name,
        ExecutionRoleArn=SAGEMAKER_EXEC_ROLE_ARN,
        PrimaryContainer={
            "Image": image,
            "ModelDataUrl": model_data_url,
            "Environment": env,
        },
    )

    sm.create_endpoint_config(
        EndpointConfigName=endpoint_config_name,
        ProductionVariants=[
            {
                "VariantName": "AllTraffic",
                "ModelName": model_name,
                "InitialInstanceCount": INITIAL_INSTANCE_COUNT,
                "InstanceType": INSTANCE_TYPE,
                "InitialVariantWeight": 1.0,
            }
        ],
    )

    if endpoint_exists(PROD_ENDPOINT):
        sm.update_endpoint(
            EndpointName=PROD_ENDPOINT,
            EndpointConfigName=endpoint_config_name,
        )
        action = "update_endpoint"
    else:
        sm.create_endpoint(
            EndpointName=PROD_ENDPOINT,
            EndpointConfigName=endpoint_config_name,
        )
        action = "create_endpoint"

    return {
        "status": "ok",
        "action": action,
        "endpoint": PROD_ENDPOINT,
        "model_package": pkg_arn,
        "model_name": model_name,
        "endpoint_config": endpoint_config_name,
    }