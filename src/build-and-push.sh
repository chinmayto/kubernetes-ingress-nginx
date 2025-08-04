#!/bin/bash

# Set your ECR registry URL (replace with your actual registry)
ECR_REGISTRY="<your-account-id>.dkr.ecr.<region>.amazonaws.com"

# Login to ECR
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

# Build and push app1
echo "Building app1..."
cd app1
docker build -t app1:latest .
docker tag app1:latest public.ecr.aws/<your-registry>/app1:latest
docker push public.ecr.aws/<your-registry>/app1:latest

# Build and push app2
echo "Building app2..."
cd ../app2
docker build -t app2:latest .
docker tag app2:latest public.ecr.aws/<your-registry>/app2:latest
docker push public.ecr.aws/<your-registry>/app2:latest

echo "Both apps built and pushed successfully!"