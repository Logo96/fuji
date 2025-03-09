## Fuji: (Forkable) universal json ingestor

A template to glue together vector to accept arbitrary json to a storage bucket, and setup analytics. 
Cloud native/scalable. 

This is a fork of [uji](https://github.com/simon-mo/uji/) by @simon-mo, which additionally allows
forking and routing of sources to different sinks.

To deploy:

1. Fork this repository.
2. Add your DOCKERHUB_USERNAME and DOCKERHUB_TOKEN to the secrets of your GitHub repository.
3. Update the readme file and push to main to trigger the docker publish.
4. Run `deploy.sh`.

## How to deploy to cloud

Easiest way to deploy is to build a docker image and deploy to your personal dockerhob account. Once deployed you can run the deploy shell script and fill in the env variables.

1. export GIT_SHA=$(git rev-parse --short HEAD)
2. IMAGE_TAG="$DOCKERHUB_USERNAME/fuji:sha-$GIT_SHA"
3. docker build -t $IMAGE_TAG .
4. docker push $IMAGE_TAG
5. ./deploy.sh


