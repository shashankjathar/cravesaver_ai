#!/bin/bash
# deploy.sh: Standard Cloud Run Deployment for CraveSaver Flask Application
# Run this from the root of the project directory.

echo "Deploying CraveSaver to Cloud Run..."

# Load configuration from .env file
if [ ! -f .env ]; then
    echo "Error: .env file not found! Please copy .env_sample to .env and fill in your details."
    exit 1
fi

# Automatically export all variables in the .env file
set -a
source .env
set +a

# Fetch the AlloyDB instance connection name
export INSTANCE_NAME=$(gcloud alloydb instances describe $ALLOYDB_INSTANCE \
    --cluster=$ALLOYDB_CLUSTER \
    --region=$REGION \
    --format="value(name)")

if [ -z "$INSTANCE_NAME" ]; then
    echo "Error: Could not find the AlloyDB instance connection name."
    echo "Check that you replaced YOUR_INSTANCE_ID_HERE and YOUR_CLUSTER_ID_HERE correctly."
    exit 1
fi

echo "Connecting Flask to AlloyDB Instance: $INSTANCE_NAME"

# Deploying a standard Python Flask application directly from source code
# Cloud Buildpacks will automatically detect requirements.txt and build the container
gcloud run deploy cravesaver-app \
    --source . \
    --region $REGION \
    --allow-unauthenticated \
    --network=easy-alloydb-vpc \
    --subnet=default \
    --set-env-vars INSTANCE_CONNECTION_NAME=$INSTANCE_NAME \
    --set-env-vars DB_USER="postgres" \
    --set-env-vars DB_PASS="YOUR_EXISTING_DB_PASSWORD" \
    --set-env-vars DB_NAME="postgres"

echo "====================================================="
echo "Deployment Process Finished!"
echo "Check the terminal output above for the public Cloud Run Service URL."
echo "Click the URL to access the CraveSaver Web UI!"
echo "====================================================="
