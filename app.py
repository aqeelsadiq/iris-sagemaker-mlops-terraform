import os
import json
import boto3
import pandas as pd
import streamlit as st
from botocore.exceptions import ClientError

FEATURES = ["sepal_length", "sepal_width", "petal_length", "petal_width"]

st.set_page_config(page_title="Iris SageMaker Endpoint Tester", layout="wide")

st.title(" Iris — SageMaker Endpoint Tester (Streamlit)")

# ----------------------------
# Helpers
# ----------------------------
def get_runtime_client(region: str):
    # SageMaker Runtime endpoint is regional
    return boto3.client("sagemaker-runtime", region_name=region)

def invoke_endpoint_json(smrt, endpoint_name: str, instances: list[dict]):
    """
    Sends JSON payload your inference.py expects:
      {"instances": [{"sepal_length":..., ...}, ...]}
    """
    payload = {"instances": instances}
    body = json.dumps(payload).encode("utf-8")

    resp = smrt.invoke_endpoint(
        EndpointName=endpoint_name,
        ContentType="application/json",
        Accept="application/json",
        Body=body,
    )
    raw = resp["Body"].read().decode("utf-8")
    return json.loads(raw)

def normalize_instances_from_df(df: pd.DataFrame) -> list[dict]:
    # Allow CSVs with either correct headers OR 4 unnamed columns
    df = df.copy()

    # If columns are like 0,1,2,3 rename them
    if list(df.columns) == [0, 1, 2, 3] and df.shape[1] == 4:
        df.columns = FEATURES

    # If user uploaded with extra columns, keep only feature columns if possible
    missing = [c for c in FEATURES if c not in df.columns]
    if missing:
        raise ValueError(f"CSV missing required columns: {missing}. Expected: {FEATURES}")

    df = df[FEATURES].dropna()
    if df.empty:
        raise ValueError("No valid rows found after selecting feature columns and dropping NA.")

    # Convert to list of dicts for JSON payload
    return df.to_dict(orient="records")

# ----------------------------
# Sidebar config
# ----------------------------
with st.sidebar:
    st.header("⚙️ Settings")

    default_region = os.environ.get("AWS_REGION") or os.environ.get("REGION") or "us-east-1"
    region = st.text_input("AWS Region", value=default_region)

    default_endpoint = os.environ.get("SAGEMAKER_ENDPOINT_NAME", "iris-endpoint-staging")
    endpoint_name = st.text_input("Endpoint name", value=default_endpoint)

    st.caption(
        "Tip: set env vars `AWS_REGION` and `SAGEMAKER_ENDPOINT_NAME` to avoid typing each time."
    )

# Create runtime client
try:
    smrt = get_runtime_client(region)
except Exception as e:
    st.error(f"Failed to create SageMaker Runtime client: {e}")
    st.stop()

tabs = st.tabs(["Single prediction", "Batch CSV", "Raw request"])

# ----------------------------
# Tab 1: Single prediction
# ----------------------------
with tabs[0]:
    st.subheader("Single prediction")

    c1, c2, c3, c4 = st.columns(4)
    with c1:
        sepal_length = st.number_input("sepal_length", value=5.1)
    with c2:
        sepal_width = st.number_input("sepal_width", value=3.5)
    with c3:
        petal_length = st.number_input("petal_length", value=1.4)
    with c4:
        petal_width = st.number_input("petal_width", value=0.2)

    if st.button("Invoke endpoint", type="primary"):
        instance = {
            "sepal_length": float(sepal_length),
            "sepal_width": float(sepal_width),
            "petal_length": float(petal_length),
            "petal_width": float(petal_width),
        }
        try:
            out = invoke_endpoint_json(smrt, endpoint_name, [instance])
            st.success("Success ")
            st.json(out)

            # Nice display
            if "species" in out and isinstance(out["species"], list) and out["species"]:
                st.metric("Predicted species", out["species"][0])
        except ClientError as e:
            st.error("AWS ClientError while invoking endpoint")
            st.code(str(e))
        except Exception as e:
            st.error("Failed to invoke endpoint")
            st.code(str(e))

# ----------------------------
# Tab 2: Batch CSV
# ----------------------------
with tabs[1]:
    st.subheader("Batch prediction from CSV")

    st.write(
        "Upload a CSV with columns: "
        f"`{', '.join(FEATURES)}`. "
        "Optional: CSV can be 4 columns without headers."
    )

    uploaded = st.file_uploader("Upload CSV", type=["csv"])

    if uploaded is not None:
        try:
            df = pd.read_csv(uploaded)
            st.write("Preview:")
            st.dataframe(df.head(20))

            instances = normalize_instances_from_df(df)

            col_a, col_b = st.columns([1, 2])
            with col_a:
                st.write(f"Rows to send: **{len(instances)}**")
                max_rows = st.number_input("Max rows to invoke (safety)", min_value=1, value=min(50, len(instances)))
            with col_b:
                st.info(
                    "SageMaker has payload size limits. If your file is big, invoke in chunks."
                )

            if st.button("Invoke endpoint for CSV"):
                # chunk for safety
                instances = instances[: int(max_rows)]
                out = invoke_endpoint_json(smrt, endpoint_name, instances)

                st.success("Success ")
                st.json(out)

                # Build a nice output table if response matches your inference.py
                if "species" in out and "class_index" in out:
                    res_df = pd.DataFrame(
                        {
                            "class_index": out["class_index"],
                            "species": out["species"],
                        }
                    )
                    st.subheader("Predictions")
                    st.dataframe(res_df)

        except Exception as e:
            st.error("Could not process CSV / invoke endpoint")
            st.code(str(e))

# ----------------------------
# Tab 3: Raw request builder
# ----------------------------
with tabs[2]:
    st.subheader("Raw request (advanced)")

    example_payload = {
        "instances": [
            {"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2},
            {"sepal_length": 6.2, "sepal_width": 2.8, "petal_length": 4.8, "petal_width": 1.8},
        ]
    }

    raw = st.text_area(
        "JSON Body to send",
        value=json.dumps(example_payload, indent=2),
        height=250,
    )

    col1, col2 = st.columns(2)
    with col1:
        content_type = st.text_input("ContentType", value="application/json")
    with col2:
        accept = st.text_input("Accept", value="application/json")

    if st.button("Invoke with raw JSON"):
        try:
            # validate JSON
            parsed = json.loads(raw)

            resp = smrt.invoke_endpoint(
                EndpointName=endpoint_name,
                ContentType=content_type,
                Accept=accept,
                Body=json.dumps(parsed).encode("utf-8"),
            )
            out_raw = resp["Body"].read().decode("utf-8")

            st.success("Success ")
            # try to pretty print JSON if possible
            try:
                st.json(json.loads(out_raw))
            except Exception:
                st.code(out_raw)

        except ClientError as e:
            st.error("AWS ClientError while invoking endpoint")
            st.code(str(e))
        except Exception as e:
            st.error("Failed to invoke endpoint")
            st.code(str(e))