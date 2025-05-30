# Territory Balance Cloud Run

This work comes from a research initiative to incorporate a Territory Balance algorithm into workflows via (deprecated) custom components. See original source code [here](https://github.com/CartoDB/territory-balancing/tree/main). Notice that several changes were included to allow the execution of the remote function without using the BigQuery client: all necessary data is passed to the remote function in a single-row, json-formatted. 

A decription of the methodology used to balance a metric across a territory can be found [here](https://docs.google.com/document/d/1D8FGKQaO2P7ejjt2HsjLfptQ420L4Vis4WbjfgkKFrc/edit).

## Requirements

For the installation and deployment of the remote function, you need to have the following tools installed:

- [Docker](https://docs.docker.com/get-docker/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

## Deployment

Inside the `cloudrun/territorybalance` folder, run in terminal the following command to login to GCloud:

```
gcloud auth login
```

Then, run the following command to build the base image for the Docker container used by Cloud Run, deploy the Cloud Run services and create the remote function using a Cloud resource connection.

```
./deploy.sh
```
> [!WARNING]  
> For this to work, your credentials should grant you access to all resources used here.

> [!IMPORTANT]  
> All services and functions will be deployed to the specified Google Cloud Project. Follow the steps below to install and deploy everything from scratch, including the Cloud Run function and its integration with BigQuery.
> ### 1. Docker base image
> First of all, you need to build the base image for the Docker container used by Cloud Run. This image contains all the dependencies needed to run the workflows.
> Go to [Artifact Registry](https://console.cloud.google.com/artifacts) and create a new repository called `territory-balancing` with format **Docker** and region **us-east1**.
> Open the `build-base.sh` file and change the following line with your project id:
> ```
> PROJECT_ID="<your-project>"
> ```
> To build the Docker image and deploy it to GCloud Docker Artifacts (before you need to login to GCloud), you need to start Docker in your machine and run the following command:
> ```
> ./build-base.sh
> ```
> ### 2. Cloud Run
> Once the base image is built, you can deploy the Cloud Run services. This service will be used to run the workflows.
> Edit the following lines in the `app/build-run.sh` file:
> ```
> PROJECT_ID="<your-project>"
> ```
> And the following line in the `app/Dockerfile` file:
> ```
> FROM us-central1-docker.pkg.dev/<my-project>/territory-balancing/territory-balancing
> ```
> Then, deploy the Cloud Run service for the Territory Balancing solver:
> ```
> cd app
> ./build-run.sh
> ```
> Once the service has been created, you will be able to see it listed in your Cloud Run. For the next step, you will need its endpoint URL. To access it, go to Cloud Run and click on the > service you have created:
> <img width="929" alt="Screenshot 2023-07-28 at 11 45 59" src="https://github.com/CartoDB/territory-balancing/assets/63408159/1a412a2d-5bac-4e47-affc-caa0dbcc2bdc">
> ### 3. BigQuery remote function
> To deploy the remote function that runs the Cloud Run service, you need to have access to a Cloud resource connection. Follow [this](https://cloud.google.com/bigquery/docs/remote-functions#create_a_connection) steps to create one if needed. Include the endpoint URL of your service in `_territory_balancing.sql`:
> ```
> CREATE OR REPLACE FUNCTION `<your project>`.<your dataset>._territory_balancing(
> ...
> REMOTE WITH CONNECTION `<my-connection>`
>   OPTIONS( max_batching_rows = 1, endpoint = '<my-endpoint>')
> ```
> Lastly, run the following command in the terminal:
> ```
> bq query --use_legacy_sql=false < _territory_balancing.sql
> ```
> ### 4. Workflows component
> Remember also to update the location (FQN) of the remote function in the component's fullrun if needed (`../../components/territorybalancing/src/fullrun.sql`)
>```
>SELECT `<your project>`.<your dataset>._territory_balancing(...)
>```
