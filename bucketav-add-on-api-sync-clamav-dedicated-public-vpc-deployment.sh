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
S3_TEMPLATE_FILE="s3://wci-reg-bucketav-cft/bucketav-add-on-api-sync-clamav-dedicated-public-vpc-v2.6.0.yaml"
LOCAL_TEMPLATE_FILE="/tmp/bucketav-s3-clamav-resources-v2.19.3.template"
TEMPLATE_FILE="bucketav-add-on-api-sync-clamav-dedicated-public-vpc-v2.6.0.yaml"
ENV_VAR_FILE="../env/${ENVIRONMENT}-env.yml"  # Adjusted path
S3_DEPLOY_BUCKET="wci-reg-bucketav-cft"  # Change to your S3 bucket for deployment

# Function to read environment variable value from YAML file
function get_env_variable() {
  local file_path=$1
  local variable_name=$2
  local variable_value=$(yq eval '.["'"${variable_name}"'"]' "${file_path}")
  echo "${variable_value}"
}

# Read environment variables from file
ENVIRONMENT=$(get_env_variable "${ENV_VAR_FILE}" "APPLICATION_ENV")
echo $ENVIRONMENT
VPC_CIDR=$(get_env_variable "${ENV_VAR_FILE}" "VPC_CIDR")
echo $VPC_CIDR
REGION=$(get_env_variable "${ENV_VAR_FILE}" "REGION")
echo $REGION
BUCKETAV_KEY_PAIR=$(get_env_variable "${ENV_VAR_FILE}" "BUCKETAV_KEY_PAIR")
echo $BUCKETAV_KEY_PAIR
HOSTED_ZONE_ID=$(get_env_variable "${ENV_VAR_FILE}" "HOSTED_ZONE_ID")
echo $HOSTED_ZONE_ID
DOMAIN_NAME=$(get_env_variable "${ENV_VAR_FILE}" "DOMAIN_NAME")
echo $DOMAIN_NAME
API_KEYS=$(get_env_variable "${ENV_VAR_FILE}" "API_KEYS")
echo $API_KEYS
DNS_CONFIGURATION=$(get_env_variable "${ENV_VAR_FILE}" "DNS_CONFIGURATION")
echo $DNS_CONFIGURATION
CORE_BUCKETAVSTACKNAME=$(get_env_variable "${ENV_VAR_FILE}" "CORE_BUCKETAVSTACKNAME")
echo $CORE_BUCKETAVSTACKNAME

echo "Starting to create BucketAv Add-On HTTPS API Synch Resources"

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
           --stack-name "${STACK_NAME}-${ENVIRONMENT}-api-sync" \
           --region $REGION \
           --no-fail-on-empty-changeset \
           --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
           --parameter-overrides "VpcCidrBlock=${VPC_CIDR}" \
                                 "HostedZoneId=${HOSTED_ZONE_ID}" \
                                 "DomainName=${DOMAIN_NAME}" \
                                 "DnsConfiguration=${DNS_CONFIGURATION}" \
                                 "ApiKeys=${API_KEYS}" \
                                 "BucketAVStackName=${CORE_BUCKETAVSTACKNAME}" \
                                 "KeyName=${BUCKETAV_KEY_PAIR}" \
           --s3-bucket "${S3_DEPLOY_BUCKET}"
