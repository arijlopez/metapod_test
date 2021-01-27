#!/bin/bash
#Set metapod_jenkins_devuser and metapod_jenkins_password as environment vars
#Run like: ./run_integration_test.sh <jenkins_host> <jenkins_host_port>
#          <metapod_image> <jenkinsapi_port> <nginx_port> <METAPOD_TAG> <jenkins_external_port> I.e:
# ./run_integration_test.sh http://jenkins 8080 release_metapod/feature_metapod 5001 8083 0.0.1/latest 8080

jenkins_url=$1
jenkins_port=$2
METAPOD_IMAGE=$3
CONTAINER_NAME_BASE=$METAPOD_IMAGE
jenkinsapi_port=$4
nginx_port=$5
METAPOD_TAG=$6
jenkins_external_port=$7

declare -a containers=(
${METAPOD_IMAGE}_jenkins
${METAPOD_IMAGE}_nginx
${METAPOD_IMAGE}_jenkinsapi
)

get_container_logs() {

  for container in "${containers[@]}"
  do
    echo "This is the logs for container: $container"
    echo "*********************************************************************"
    docker logs $container
  done

}

remove_containers() {

  for container in "${containers[@]}"
  do
    docker rm -f $container
  done

}

get_jenkins_build_log(){
  echo "This is the logs for the jenkins test build"
  echo "*********************************************************************"
  docker exec -ti ${METAPOD_IMAGE}_jenkins cat /var/jenkins_home/jobs/run_inspec/builds/1/log
}

get_jenkins_build_log_from_nginx(){
  echo "This is the logs for the jenkins test build grabbed from nginx"
  echo "*********************************************************************"
  curl http://localhost:${nginx_port}/reports/run_inspec_1/log
}

get_status() {
  status_response=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"jenkins_url":"'"${jenkins_url}"'","jenkins_port":"'"${jenkins_port}"'","username":"'"${metapod_jenkins_devuser}"'", "password":"'"${metapod_jenkins_password}"'", "jenkins_job": "run_inspec", "build_number":"'"${build_number}"'"}' \
  http://localhost:${jenkinsapi_port}/checkJobStatus
  )

  echo $status_response

}

dots()
{
  i=1
  sp="/.\|"
  echo -n ' '
  printf "\b${sp:i++%${#sp}:1}"
}

command_env_vars() {
  command_env_vars=$(echo JENKINS_PORT=$jenkins_external_port METAPOD_TAG=${METAPOD_TAG} \
  NGINX_PORT=$nginx_port JENKINSAPI_PORT=$jenkinsapi_port METAPOD_IMAGE=${METAPOD_IMAGE} \
  CONTAINER_NAME_BASE=${CONTAINER_NAME_BASE})
}

command_env_vars
# echo ${command_env_vars}
# remove_containers
eval "${command_env_vars} docker-compose down -v"
eval "${command_env_vars} docker-compose up --build -d --force-recreate"

jenkins_is_running() {
  if docker logs ${METAPOD_IMAGE}_jenkins 2>&1 | grep "Jenkins is fully up and running"
  then
    return 0
  else
    return 1
  fi
}

while ! jenkins_is_running
do
  dots
  sleep 2
done
# sleep a bit more to make sure jenkins is listening
sleep 3

json_response=$(
curl -s \
-X POST \
-H "Content-Type: application/json" \
-d '{"jenkins_url":"'"${jenkins_url}"'","jenkins_port":"'"${jenkins_port}"'","username":"'"${metapod_jenkins_devuser}"'", "password":"'"${metapod_jenkins_password}"'", "remote_hosts":[["52.246.191.166","csdd-automation", "ssh_key_name", "metapod_private_key"]],"inspec_profile":["external","https://github.com/dev-sec/linux-baseline"]}' \
http://localhost:${jenkinsapi_port}/runJob
)
# echo $json_response
build_number=$(echo ${json_response} | jq .number)

if [ -z "${build_number}" ]
then
      echo "There was a problem"
      echo "${json_response}"
      get_container_logs
      get_jenkins_build_log
      exit 1
else
      echo "Build number: ${build_number}"
fi

job_result=null
while [ "${job_result}" == "null" ]
do
job_result=$(get_status | jq -r .result)
#echo "this is the job result: $job_result"
dots
sleep 2
done
echo
job_result=$(get_status | jq -r .result)
if [[ "$job_result" == "SUCCESS" ]]
then
      get_jenkins_build_log_from_nginx && get_container_logs
      echo
      echo "Job result: ${job_result} for build number: ${build_number}"
      eval "${command_env_vars} docker-compose down -v"
else
      get_jenkins_build_log_from_nginx && get_container_logs
      echo
      echo "Job result: ${job_result} for build number: ${build_number}, exiting \
      with error, this is the job log above"
      eval "${command_env_vars} docker-compose down -v"
      exit 1
fi
