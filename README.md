AWS Developer Associate Content Series : Developing on ECS with Fargate
=======================================================================

Created by Rob Scott, last modified on May 11, 2022

This demonstration will use Docker to create an image for ECS. Once the image is built locally, it can be pushed to Elastic Container Registry (ECR). ECS can retrieve the container image on deployment and run the application without requiring any pre-provisioned servers.

Building a Container Image
--------------------------

#### Write the app

We will use a similar Express web server application and turn it into a container-based application after it is all written. It's important to pay attention to how this application is made to run locally, because Docker needs to understand how to replicate the environment when running it in a container.

In a new repository, make a file with the name `app.js`. Paste the following code inside

    const express = require("express")
    const app = express()
    const port = process.env.PORT | 8888

    app.get('/', (req, res) => {
      res.send("Hello from ECS Fargate")
    })

    app.listen(port, () => {
      console.log(`ECS application listening on port ${port}`)
    })

Next, the application will need the `express` dependency in order to run. Use `npm install express` to install it. That should have generated a `package.json`, `node_modules` and a `package-lock.json`.

Check out the `package.json` and verify that there is a key present that says `dependencies`. Express should be included as a dependency. This is how the `npm install` command knows what dependencies it will need before running.

#### Containerize the app

Once Docker is installed on your machine, we will make a Dockerfile. A Dockerfile is a script with instructions on how to load a container with code, runtime, and dependencies. Make a file named `Dockerfile` and add the following code

    FROM node:12.18.1

    WORKDIR /ecs-demo

    COPY ["app.js", "package.json", "package-lock.json", "."]

    RUN npm install

    CMD ["node", "app.js"]

`FROM` is normally the first item on these scripts because it specifies what runtime and environment should be used. In this case, `node:12.18.1` is often called a _base-image_. The base image is available through Docker and its image repository, [Dockerhub](https://hub.docker.com/).

`WORKDIR` specifies where the script should be working from at its start. In this example, it is not that necessary. However, this specification is important on huge projects with a lot of code and dependencies.

`COPY` will copy all of the files in the working directory over into the container. That would include the `app.js`, `package.json`, and `package-lock.json`.

`RUN npm install`, like mentioned before, looks into the dependencies list and installs everything the application will need. In this case, it is just Express.

Finally, the script runs the app with `node app.js`.

To build the Docker image, use `docker built -t <NAME> .`. The `-t` flag stands for Tag, and you can choose a name to give the image being built. Run `docker images` to verify that the image was successfully built and able to be referenced.

Run the newly built image with `docker run -d -p 8888:8888 <TAG-NAME>`. The `-d` flag is for Detach-- the command will fork off a process so that the terminal is still usable after starting the application. It should cause a success hash to be printed once it spins up. The `-p` flag is for Port, and declares any desired port-forwarding specifications. The application is listening on `8888`, per the `app.js`, so this command will tell the container to also listen on `8888`, forwarding everything to the application. The format follows `<host>:<app>`.

REMEMBER to terminate these docker processes once they are not needed. Use `docker ps` to find out which containers are still running. Once the obsolete containers have been identified, use `docker kill <NAME>` to terminate them.

#### Push the image to ECR

To deploy this new application on ECS, it will need to reside in Elastic Container Registry. Authenticate yourself with ECR on the AWS CLI with the following command

    aws ecr get-login-password --region <REGION> | \
    docker login \
    --username AWS \
    --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com
  
Once logged in, create a repository to hold the images

    aws ecr create-repository \
    --repository-name <NAME> \
    --image-scanning-configuration scanOnPush=true \
    --region <REGION>

Name the repository the same as the image tag. This repository is only meant for this individual demonstration image and avoids naming confusion when pushing it to ECR.

Once the repository is successfully made in AWS, we can push the image. Re-tag the image and then push it.

    docker tag <NAME>:latest <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<NAME>:latest

    docker push <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<NAME>:latest

Verify that the image is successfully in ECR-- recheck the naming/regions of your user’s configurations if unsuccessful.

#### Launch the cluster

Navigate to the ECS console and go to the Clusters page. Click Get Started to being configuring the cluster with the custom image. Under Container definition, click Configure on the custom tab. Open a new browser tab and copy/paste the image URL in ECR. Under port mappings, specify `8888`. Click Update and hit Next. Ignore the configuration for attach a load balancer and hit Next again. Finally, give the cluster a name and create it.

Allow time for the deployment to complete and look at the Tasks running beneath your cluster. Navigate to the single task that should be running and copy its Public IP address. Make sure its status is RUNNING. Paste that IP address into the browser and add `:8888` to the end of it. Verify that the Express server returns the proper message.
