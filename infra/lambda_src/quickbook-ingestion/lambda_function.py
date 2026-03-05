
import os
import time
import json
import boto3
from botocore.exceptions import ClientError

REGION = os.environ.get("REGION", "us-east-1")
MODEL_PACKAGE_GROUP = os.environ["MODEL_PACKAGE_GROUP"]
PROD_ENDPOINT_NAME = os.environ["PROD_ENDPOINT_NAME"]
SAGEMAKER_EXEC_ROLE_ARN = os.environ["SAGEMAKER_EXEC_ROLE_ARN"]

INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE", "ml.m5.large")
INITIAL_INSTANCE_COUNT = int(os.environ.get("INITIAL_INSTANCE_COUNT", "1"))

# This must match your training/inference framework
SKLEARN_VERSION = os.environ.get("SKLEARN_VERSION", "1.2-1")
PY_VERSION = os.environ.get("PY_VERSION", "py3")

sm = boto3.client("sagemaker", region_name=REGION)


def endpoint_exists(endpoint_name: str) -> bool:
    try:
        sm.describe_endpoint(EndpointName=endpoint_name)
        return True
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("ValidationException", "ResourceNotFound"):
            return False
        raise


def latest_approved_model_package_arn() -> str:
    resp = sm.list_model_packages(
        ModelPackageGroupName=MODEL_PACKAGE_GROUP,
        ModelApprovalStatus="Approved",
        SortBy="CreationTime",
        SortOrder="Descending",
        MaxResults=1,
    )
    if not resp.get("ModelPackageSummaryList"):
        raise RuntimeError(f"No Approved model package found in group: {MODEL_PACKAGE_GROUP}")
    return resp["ModelPackageSummaryList"][0]["ModelPackageArn"]


def get_sklearn_image_uri(region: str, version: str, py_version: str) -> str:
    raise NotImplementedError


def handler(event, context):
    print("EVENT:", json.dumps(event))

    pkg_arn = event.get("detail", {}).get("ModelPackageArn") or latest_approved_model_package_arn()
    print("Using Approved ModelPackageArn:", pkg_arn)

    desc = sm.describe_model_package(ModelPackageName=pkg_arn)

    # Get model artifact
    container = desc["InferenceSpecification"]["Containers"][0]
    model_data = container["ModelDataUrl"]
    print("ModelDataUrl:", model_data)

    # Prefer image URI from Model Package if present
    image_uri = container.get("Image")
    if not image_uri:
        raise RuntimeError(
            "Model package does not contain container Image URI. "
            "Either (1) register the model with inference image, or (2) provide IMAGE_URI env var to Lambda."
        )

    model_name = f"prod-model-{int(time.time())}"

    env = {
        "SAGEMAKER_PROGRAM": "inference.py",
        "SAGEMAKER_SUBMIT_DIRECTORY": "/opt/ml/model/code",
    }

    sm.create_model(
        ModelName=model_name,
        ExecutionRoleArn=SAGEMAKER_EXEC_ROLE_ARN,
        PrimaryContainer={
            "Image": image_uri,
            "ModelDataUrl": model_data,
            "Environment": env,
        },
    )
    print("Created model:", model_name)

    endpoint_config_name = f"{PROD_ENDPOINT_NAME}-config-{int(time.time())}"
    sm.create_endpoint_config(
        EndpointConfigName=endpoint_config_name,
        ProductionVariants=[
            {
                "VariantName": "AllTraffic",
                "ModelName": model_name,
                "InitialInstanceCount": INITIAL_INSTANCE_COUNT,
                "InstanceType": INSTANCE_TYPE,
            }
        ],
    )
    print("Created endpoint config:", endpoint_config_name)

    if endpoint_exists(PROD_ENDPOINT_NAME):
        sm.update_endpoint(EndpointName=PROD_ENDPOINT_NAME, EndpointConfigName=endpoint_config_name)
        print("Updating endpoint:", PROD_ENDPOINT_NAME)
    else:
        sm.create_endpoint(EndpointName=PROD_ENDPOINT_NAME, EndpointConfigName=endpoint_config_name)
        print("Creating endpoint:", PROD_ENDPOINT_NAME)

    return {"status": "ok", "endpoint": PROD_ENDPOINT_NAME, "model_package": pkg_arn, "model": model_name}