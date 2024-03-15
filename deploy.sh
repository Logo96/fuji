#!/bin/bash

# Set variables
SERVICE_NAME="your-service-name"
BUCKET_NAME="your-bucket-name"
REGION="us-central1"
DATASET_NAME="your-dataset-name"
TABLE_NAME="your-table-name"

# Create Cloud Storage bucket if it doesn't exist
if ! gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
  echo "Creating bucket $BUCKET_NAME..."
  gsutil mb gs://$BUCKET_NAME
else
  echo "Bucket $BUCKET_NAME already exists."
fi

# Deploy Cloud Run service if it doesn't exist
echo "Deploying Cloud Run service $SERVICE_NAME..."
gcloud run deploy $SERVICE_NAME \
	--image simonmok/uji:main \
	--allow-unauthenticated \
	--region $REGION \
	--set-env-vars GCS_BUCKET_NAME=$BUCKET_NAME

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
  bq mkdef --source_format=JSON --autodetect=true \
    gs://$BUCKET_NAME > /tmp/uji-table-def

  cat /tmp/uji-table-def

  bq mk --table --external_table_definition=/tmp/uji-table-def \
    $DATASET_NAME.$TABLE_NAME
else
  echo "BigQuery table $DATASET_NAME.$TABLE_NAME already exists."
fi

