#!/bin/bash

#####################################################################################
# This script is used to build a local docker image of the container, in which DBT will 
# run. It will then deploy the same to ECR.
#
# The script is dependent on the various resources getting deployed using the cloudformation
# template file: cloudformation/dbtonfargate.yaml. The resource and their information
# will be extracted once the stack is deployed successfully.
#
# Example :
# bin/step_1_1_buildAndPushDBTDockerToECR.sh "dbtonfargate"
#####################################################################################

PARAM_DBT_ON_FARGATE_STACKNAME=${1:-'dbtonfargate'} #The cloudformation stack name

PROJECT_DIR="${PWD}"

## ---------------------------------------------------------------------------------------- ##
# Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
deployed_env=`aws cloudformation describe-stacks --stack-name "${PARAM_DBT_ON_FARGATE_STACKNAME}" --query "Stacks[].Parameters[?ParameterKey=='TAGEnv'].ParameterValue" --output text` #ex: dev
echo "Stack[${PARAM_DBT_ON_FARGATE_STACKNAME}] environment : $deployed_env"

ecr_arn_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-DPDBTECR" #ex: dbtonfargate-dev-DPDBTECR
ecr_ref_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-DPDBTECR-Ref" #ex: dbtonfargate-dev-DPDBTECR
aws_deployedregion_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-AWSDeployedRegion" #ex: dbtonfargate-dev-DPDBTECR

ecr_arn=`aws cloudformation list-exports --query "Exports[?Name == '${ecr_arn_export_name}'].Value" --output text`
ecr_name=`aws cloudformation list-exports --query "Exports[?Name == '${ecr_arn_export_name}'].Value" --output text`
docker_tag=`aws cloudformation list-exports --query "Exports[?Name == '${ecr_ref_export_name}'].Value" --output text`
ecr_aws_region=`echo ${ecr_arn} | cut -d ':' -f4`
ecr_aws_accountid=`echo ${ecr_arn} | cut -d ':' -f5`

ecr_url="${ecr_aws_accountid}.dkr.ecr.${ecr_aws_region}.amazonaws.com" 
echo "ECR ARN : ${ecr_arn}"
echo "Docker tag  : ${docker_tag}"
echo "ECR URL : ${ecr_url} "

echo "Retreiving ecr[${ecr_url}] password ..."
aws ecr get-login-password --region ${ecr_aws_region} | docker login --username AWS --password-stdin "${ecr_url}"

echo "Building docker image ${docker_tag} ..."
docker build -t ${docker_tag} -f ./dbtdocker/Dockferfile ./dbtdocker
docker tag ${docker_tag}:latest ${ecr_url}/${docker_tag}:latest

echo "Pushing docker image to ${ecr_url}/${docker_tag}:latest ..."
docker push ${ecr_url}/${docker_tag}:latest

echo "Finished!!!"