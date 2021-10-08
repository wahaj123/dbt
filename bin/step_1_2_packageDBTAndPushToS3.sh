#!/bin/bash

#####################################################################################
# This script is used for packaging DBT and uploading into the S3 bucket.
#
# The script is dependent on the various resources getting deployed using the cloudformation
# template file: cloudformation/dbtonfargate.yaml. The resource and their information
# will be extracted once the stack is deployed successfully.
#
# Example :
# bin/packageDBTAndPushToS3.sh "dbtonfargate" 
#####################################################################################

PARAM_DBT_ON_FARGATE_STACKNAME=${1:-'dbtonfargate'} #The cloudformation stack name

BASE_DIR="${PWD}"
BUILD_DIR="${BASE_DIR}/build"
## ---------------------------------------------------------------------------------------- ##
echo "Cleaning up build directory ..."
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

## ---------------------------------------------------------------------------------------- ##
echo "Packaging DBT ..."
cd ${BUILD_DIR}
package_file_name=dbt_python_venv
../bin/package_dbtvenv.sh dbtvenvs dbt_python_venv

ls -l $package_file_name*

cd ${BASE_DIR}
## ---------------------------------------------------------------------------------------- ##

# # Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
deployed_env=`aws cloudformation describe-stacks --stack-name "${PARAM_DBT_ON_FARGATE_STACKNAME}" --query "Stacks[].Parameters[?ParameterKey=='TAGEnv'].ParameterValue" --output text` #ex: dev
echo "Stack[${PARAM_DBT_ON_FARGATE_STACKNAME}] environment : $deployed_env"

# # Retreive the url & arn based of the export from the deployed cloud formation template (dbtonfargate.yml)
s3_codebucket_url_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-CodeStageBKTId" #ex: dbtonfargate-dev-CodeStageBKTId
aws_deployedregion_export_name="${PARAM_DBT_ON_FARGATE_STACKNAME}-${deployed_env}-AWSDeployedRegion" #ex: dbtonfargate-dev-DPDBTECR

s3_bucket_url=`aws cloudformation list-exports --query "Exports[?Name == '${s3_codebucket_url_export_name}'].Value" --output text`

echo "Upload packaged artifact to S3 ${s3_bucket_url} ..."
aws s3 rm ${s3_bucket_url}/dbtvenvs/${package_file_name}.tar.gz
aws s3 cp ${BUILD_DIR}/${package_file_name}.tar.gz ${s3_bucket_url}/dbtvenvs/
aws s3 cp dbtdocker/run_pipeline.sh ${s3_bucket_url}/
aws s3 cp "dbtdocker/retrieve_secrets.py" ${s3_bucket_url}/
aws s3 cp dbtdocker/extract_json_key.py ${s3_bucket_url}/

echo "Finished!!!"