#!/bin/bash

#####################################################################################
# This script is used to package a virtual env with dbt installed. As of today, virtual environments
# are not migratable, the 'relocatable' flag is in beta stage. Hence this script
# - Instantiate a docker (python slim buster)
# - create the directoy under which the venv will finally be running (/tmp/var/appdir)
# - activate the venv
# - install dbt and other dependencies
# - exits the docker session
# - tar & gzips the env.
#
#####################################################################################

PARAM_WORK_DIR=${1:-'pyvenvs'} 
PARAM_PACKAGE_FILE=${2:-'dbt_python_venv'}

echo "Cleaning up ${PARAM_WORK_DIR} ..."
rm -rf $PARAM_WORK_DIR
mkdir -p $PARAM_WORK_DIR
cd $PARAM_WORK_DIR

echo "Creating entrypoint script ..."
entry_point_script="./entrypnt.sh"

cat > ${entry_point_script} <<- EOM
#!/bin/bash

cd /tmp/var/appdir/
python3 -m venv .
source bin/activate
pip install dbt_snowflake
rm -rf share 
exit
EOM

chmod 750 ${entry_point_script}
# cat ${entry_point_script}

echo "Instantiate a docker instance and create the venv ..."
docker run -tv "${PWD}:/tmp/var/appdir" python:3.7.7-slim-buster "/bin/bash" "/tmp/var/appdir/${entry_point_script}"

echo "Back in host"
echo "Listing out ${PARAM_WORK_DIR} ..."

echo "packaging ..."
tar -cf ../${PARAM_PACKAGE_FILE}.tar .
gzip ../${PARAM_PACKAGE_FILE}.tar

cd ${CURRENT_PWD} #come back to original dir
