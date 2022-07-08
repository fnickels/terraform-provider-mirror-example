# terraform-mirror-issue

Demonstration of Terraform provider mirror issue

## Prerequisits

AWS Account & Credentials

## Setup

Create `secrets.env` file with commands to establish AWS credentials.  We use [keyconjurer](https://github.com/RiotGames/key-conjurer) so my `secrets.env` file looks like:

```bash
$(keyconjurer get dev-account --role=GL-PowerUser)
```

but a more traditional `secrets.env` file might look like:

```bash
export AWS_ACCESS_KEY_ID=<key id goes here>
export AWS_SECRET_ACCESS_KEY=<access key goes here>
export TF_VAR_access_key=$AWS_ACCESS_KEY_ID
export TF_VAR_secret_key=$AWS_SECRET_ACCESS_KEY
```

## Issue Reproduction:

```bash
source secrets.env
make init
make build
make destroy
```


## Terraform Articales

https://www.terraform.io/cli/config/config-file#plugin_cache_dir
https://www.terraform.io/cli/commands/init
https://www.terraform.io/cli/commands/providers/mirror