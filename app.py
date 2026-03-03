import os
import json
import boto3
import streamlit as st

# ---------------------------
# Config
# ---------------------------
DEFAULT_REGION = os.getenv("AWS_REGION", "us-east-1")
DEFAULT_ENDPOINT = os.getenv("ENDPOINT_NAME", "iris-endpoint-staging")

st.set_page_config(page_title="Iris Predictor (SageMaker)", layout="centered")
st.title("🌸 Iris Predictor (SageMaker Endpoint)")

region = st.text_input("AWS Region", value=DEFAULT_REGION)
endpoint_name = st.text_input("Endpoint Name", value=DEFAULT_ENDPOINT)

runtime = boto3.client("sagemaker-runtime", region_name=region)

FEATURES = ["sepal_length", "sepal_width", "petal_length", "petal_width"]

st.subheader("Input Features")
c1, c2 = st.columns(2)
with c1:
    sepal_length = st.number_input("sepal_length", value=5.1, step=0.1, format="%.2f")
    petal_length = st.number_input("petal_length", value=1.4, step=0.1, format="%.2f")
with c2:
    sepal_width = st.number_input("sepal_width", value=3.5, step=0.1, format="%.2f")
    petal_width = st.number_input("petal_width", value=0.2, step=0.1, format="%.2f")

payload = {"instances": [[sepal_length, sepal_width, petal_length, petal_width]]}

st.caption("Payload sent to endpoint (JSON)")
st.code(json.dumps(payload, indent=2), language="json")


def invoke(endpoint: str, body: dict) -> str:
    resp = runtime.invoke_endpoint(
        EndpointName=endpoint,
        ContentType="application/json",
        Accept="application/json",
        Body=json.dumps(body).encode("utf-8"),
    )
    return resp["Body"].read().decode("utf-8", errors="replace")


st.subheader("Prediction")

if st.button("Predict"):
    try:
        raw = invoke(endpoint_name, payload)

        st.success("✅ Prediction received")
        st.caption("Raw response")
        st.code(raw)

        # Try parse as JSON
        try:
            parsed = json.loads(raw)
            st.caption("Parsed response")
            st.json(parsed)

            # If your inference.py returns {"species":[...]}
            if isinstance(parsed, dict) and "species" in parsed:
                species = parsed["species"][0] if parsed["species"] else None
                st.markdown(f"### 🌿 Predicted Species: **{species}**")

        except Exception:
            st.info("Response is not JSON (showing raw output only).")

    except Exception as e:
        st.error(f"InvokeEndpoint failed: {e}")


st.divider()
st.subheader("Batch Prediction (optional)")

st.write("Paste multiple rows, one per line, comma-separated (4 values):")
batch_text = st.text_area(
    "Batch inputs",
    value="5.1,3.5,1.4,0.2\n6.2,2.8,4.8,1.8",
    height=120,
)

if st.button("Predict Batch"):
    try:
        rows = []
        for line in batch_text.strip().splitlines():
            parts = [p.strip() for p in line.split(",")]
            if len(parts) != 4:
                st.warning(f"Skipping invalid line (need 4 values): {line}")
                continue
            rows.append([float(x) for x in parts])

        if not rows:
            st.warning("No valid rows found.")
        else:
            batch_payload = {"instances": rows}
            raw = invoke(endpoint_name, batch_payload)

            st.success("✅ Batch prediction received")
            st.caption("Raw response")
            st.code(raw)

            try:
                parsed = json.loads(raw)
                st.caption("Parsed response")
                st.json(parsed)
            except Exception:
                st.info("Response is not JSON (showing raw output only).")

    except Exception as e:
        st.error(f"InvokeEndpoint failed: {e}")