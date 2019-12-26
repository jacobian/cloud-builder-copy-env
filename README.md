# Copy env vars from Cloud Run to Cloud Build 

![It's a Hack!](hack.jpg)

So you have a Cloud Run service, and you'd like to run a build step that has access to some secrets stored in your service's env vars -- like a database migration, for example.

You could do this the right, by [messing with KMS and secrets and stuff](https://github.com/GoogleCloudPlatform/django-demo-app-unicodex). But you're lazy, and env vars are fine by your threat model.

So here's this dingus. It'll copy env vars from a Cloud Run service into an env file, which you can then read in a later build step.

## Usage

1. Push this guy to your private container registry so you can use it in cloudbuild:

   ```bash
   git clone https://github.com/jacobian/cloud-builder-copy-env
   cd cloud-builder-copy-env
   gcloud builds submit
   ```

2. Grant permissions - this guy needs to be able to be able to read env vars from that project:

   ```bash
   export PROJECT_ID=your-project-id
   export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
   export SERVICE_ACCOUNT="${PROJECT_NUMBER@cloudbuild.gserviceaccount.com"

   gcloud projects add-iam-policy-binding ${PROJECT_ID} \
     --member serviceAccount:$SERVICE_ACCOUNT \
     --role roles/run.admin
   ```

   NB: you may also want to add `roles/cloudsql.client` while you're at it, as if you're using this for the common database migration use case, you'll need that permission later too.

   FIXME: is this correct? I did things differently so I'm not 100% sure.

3. Use this build step in your cloudbuild.yaml:

   ```yaml
     - id: copyenv
       name: gcr.io/$PROJECT_ID/copyenv
       args: [--service, your-service-name]
   ```

   This takes some optional arguments:
    
    * `--region` (default: `us-central`)
    * `--platform` (default: `managed`)
    * `--dest` (default: `/workspace.env`)

This will write all your secrets to `/workspace/.env`, which is automatically persisted between build steps. So subsequent build steps can read from there and pick up all your config. 

For example, I use [django-environ](https://django-environ.readthedocs.io/en/latest/), so my Django settings file has something like this:

```python
import environ

env = environ.Env()
env.read_env(os.environ.get("ENV_FILE", ".env"))
DATABASES = {"default": env.db()}
```

And I make sure that my migration build step looks like:

```yaml
  - id: release
    name: gcr.io/google-appengine/exec-wrapper
    args:
      - -i
      - gcr.io/$PROJECT_ID/my-service-name
      - -e
      - ENV_FILE=/workspace/.env  # <- 👀 this is the important line
      - --
      - sh
      - release.sh
``` 
