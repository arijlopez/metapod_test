##!/bin/bash -x
# Requirement: Set Azure CONTAINER_KEY as env var
#Run like: ./upload_images_to_azure <IMAGE_TAG> <IMAGE_PATH> <METAPOD_IMAGE> <action>[save/upload] I.e:
# ./upload_images_to_azure latest|0.0.1 /data/metapod/images release save

METAPOD_TAG=$1
IMAGE_PATH=$2
METAPOD_IMAGE=$3
action=$4
LATEST=latest

declare -a images=(
${METAPOD_IMAGE}_jenkins
${METAPOD_IMAGE}_nginx
${METAPOD_IMAGE}_jenkinsapi
)

mkdir -p ${IMAGE_PATH}

if [[ "$action" == "save" ]]
then
  for image in "${images[@]}"
  do
     echo "Saving image in ${IMAGE_PATH}/${image}_${METAPOD_TAG}.tar.gz"
     docker save ${image}:${METAPOD_TAG} > ${IMAGE_PATH}/${image}_${METAPOD_TAG}.tar.gz
     docker tag ${image}:${METAPOD_TAG} ${image}:${LATEST}
     docker save ${image}:${LATEST} > ${IMAGE_PATH}/${image}_${LATEST}.tar.gz

  done
elif [[ "$action" == "upload" ]]
then
  for image in "${images[@]}"
  do
     echo "Uploading image: ${image}_${METAPOD_TAG}.tar.gz in Azure container files/metapod_images/${image}_${METAPOD_TAG}.tar.gz"
     az storage blob upload --account-key ${CONTAINER_KEY} --account-name csdddevelopment4nd3u6sa --container-name files --name metapod_images/${image}_${METAPOD_TAG}.tar.gz --file ${IMAGE_PATH}/${image}_${METAPOD_TAG}.tar.gz
     echo "Uploading image: ${image}_${LATEST}.tar.gz in Azure container files/metapod_images/${image}_${LATEST}.tar.gz"
     az storage blob upload --account-key ${CONTAINER_KEY} --account-name csdddevelopment4nd3u6sa --container-name files --name metapod_images/${image}_${LATEST}.tar.gz --file ${IMAGE_PATH}/${image}_${LATEST}.tar.gz

  done
  #find ${IMAGE_PATH}/* -mtime +2 -delete
  rm -rf ${IMAGE_PATH}/*
else
  echo "action parameter is set to $action. It must be set to save or upload"
fi
