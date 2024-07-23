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
TEMPLATE_FILE="route53-acm-dns-bucketav-resources-cft.yml"
ENV_VAR_FILE=../env/$ENVIRONMENT-env.yml

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
VPC_ID=$(get_env_variable "${ENV_VAR_FILE}" "VPC_ID")
echo $VPC_ID
REGION=$(get_env_variable "${ENV_VAR_FILE}" "REGION")  # Corrected variable name
echo $REGION

echo "Starting to create Route53 resources(Public and Private hosted zones Resources"

sam deploy -t ${TEMPLATE_FILE} --stack-name "${STACK_NAME}-${ENVIRONMENT}-route53-stack" \
                             --region=$REGION \
                             --no-fail-on-empty-changeset \
                             --capabilities=CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
                             --parameter-overrides "VpcId=${VPC_ID}" \
                                                   "Environment=${ENVIRONMENT}" \
                                                   "VpcRegion=${REGION}"