#!/bin/bash

# Run from project root directory

if [ $# -lt 1 ]; then
  echo "Argument missing"; exit 1; fi
if [ ${1} != 'dev' ] && [ ${1} != 'prod' ] && [ ${1} != 'mydev' ]; then
  echo "invalid arg-1. Use 'dev' / 'prod' / 'mydev'"; exit 1; fi
if [ $# -eq 2 ] && [ ${2} != 'build' ] && [ ${2} != 'up' ];  then
  echo "invalid arg-2. Use 'build', 'up' or skip the arg-2"; exit 1; fi

deploy_env=${1}
ENV_FILE="${deploy_env}.env"

# Find git HEAD commit hash and replace the DEPLOY_COMMIT value in env file
commit_hash=$(git rev-parse --short HEAD)
sed -i -r "s#^(DEPLOY_COMMIT=).*#\1$commit_hash#" ${ENV_FILE}

# Load environment variables from dotenv file
. "./${ENV_FILE}"

service="${SERVICE}"
version="${VERSION}"

ssh_host_label="${DEPLOY_SSH_HOST_LABEL}"

# Create necessary folders in deploy environment if not exists
ssh "${ssh_host_label}" "mkdir -p ${service}/envs"
ssh "${ssh_host_label}" "mkdir -p ${service}/scripts"

if [ $# -eq 1 ] || [ ${2} = 'build' ];  then
  # Copy deployment files to deploy_location
  scp ${ENV_FILE} "${ssh_host_label}:~/${service}/.env"
  scp ${ENV_FILE} "${ssh_host_label}:~/${service}/envs/${version}.${commit_hash}.env"
  scp "docker-compose.yml" "${ssh_host_label}:~/${service}/docker-compose.yaml"
  scp "scripts/deploy-up.sh" "${ssh_host_label}:~/${service}/scripts/deploy-up.sh"
  scp -r "filebeat" "${ssh_host_label}:~/${service}/filebeat"
  scp -r "kibana" "${ssh_host_label}:~/${service}/kibana"
  scp -r "logstash" "${ssh_host_label}:~/${service}/logstash"

  echo "Copy completed"
fi

if [ $# -eq 1 ] || [ ${2} = 'up' ];  then
  echo "\nReady to 'up' deployment on '${ssh_host_label}'"
  if [ ${1} = 'dev' ]; then
    echo "Error: 'up' not implemented yet for '${1}', please manually ssh to '${ssh_host_label}' and run 'cd ${service}; sh scripts/deploy-up.sh'"; exit 1;
  fi
  # ssh to remote machine and run scripts/deploy-up.sh to deploy
  ssh "${ssh_host_label}" "cd ${service}; sh scripts/deploy-up.sh"
fi

