#!/bin/bash

pushd `dirname $0` > /dev/null

function show_usage {
    echo "Usage: $0 <region> <namespace> <environment> <app> <keypair>"
    echo "Example: $0 us-west-2 example-ns demo-env flask-api ssh_key"
    exit 1
}

if [ "$#" -lt 5 ]; then
    show_usage
fi

#check AWS credentials. terraform could hang if token expired
aws sts get-caller-identity
cd deploy/terraform
terraform init

COMMAND="apply"

TF_VAR_region=$1 \
TF_VAR_namespace=$2 \
TF_VAR_environment=$3 \
TF_VAR_app=$4 \
TF_VAR_keypair=$5 \
terraform ${COMMAND}

# deploy elastic beanstalk applicaton verson to environment
aws --region us-west-2 elasticbeanstalk update-environment --environment-name $(terraform output env_name) --version-label $(terraform output app_version)

popd  > /dev/null