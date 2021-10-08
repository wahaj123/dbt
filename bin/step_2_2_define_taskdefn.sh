#!/bin/bash

#####################################################################################
# This script is used to define the task definition for a specific DBT project ex: 'dbtoncloud'.
#
# The script is dependent on the various resources getting deployed using the cloudformation
# template file: cloudformation/dbtonfargate.yaml. The resource and their information
# will be extracted once the stack is deployed successfully.
#
# NOTE: modify this script based on your implementation
#
# Example :
# bin/step_2_2_define_taskdefn.sh "dbtonfargate" "dbtoncloud"
#####################################################################################

PARAM_DBT_ON_FARGATE_STACKNAME=${1:-'dbtonfargate'} #The cloudformation stack name
PARAM_DBT_PROJECT=${2:-'dbtoncloud'}

## ---------------------------------------------------------------------------------------- ##
echo "Fetching values for parameters ..."

# Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
deployed_env=`aws cloudformation describe-stacks --stack-name "${PARAM_DBT_ON_FARGATE_STACKNAME}" --query "Stacks[].Parameters[?ParameterKey=='TAGEnv'].ParameterValue" --output text` #ex: dev
echo "Deployed Stack[${PARAM_DBT_ON_FARGATE_STACKNAME}] environment : $deployed_env"

# # Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
s3_codebucket_url_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-CodeStageBKTId" #ex: dbtonfargate-dev-CodeStageBKTId
s3_codebucket_arn_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-CodeStageBKTArn" #ex: dbtonfargate-dev-CodeStageBKTArn
aws_deployedregion_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-AWSDeployedRegion" #ex: dbtonfargate-dev-DPDBTECR
ecr_arn_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-DPDBTECR" #ex: dbtonfargate-dev-DPDBTECR
ecr_ref_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-DPDBTECR-Ref" #ex: dbtonfargate-dev-DPDBTECR
aws_deployedregion_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-AWSDeployedRegion" #ex: dbtonfargate-dev-DPDBTECR
ecstaskexecrole_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-ECSTaskExecutionRole-Arn"
dploggroupurl_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-DPLogGroupURL"

s3_bucket_url=`aws cloudformation list-exports --query "Exports[?Name == '${s3_codebucket_url_export_name}'].Value" --output text`
s3_codebucket_arn=`aws cloudformation list-exports --query "Exports[?Name == '${s3_codebucket_arn_export_name}'].Value" --output text`
ecstaskexecrole=`aws cloudformation list-exports --query "Exports[?Name == '${ecstaskexecrole_export_name}'].Value" --output text`
dploggroupurl=`aws cloudformation list-exports --query "Exports[?Name == '${dploggroupurl_export_name}'].Value" --output text`
#
docker_tag=`aws cloudformation list-exports --query "Exports[?Name == '${ecr_ref_export_name}'].Value" --output text`
ecr_arn=`aws cloudformation list-exports --query "Exports[?Name == '${ecr_arn_export_name}'].Value" --output text`
ecr_name=`aws cloudformation list-exports --query "Exports[?Name == '${ecr_arn_export_name}'].Value" --output text`
ecr_aws_region=`echo ${ecr_arn} | cut -d ':' -f4`
ecr_aws_accountid=`echo ${ecr_arn} | cut -d ':' -f5`

ecr_url="${ecr_aws_accountid}.dkr.ecr.${ecr_aws_region}.amazonaws.com"
docker_ecr_url=${ecr_url}/${docker_tag}:latest 
#

stack_name="ecs-task-${deployed_env}-${PARAM_DBT_PROJECT}"

dummy_sflk_secrets='{ \"SNOWSQL_ACCOUNT\": \"abc.us-east-1\", \"SNOWSQL_USER\": \"SOMEBODY\", \"DBT_PASSWORD\": \"abracadabra\", \"SNOWSQL_ROLE\": \"PUBLIC\", \"SNOWSQL_DATABASE\": \"DEMO_DB\", \"SNOWSQL_WAREHOUSE\": \"DEMO_WH\" }'

#dummy_sflk_secrets='{ \"SNOWSQL_ACCOUNT\": \"abc.us-east-1\" }'

echo "[ \
  { \"ParameterKey\": \"TAGEnv\", \"ParameterValue\": \"${deployed_env}\" },
  { \"ParameterKey\": \"TAGDBTProject\", \"ParameterValue\": \"${PARAM_DBT_PROJECT}\" },
  { \"ParameterKey\": \"PARAMECSTaskExecutionRoleArn\", \"ParameterValue\": \"${ecstaskexecrole}\" },
  { \"ParameterKey\": \"PARAMDBTECRUrl\", \"ParameterValue\": \"${docker_ecr_url}\" },
  { \"ParameterKey\": \"PARAMS3CodeBucketUrl\", \"ParameterValue\": \"${s3_bucket_url}\" },
  { \"ParameterKey\": \"PARAMDPLogGroupUrl\", \"ParameterValue\": \"${dploggroupurl}\" },
  { \"ParameterKey\": \"PARAMS3CodeBucketArn\", \"ParameterValue\": \"${s3_codebucket_arn}\" },
  { \"ParameterKey\": \"PARAMSecretsMgrSecrets\", \"ParameterValue\": \"${dummy_sflk_secrets}\" }

]" > param.json

cat param.json


echo "Registering stack named as : ${stack_name}"
aws cloudformation create-stack --stack-name ${stack_name} --template-body file://cloudformation/dbt_taskdef.yaml \
 --parameters file://${PWD}/param.json --capabilities CAPABILITY_NAMED_IAM


