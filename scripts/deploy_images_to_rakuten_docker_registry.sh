##!/bin/bash -x
# requires the following:
# - Set Azure CONTAINER_KEY as env var
# - login:  docker login docker-regi.intra.rakuten-it.com
#Run like: .deploy_images_to_rakuten_docker_registry.sh <IMAGE_TAG> <LOCAL_IMAGE_PATH> <IMAGE_BASENAME> I.e:
# ./deploy_images_to_rakuten_docker_registry.sh v0.0.1 /data/metapod/images release_metapod

METAPOD_TAG=$1
IMAGE_PATH=$2
METAPOD_IMAGE=$3
azure_container_path="metapod_images"
rakuten_docker_registry_path="docker-regi.intra.rakuten-it.com/ts-lopezari01"
latest=latest

declare -a images=(
jenkins
nginx
jenkinsapi
)

rm -rf ${IMAGE_PATH}/*
mkdir -p ${IMAGE_PATH}

for image in "${images[@]}"
do
   echo "Download Image from Azure file container: \
   ${azure_container_path}/${METAPOD_IMAGE}_${image}_${METAPOD_TAG}.tar.gz"
   az storage blob download --account-key ${CONTAINER_KEY} \
   --account-name csdddevelopment4nd3u6sa --container-name files \
   --name ${azure_container_path}/${METAPOD_IMAGE}_${image}_${METAPOD_TAG}.tar.gz \
   --file ${IMAGE_PATH}/${METAPOD_IMAGE}_${image}_${METAPOD_TAG}.tar.gz
   docker load -i ${IMAGE_PATH}/${METAPOD_IMAGE}_${image}_${METAPOD_TAG}.tar.gz
   docker tag ${METAPOD_IMAGE}_${image}:${METAPOD_TAG} ${rakuten_docker_registry_path}/${METAPOD_IMAGE}_${image}:${METAPOD_TAG}
   docker tag ${METAPOD_IMAGE}_${image}:${METAPOD_TAG} ${rakuten_docker_registry_path}/${METAPOD_IMAGE}_${image}:${latest}

   echo "Upload Image to ${rakuten_docker_registry_path}/${METAPOD_IMAGE}_${image}:${METAPOD_TAG}"
   docker push ${rakuten_docker_registry_path}/${METAPOD_IMAGE}_${image}:${METAPOD_TAG}
   docker push ${rakuten_docker_registry_path}/${METAPOD_IMAGE}_${image}:${latest}
done

rm -rf ${IMAGE_PATH}/*

echo "Done"
