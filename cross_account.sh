#!/bin/bash
set -euo pipefail

for account in test dev; do
  echo "Processing account $account..."

  CREDS=$(aws sts assume-role \
    --role-arn $(yq -r ".accounts[] | select(.name==\"$account\") | .role_arn" accounts.yml) \
    --role-session-name "AnsibleSSM")

  export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

  REGION=$(yq -r ".accounts[] | select(.name==\"$account\") | .region" accounts.yml)
  export AWS_DEFAULT_REGION=$REGION

  echo "Running playbook for $account..."
  ansible-playbook -i crossac_aws_ec2.yml main.yml

  # cleanup environment variables after each iteration
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION
done

