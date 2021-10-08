#!/bin/bash

#####################################################################################
# This script is used for packaging individual DBT project and uploading into the S3 bucket
# under the subfolder 'dbtdataops'.
#
# The script is dependent on the various resources getting deployed using the cloudformation
# template file: cloudformation/dbtonfargate.yaml. The resource and their information
# will be extracted once the stack is deployed successfully.
#
# NOTE: modify this script based on your implementation
#
# Example :
# bin/step_2_1_deploy_dbt_project.sh.sh "dbtonfargate" 
#####################################################################################

PARAM_DBT_ON_FARGATE_STACKNAME=${1:-'dbtonfargate'} #The cloudformation stack name

BASE_DIR="${PWD}"
BUILD_DIR="${BASE_DIR}/build"
DBT_DATAOPS_FOLDER=dbtdataops
DBT_PROJECT_IDR="dbtdataops/dbtoncloud"
DBT_PROJECT=`basename ${DBT_PROJECT_IDR}`

## ---------------------------------------------------------------------------------------- ##
echo "Cleaning up build directory ..."
rm -rf ${BUILD_DIR}/${DBT_PROJECT}
mkdir -p ${BUILD_DIR}/${DBT_PROJECT} ${DBT_PROJECT}.tar.gz

cd ${BASE_DIR}
echo "Copying dbt artifacts to folder : ${BUILD_DIR} ..."
cp -r ${DBT_PROJECT_IDR} ${BUILD_DIR}

echo "Packaging ${DBT_PROJECT} ..."
cd ${BUILD_DIR}
rm ${DBT_PROJECT}.tar.gz
tar -cf ${DBT_PROJECT}.tar ${DBT_PROJECT}
gzip ${DBT_PROJECT}.tar
ls -l ${DBT_PROJECT}.tar.gz
cd ${BASE_DIR}

## ---------------------------------------------------------------------------------------- ##
# Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
deployed_env=`aws cloudformation describe-stacks --stack-name "${PARAM_DBT_ON_FARGATE_STACKNAME}" --query "Stacks[].Parameters[?ParameterKey=='TAGEnv'].ParameterValue" --output text` #ex: dev
echo "Stack[${PARAM_DBT_ON_FARGATE_STACKNAME}] environment : $deployed_env"

# # Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
s3_codebucket_url_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-CodeStageBKTId" #ex: dbtonfargate-dev-CodeStageBKTId
aws_deployedregion_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-AWSDeployedRegion" #ex: dbtonfargate-dev-DPDBTECR

s3_bucket_url=`aws cloudformation list-exports --query "Exports[?Name == '${s3_codebucket_url_export_name}'].Value" --output text`

echo "Uploading to S3 [${s3_bucket_url}/${DBT_DATAOPS_FOLDER}/] ..."
aws s3 cp ${BUILD_DIR}/${DBT_PROJECT}.tar.gz ${s3_bucket_url}/${DBT_DATAOPS_FOLDER}/

echo "Finished!!"
