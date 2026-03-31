#!/bin/bash
# setup_gcp.sh: Provision infrastructure for AlloyDB AI Natural Language Mini-Project
# Run this inside Google Cloud Shell

set -e

# Load configuration from .env file
if [ ! -f .env ]; then
    echo "Error: .env file not found! Please copy .env_sample to .env and fill in your details."
    exit 1
fi

# Automatically export all variables in the .env file
set -a
source .env
set +a

PROJECT_ID=$(gcloud config get-value project)
NETWORK="default"

echo "Starting deployment in project: $PROJECT_ID, region: $REGION"

# 1. Enable required APIs
echo "Enabling necessary APIs (AlloyDB, Vertex AI, Service Networking)..."
gcloud services enable \
    alloydb.googleapis.com \
    aiplatform.googleapis.com \
    servicenetworking.googleapis.com \
    compute.googleapis.com \
    run.googleapis.com \
    iam.googleapis.com \
    cloudbuild.googleapis.com

# 2. Configure Private Services Access (VPC peering for AlloyDB)
echo "Configuring private networking connection..."
gcloud compute addresses create google-managed-services-default \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --network=$NETWORK \
    --project=$PROJECT_ID || true # Ignore error if already exists

gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=google-managed-services-default \
    --network=$NETWORK \
    --project=$PROJECT_ID || true # Ignore error if already connected

# 3. Create AlloyDB Cluster (SKIPPED - using existing)
echo "Skipping cluster creation since you already have one running: ($ALLOYDB_CLUSTER)..."
# gcloud alloydb clusters create $ALLOYDB_CLUSTER \
#     --region=$REGION \
#     --network=$NETWORK \
#     --password=$DB_PASSWORD

# 4. Create AlloyDB Primary Instance (SKIPPED - using existing)
echo "Skipping instance creation since you already have one running: ($ALLOYDB_INSTANCE)..."
# gcloud alloydb instances create $ALLOYDB_INSTANCE \
#     --cluster=$ALLOYDB_CLUSTER \
#     --region=$REGION \
#     --machine-type=standard-2 \
#     --instance-type=PRIMARY

# 5. Enable Vertex AI Integration on the cluster (required for alloydb_ai_nl)
echo "Granting Vertex AI User role to the AlloyDB service account..."
PROJECT_NUM=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:service-${PROJECT_NUM}@gcp-sa-alloydb.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

echo "================================================="
echo "Infrastructure Setup Complete!"
echo "AlloyDB Instance: $ALLOYDB_INSTANCE"
echo "Database Password: $DB_PASSWORD"
echo "Next step: Connect to AlloyDB via 'psql' to run schema.sql and setup_nl.sql."
echo "================================================="
