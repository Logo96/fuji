## Uji: universal json ingestor

A template to glue together vector to accept arbitrary json to storage bucket, then setup analytics. Cloud native/scalable.

To deploy:

```
SERVICE_NAME=...
BUCKET_NAME=...
gcloud run deploy $SERVICE_NAME \
  --image ghcr.io/simon-mo/uji \
  --allow-unauthenticated \
  --set-env-vars GCS_BUCKET_NAME=$BUCKET_NAME
```

Create bigquery:

```
DATASET_NAME=...
TABLE_NAME=...
bq mkdef --source_format=JSON --autodetect=true \
  gs://$BUCKET_NAME > /tmp/uji-table-def

cat /tmp/uji-table-def

bq mk --table --external_table_definition=/tmp/uji-table-def \
  $DATASET_NAME.$TABLE_NAME
```
