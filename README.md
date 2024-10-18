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



