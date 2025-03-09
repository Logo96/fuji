#!/bin/bash

# Use environment variables or prompt the user
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-$(read -p "Enter your DockerHub username: " DOCKERHUB_USERNAME && echo $DOCKERHUB_USERNAME)}
SERVICE_NAME=${SERVICE_NAME:-$(read -p "Enter your service name: " SERVICE_NAME && echo $SERVICE_NAME)}
BUCKET_NAME=${BUCKET_NAME:-$(read -p "Enter your bucket name: " BUCKET_NAME && echo $BUCKET_NAME)}
DATASET_NAME=${DATASET_NAME:-$(read -p "Enter your dataset name: " DATASET_NAME && echo $DATASET_NAME)}
TABLE_NAME=${TABLE_NAME:-$(read -p "Enter your table name: " TABLE_NAME && echo $TABLE_NAME)}

REGION="us-central1"
GIT_SHA=$(git rev-parse --short HEAD)
echo "GIT_SHA: $GIT_SHA"
IMAGE_TAG=sha-$GIT_SHA

# Initialize VECTOR_ROUTES as empty
VECTOR_ROUTES=""

# Check if route.json exists
# Check if route.json exists
if [ -f "route.json" ]; then
    echo "route.json file found. Do you want to use custom routing? (y/n)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Read routing rules from route.json
        VECTOR_ROUTES=$(cat route.json)

        # Validate JSON format
        if ! echo "$VECTOR_ROUTES" | jq . >/dev/null 2>&1; then
            echo "Error: Invalid JSON in route.json. Please check the file format."
            exit 1
        fi
        echo "Using custom routing rules from route.json"
    else
        echo "Custom routing will not be used."
    fi
else
    echo "route.json file not found. Custom routing will not be used."
fi

# echo all the variables, and wait for confirmation
echo "DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
echo "SERVICE_NAME: $SERVICE_NAME"
echo "BUCKET_NAME: $BUCKET_NAME"
echo "DATASET_NAME: $DATASET_NAME"
echo "TABLE_NAME: $TABLE_NAME"
echo "REGION: $REGION"
echo "IMAGE_TAG: $IMAGE_TAG"
if [ -n "$VECTOR_ROUTES" ]; then
    echo "Routing Rules:"
    echo "$VECTOR_ROUTES" | jq .
else
    echo "No custom routing rules applied."
fi
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Create Cloud Storage bucket if it doesn't exist
if ! gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
  echo "Creating bucket $BUCKET_NAME..."
  gsutil mb gs://$BUCKET_NAME
else
  echo "Bucket $BUCKET_NAME already exists."
fi

# Prepare environment variables for Cloud Run
ENV_VARS="GCS_BUCKET_NAME=$BUCKET_NAME"
if [ ! -z "$VECTOR_ROUTES" ]; then
    ENV_VARS="$ENV_VARS,VECTOR_ROUTES='$VECTOR_ROUTES'"
fi

# Deploy Cloud Run service
echo "Deploying Cloud Run service $SERVICE_NAME..."
gcloud run deploy $SERVICE_NAME \
    --image $DOCKERHUB_USERNAME/fuji:$IMAGE_TAG \
    --allow-unauthenticated \
    --region $REGION \
    --set-env-vars "$ENV_VARS"

# Create BigQuery dataset if it doesn't exist
if ! bq show $DATASET_NAME &>/dev/null; then
  echo "Creating BigQuery dataset $DATASET_NAME..."
  bq mk $DATASET_NAME
else
  echo "BigQuery dataset $DATASET_NAME already exists."
fi

# Create BigQuery external table if it doesn't exist
if ! bq show $DATASET_NAME.$TABLE_NAME &>/dev/null; then
  echo "Creating BigQuery external table $DATASET_NAME.$TABLE_NAME..."
  bq mkdef --source_format=NEWLINE_DELIMITED_JSON --autodetect=true \
    "gs://$BUCKET_NAME/*" > /tmp/fuji-table-def

  cat /tmp/fuji-table-def

  bq mk --table --external_table_definition=/tmp/fuji-table-def \
    $DATASET_NAME.$TABLE_NAME
else
  echo "BigQuery table $DATASET_NAME.$TABLE_NAME already exists."
fi

