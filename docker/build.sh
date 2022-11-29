# build the docker file in this dir and emulate x86_64
# usage: ./build.sh
# add name of the container to be flex-base
docker buildx build --platform linux/amd64 -t flex-base .

