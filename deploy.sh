#!/bin/bash

# Use environment variables or prompt the user
SERVICE_NAME=${SERVICE_NAME:-$(read -p "Enter your service name: " SERVICE_NAME && echo $SERVICE_NAME)}
BUCKET_NAME=${BUCKET_NAME:-$(read -p "Enter your bucket name: " BUCKET_NAME && echo $BUCKET_NAME)}
DATASET_NAME=${DATASET_NAME:-$(read -p "Enter your dataset name: " DATASET_NAME && echo $DATASET_NAME)}
TABLE_NAME=${TABLE_NAME:-$(read -p "Enter your table name: " TABLE_NAME && echo $TABLE_NAME)}

REGION="us-central1"

# echo all the variables, and wait for confirmation
echo "SERVICE_NAME: $SERVICE_NAME"
echo "BUCKET_NAME: $BUCKET_NAME"
echo "DATASET_NAME: $DATASET_NAME"
echo "TABLE_NAME: $TABLE_NAME"
echo "REGION: $REGION"
read -p "Do you want to continue? " -n 1 -r
echo

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
  bq mkdef --source_format=NEWLINE_DELIMITED_JSON --autodetect=true \
    "gs://$BUCKET_NAME/*" > /tmp/uji-table-def

  cat /tmp/uji-table-def

  bq mk --table --external_table_definition=/tmp/uji-table-def \
    $DATASET_NAME.$TABLE_NAME
else
  echo "BigQuery table $DATASET_NAME.$TABLE_NAME already exists."
fi

