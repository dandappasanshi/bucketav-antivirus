#!/bin/bash

# Exit immediately if any command returns a non-zero exit status
set -e

# Function to handle errors
handle_error() {
  echo "Error: Script failed on line $1"
  # Add cleanup actions here if needed
  exit 1
}

# Set the trap to call the error handler function
trap 'handle_error $LINENO' ERR

# Fetch environment value while running this script
ENVIRONMENT=$1

# Check if environment is provided
if [ -z "$ENVIRONMENT" ]; then
  echo "Please provide an environment name."
  exit 1
fi

STACK_NAME="wci-reg"
S3_TEMPLATE_FILE="s3://wci-reg-bucketav-cft/bucketav-s3-clamav-resources-v2.19.3.template"
LOCAL_TEMPLATE_FILE="/tmp/bucketav-s3-clamav-resources-v2.19.3.template"
ENV_VAR_FILE="../env/${ENVIRONMENT}-env.yml"
S3_DEPLOY_BUCKET="wci-reg-bucketav-cft"  # Change to your S3 bucket for deployment

# Function to read environment variable value from YAML file
get_env_variable() {
  local file_path=$1
  local variable_name=$2
  local variable_value=$(yq eval '.["'"${variable_name}"'"]' "${file_path}")
  echo "${variable_value}"
}

# Read environment variables from file
APPLICATION_ENV=$(get_env_variable "${ENV_VAR_FILE}" "APPLICATION_ENV")
echo $APPLICATION_ENV
CORE_BUCKETAV_VPC_CIDR=$(get_env_variable "${ENV_VAR_FILE}" "CORE_BUCKETAV_VPC_CIDR")
echo $CORE_BUCKETAV_VPC_CIDR
REGION=$(get_env_variable "${ENV_VAR_FILE}" "REGION")
echo $REGION
BUCKETAV_KEY_PAIR=$(get_env_variable "${ENV_VAR_FILE}" "BUCKETAV_KEY_PAIR")
echo $BUCKETAV_KEY_PAIR

echo "Starting to create BucketAv Resources"

# Check if the S3 bucket exists, and create it if it doesn't
if ! aws s3 ls "s3://${S3_DEPLOY_BUCKET}" > /dev/null 2>&1; then
  echo "S3 bucket ${S3_DEPLOY_BUCKET} does not exist. Creating it..."
  aws s3 mb "s3://${S3_DEPLOY_BUCKET}" --region $REGION
fi

# Download the template file from S3
aws s3 cp "${S3_TEMPLATE_FILE}" "${LOCAL_TEMPLATE_FILE}"

# Check if the template file was downloaded successfully
if [[ ! -f "${LOCAL_TEMPLATE_FILE}" ]]; then
  echo "Error: Failed to download the template file from S3."
  exit 1
fi

# Deploy using the local template file and specify the S3 bucket for deployment
sam deploy -t "${LOCAL_TEMPLATE_FILE}" \
           --stack-name "${STACK_NAME}-${APPLICATION_ENV}-bucketav" \
           --region $REGION \
           --no-fail-on-empty-changeset \
           --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
           --parameter-overrides "VpcCidrBlock=${CORE_BUCKETAV_VPC_CIDR}" "KeyName=${BUCKETAV_KEY_PAIR}" \
           --s3-bucket "${S3_DEPLOY_BUCKET}"
