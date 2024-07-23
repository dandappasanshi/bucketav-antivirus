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
TEMPLATE_FILE="bucketav-s3-cft-template.yml"
LOCAL_FILE_PATH1="bucketav-add-on-api-sync-clamav-dedicated-public-vpc-v2.6.0.yaml"
LOCAL_FILE_PATH2="bucketav-s3-clamav-resources-v2.19.3.template"  # Replace with your local file path
ENV_VAR_FILE="../env/${ENVIRONMENT}-env.yml"  # Adjusted path

# Function to read environment variable value from YAML file
function get_env_variable() {
  local file_path=$1
  local variable_name=$2
  local variable_value=$(yq eval '.["'"${variable_name}"'"]' "${file_path}")
  echo "${variable_value}"
}

# Read environment variables from file
ENVIRONMENT=$(get_env_variable "${ENV_VAR_FILE}" "APPLICATION_ENV")
echo "Environment: $ENVIRONMENT"
REGION=$(get_env_variable "${ENV_VAR_FILE}" "REGION")
echo "Region: $REGION"
BUCKETAV_S3_CFT=$(get_env_variable "${ENV_VAR_FILE}" "BUCKETAV_S3_CFT")
echo "Bucket Name: $BUCKETAV_S3_CFT"

echo "Starting to create Private API Resources"

# Deploy SAM template
sam deploy -t $TEMPLATE_FILE --stack-name "${STACK_NAME}-${ENVIRONMENT}-bucketav-s3" \
                             --region=$REGION \
                             --no-fail-on-empty-changeset \
                             --capabilities=CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
                             --parameter-overrides "BucketName=${BUCKETAV_S3_CFT}" \
                                                   "Environment=${ENVIRONMENT}"

# Check SAM deployment status
if [ $? -ne 0 ]; then
  echo "SAM deployment failed."
  exit 1
fi

# Upload files to S3 bucket individually
echo "Uploading files to S3 bucket..."
aws s3 cp ${LOCAL_FILE_PATH1} s3://${BUCKETAV_S3_CFT}/$(basename ${LOCAL_FILE_PATH1})
aws s3 cp ${LOCAL_FILE_PATH2} s3://${BUCKETAV_S3_CFT}/$(basename ${LOCAL_FILE_PATH2})

# Check if the uploads were successful
if [ $? -eq 0 ]; then
  echo "Files successfully uploaded to s3://${BUCKETAV_S3_CFT}/"
else
  echo "File upload failed."
  exit 1
fi

echo "Done."
