# Setting up a Docker Build Server Image with support for a local Terraform Provider Mirror containing multiple provider versions

The pattern of using a Docker image with specific versions of the tools and dependencies preloaded into the image is not new or novel. Yet, when looking for steps to apply this pattern to Terraform Provider Versions, examples and documentation covering this are a bit challenging to find and piece together. Specifically, if you are looking to support multiple build targets that may have differing provider version requirements.

In this post, I will cover the basic setup of the build image and then introduce one approach for capturing and preloading the terraform provider versions into a local mirror within the build image.

The benefits of a Build Server Image with pinned, preloaded dependency versions are:

* Improved build times. Resources do not have to be pulled down from the Internet each time a build is performed.  Download once into the image, and re-use it many times.

* Consistency. The same version of the tools and dependencies are used each time you build. A newer version of a dependency introduced between builds should not impact the build artifacts as long as all dependencies are properly pinned in the build image.  When working across a team of developers if everyone is using the same version of the build image you can have confidence that each developer will be building identical build artifacts irrespective of differences in their development environments and O/S platforms. 

* Versioning Tracking, using version tags with your build server image coupled with a source code repository & artifact registry you can have improved accountability and reproducibility.  Adding metadata to your application as to what version build image was used to build it makes it easier to trace back and have confidence about the configuration used to build a release when troubleshooting.

* Security, improve your security posture by not reaching out to the Internet for resources each time you build.  The ability to scan the build image for malicious artifacts can help ensure your tooling does not have security flaws.

The following sections will walk you through setting up a simple test Terraform application and Docker build image.  We will demonstrate how add the ability to capture and use local terraform provider mirror.

---

## Setup Example Environment

To work through the example code we will be covering, create the following directory structure in your home directory.

From your shell run:

```
mkdir -p ~/example/app
mkdir -p ~/example/buildimage
```

You will also need a somewhat recent version of both Docker and Terraform installed on your machine.

To check what you have run:

```
terraform --version
docker --version
```

It is ok if the version of Terraform installed on your machine is different from the version we will be installing in the build image. This is one of the benefits of using a build image to ensure consistency across multiple machines and developers.

* [Docker install instructions](https://docs.docker.com/get-docker/)
* [Terraform install instructions](https://www.terraform.io/downloads)


## Simple Terraform Environment

In the `~/example/app` directory create the following `main.tf` file:

```
#see: https://www.terraform.io/language/providers/requirements

terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = ">= 4.0.0"
    }
    cloudinit = {
      source  = "registry.terraform.io/hashicorp/cloudinit"
      version = ">= 2.0.0"
    }
    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = ">= 0.0.0"
    }
    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = ">= 0.0.0"
    }
    artifactory = {
      source  = "registry.terraform.io/jfrog/artifactory"
      version = ">= 0.0.0"
    }
  }
}

locals {
  test = "Hello World!"
}

output mytest {
    value = local.test
}
```

This code prints out "Hello World!", but also requires the five specified providers to be imported when a `terraform init` command is run.

From your shell run:

```
cd ~/example/app
terraform init
```

The output should look something like this:

```
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding jfrog/artifactory versions matching ">= 0.0.0"...
- Finding hashicorp/aws versions matching ">= 4.0.0"...
- Finding hashicorp/cloudinit versions matching ">= 2.0.0"...
- Finding hashicorp/external versions matching ">= 0.0.0"...
- Finding hashicorp/null versions matching ">= 0.0.0"...
- Installing jfrog/artifactory v6.10.1...
- Installed jfrog/artifactory v6.10.1 (signed by a HashiCorp partner, key ID 6B219DCCD7639232)
- Installing hashicorp/aws v4.22.0...
- Installed hashicorp/aws v4.22.0 (signed by HashiCorp)
- Installing hashicorp/cloudinit v2.2.0...
- Installed hashicorp/cloudinit v2.2.0 (signed by HashiCorp)
- Installing hashicorp/external v2.2.2...
- Installed hashicorp/external v2.2.2 (signed by HashiCorp)
- Installing hashicorp/null v3.1.1...
- Installed hashicorp/null v3.1.1 (signed by HashiCorp)

Partner and community providers are signed by their developers.

If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

The key thing to take note of are the five lines that start with - Installed, each of these, list :
* the provider name, 
* the version installed, and 
* an indicator of the downloaded version being signed.

Since each one of our version requirements in the `main.tf` file are asking for the latest version (`>=`), the versions returned here will be the most up-to-date available on the public mirrors.

At the time of this writing we got:
* hashicorp/aws **v4.22.0** (signed by HashiCorp)
* hashicorp/cloudinit **v2.2.0** (signed by HashiCorp)
* hashicorp/external **v2.2.2** (signed by HashiCorp)
* hashicorp/null **v3.1.1** (signed by HashiCorp)
* jfrog/artifactory **v6.10.1** (signed by a HashiCorp partner, key ID 6B219DCCD7639232)

Take note of these versions as we will be referring back to them later on when we pin our local mirror to alternate versions.

If you run the `terraform init` command a second time you should see:

```
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/cloudinit from the dependency lock file
- Reusing previous version of hashicorp/external from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of jfrog/artifactory from the dependency lock file
- Using previously-installed hashicorp/aws v4.22.0
- Using previously-installed hashicorp/cloudinit v2.2.0
- Using previously-installed hashicorp/external v2.2.2
- Using previously-installed hashicorp/null v3.1.1
- Using previously-installed jfrog/artifactory v6.10.1

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

The output is indicating the versions previously downloaded are still the most up-to-date versions and the previously downloaded versions will be used.

Had a newer version of any of these five providers been released since last running the command, that version would have been downloaded and reported back as the version that will be used in subsequent terraform commands such as `plan`, `apply`, and `destroy`.

Lastly, lets take a look at how the apply command behaves in this configuration. 

Run:

```
terraform apply -auto-approve
```

The output should look something like this:

```
$ terraform apply -auto-approve

Changes to Outputs:
  + mytest = "Hello World!"

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

mytest = "Hello World!"
```

Clearly, the code does not do anything noteworthy and the providers we have defined do not impact the output in any fashion. As such, we will only be focusing on the effects on how the `terraform init` command behaves for the remainder of this article.


## Base Docker image

Create a `Dockerfile` file in the `~/example/buildimage` directory with the following contents:

```
FROM centos:7 AS orig

RUN yum -y install \
      curl \
      git \
      make \
      unzip \
   && yum -y clean all \
   && rm -rf /var/cache

###############
### AWS CLI ###
###############
ENV AWS_CLI_V2_VERSION=2.7.11

###############
## TERRAFORM ##
###############
## https://github.com/hashicorp/terraform/blob/main/CHANGELOG.md
## https://www.terraform.io/downloads
## https://releases.hashicorp.com/terraform/
ENV TERRAFORM_VERSION=1.1.9

RUN curl -L \
      -o "awscliv2.zip" \
      "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_V2_VERSION}.zip" \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf ./awscliv2.zip ./aws

RUN curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

## Clean up excess files
RUN rm -rf /root/.pki

############################
### flatten Docker Image ###
############################
FROM scratch
COPY --from=orig / /

ARG BUILD_IMAGE_VERSION
ENV BUILD_IMAGE_VERSION ${BUILD_IMAGE_VERSION}
LABEL build.image.version=${BUILD_IMAGE_VERSION}
```

The above image preloads `git`, `make`, `unzip`, and `curl`. As well as pinned versions of `terraform` and the `aws` cli. You can add whatever tools you like for your build environment requirements.

The `Dockerfile` expects one passed-in build argument, `BUILD_IMAGE_VERSION`, this is the version number you can assign to the build image. The value is exposed as both a label on the docker image and an environment variable within the container.

Additionally, We have flattened the image to have the smallest image size possible. Build images in most environments are generally unique and do not lend themselves to the benefits of sharing image layers.


## Image Build

With the above `Dockerfile` saved in the `~/example/buildimage` directory it is time to build the image.

Run the following command from a shell:

```
cd ~/example/buildimage
docker build \
   --progress plain \
   --tag "base_buildimage:1.0.0" \
   --tag "base_buildimage:latest" \
   --build-arg BUILD_IMAGE_VERSION="1.0.0" \
   --file ./Dockerfile .
```

If the commands were successful we can now attempt to use our new build image to initialize our example Terraform environment.

Run:

```
cd ~/example/
docker run --rm -ti \
  --name "myBuildContainer" \
  --volume $(pwd):/root/src \
  --workdir /root/src \
  "base_buildimage:1.0.0" \
  terraform -chdir=./app  init
```

You will likely get output that looks like this:

```
$ cd ~/example/
$ docker run --rm -ti \
>   --name "myBuildContainer" \
>   --volume $(pwd):/root/src \
>   --workdir /root/src \
>   "base_buildimage:1.0.0" \
>   terraform -chdir=./app  init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/cloudinit from the dependency lock file
- Reusing previous version of hashicorp/external from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of jfrog/artifactory from the dependency lock file
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/cloudinit v2.2.0
- Using previously-installed hashicorp/external v2.2.2
- Using previously-installed hashicorp/null v3.1.1
- Using previously-installed jfrog/artifactory v6.10.1
- Using previously-installed hashicorp/aws v4.22.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

If you did not run the initial terraform init command from earlier the output will look different. The output above should look like those when we ran the `terraform init` command a second time earlier.

Regardless, you will note the provider versions should be the same as those from before.

Run:
```
ls -la  ~/example/app
```

From the file listing the Terraform state and lock files are visible as well as the `.terraform` directory.

Next we will clear all of these so that the directory only includes the `main.tf` file, and then we will rerun the `terraform init` from within the build image:

```
rm -rf ~/example/app/.terraform \
   ~/example/app/.terraform.lock.hcl \
   ~/example/app/terraform.tfstate

cd ~/example/
docker run --rm -ti \
  --name "myBuildContainer" \
  --volume $(pwd):/root/src \
  --workdir /root/src \
  "base_buildimage:1.0.0" \
  terraform -chdir=./app  init
```

This time the output should look almost identical to the `terraform init` command we performed at the start of this article.

Lastly, lets look at the tool versions within the build image:

```
cd ~/example/
docker run --rm -ti \
  --name "myBuildContainer" \
  --volume $(pwd):/root/src \
  --workdir /root/src \
  "base_buildimage:1.0.0" \
  bash
```

This should bring you to a bash shell in the container the prompt may look something like this:

```
$ docker run --rm -ti \
   --name "myBuildContainer" \
   --volume $(pwd):/root/src \
   --workdir /root/src \
   "base_buildimage:1.0.0" \
   bash
[root@4a87daf18f42 src]#
```

To exit the bash shell simply type exit, but before doing that lets check a few things:

```
terraform --version
aws --version
env | grep BUILD
```

The output will look like this:

```
[root@4a87daf18f42 src]# terraform --version
Terraform v1.1.9
on linux_amd64
Your version of Terraform is out of date! The latest version
is 1.2.4. You can update by downloading from https://www.terraform.io/downloads.html
[root@4a87daf18f42 src]# aws --version
aws-cli/2.7.11 Python/3.9.11 Linux/5.10.102.1-microsoft-standard-WSL2 exe/x86_64.centos.7 prompt/off
[root@4a87daf18f42 src]# env | grep BUILD
BUILD_IMAGE_VERSION=1.0.0
[root@4a87daf18f42 src]#
```

You should be able to match up the version of `terraform` and `aws` to the versions we pinned in the Dockerfile. The environment variable define in the Dockerfile is also visible.

What is not pinned are the Terraform Providers. These are still being pulled from the Internet and are floating to the most recent version at the time `terraform init` command is executed. 

Not super helpful in ensuring consistency and reproducibility.

This can be remedied by changing the version requirements in the `main.tf` file from (`>=`) to (`=`), but this will still leave the provider files being downloaded from the Internet each time the `terraform init` command is run.

### Related Terraform Documentation

* [Terraform Version Constraints](https://www.terraform.io/language/expressions/version-constraints)
* [Terraform Provider Requirements](https://www.terraform.io/language/providers/requirements)


---

## Completed Milestones

* Demonstrated Simple Terraform example using required providers and its interactions with the `terraform init` command.
* Constructed and Demonstrated a basic Docker Build Server Image
* Ran the `terraform init` command from within the Build Server Image and observed the same results and artifacts.

In the next section, we will cover establishing a local file system mirror that provides a pinned subset of terraform providers you can rely on being consistent and locally available from one build to the next.

---

## Adding a Terraform Provider Mirror 

Terraform has support for several different types of mirrors. There are nuanced differences between the various forms, to avoid going down too many rabbit holes I am going to limit the scope of this article to just a file system-based form using the default file locations and optional terraform configuration files.
At the heart of this approach is the terraform provider mirror command, and the default Linux file system location for local providers (`/usr/local/share/terraform/plugins`).

I would NOT recommend using the terraform provider mirror command on your local machine using the default directory, as once you set that, it is easy to forget that it is in place and several months later you may pull your hair out trying to figure out why you are not able to gain access to newer provider versions. But in a build image where you are actively pinning all of your resources to specific versions, this is an ideal use case.

## Define the pinned versions

Create a `setone.tf` file in the `~/example/buildimage` directory with the following contents:

```
#see: https://www.terraform.io/language/providers/requirements

terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "4.2.0"
    }
    cloudinit = {
      source  = "registry.terraform.io/hashicorp/cloudinit"
      version = "2.2.0"
    }
    # only in Set 1
    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = "2.1.0"
    }
  }
}
```

Note we are not using floating version definitions, but rather explicit versions. For example of floating version definition review our earlier file ~/example/app/main.tf, all of the definitions there are floating.

If we had used floating version definitions (>=) the version loaded into the image would be the most recent version and could change each time the build image is built.

This might be an acceptable approach for your use case, but just be aware of what you are doing. If following this approach I would recommend issuing a new version number for your build image each time it is built as you will likely not be aware of individual provider version changes. This should not be too big of a deal if you are saving your images in a registry as the hash from one build to the next if nothing actually changed will likely be the same.

If you follow the approach of hard pinning of provider versions you can manually change your build image version when you make a change to the files defining your pinnings ( Dockerfile and setone.tf ).

## Revise the Dockerfile

Next, we need to add some commands to the Dockerfile. To keep track of what we have done so far we are going to make a copy of our current file and make changes to the new file:

Do the following:

```
cd ~/example/buildimage
cp Dockerfile Dockerfile_Mirror
```

Using your preferred editor open Dockerfile_Mirror.

Replace the two lines in the file:

```
## Clean up excess files
RUN rm -rf /root/.pki
```

with the following lines:

```
RUN mkdir -p /tmp/setone
ADD ./setone.tf /tmp/setone

RUN terraform -chdir=/tmp/setone \
  providers mirror \
#   -platform=windows_amd64 \
#   -platform=darwin_amd64 \
   -platform=linux_amd64 \
  /usr/local/share/terraform/plugins

## Clean up excess files
RUN rm -rf /root/.terraform.d /root/.pki /tmp/setone
```

Here is what we are doing and why:
* Create a temporary directory we can place our pinned requirements file into.
* Copy `setone.tf` into the directory.
* Run `terraform providers mirror` command in the temporary directory
  * Specify `/usr/local/share/terraform/plugins` as the target directory, which is the default location for local mirror files for Terraform on Linux.
  * You could include other platforms (currently commented out), if your use case would require them.  But since the build image is based on Linux we are only selecting the Linux platform files.
* Lastly we clean up unnecesary artifacts that are not needed in the build image.

For more details on mirrors see [Terraform Provider Mirrors]()

## Mirror Image Build

Run the following command from a shell:

```
cd ~/example/buildimage
docker build \
   --progress plain \
   --tag "mirror_buildimage:1.0.0" \
   --tag "mirror_buildimage:latest" \
   --build-arg BUILD_IMAGE_VERSION="1.0.0" \
   --file ./Dockerfile_Mirror .
```

If the command is successful we can now attempt to use our new build image to initialize our example Terraform environment from within the build image.

Run:

```
cd ~/example/
docker run --rm -ti \
  --name "myBuildContainer" \
  --volume $(pwd):/root/src \
  --workdir /root/src \
  "mirror_buildimage:1.0.0" \
  terraform -chdir=./app  init
```

note the version pulled in now

---

## Multiple versions

The above is all well and good if everyone using your build image can live with just the single version of each provider, but what do you do when you want to test or use a different version of a provider for some of the environments you are building with this build image?

The terraform provider mirror command will give yiou an error if you attempt to list the same provider twice.

So the approach that will work is having multiple requirement files in different directories and running `terraform provider mirror` against each but target the same target directory.


## Define a second (third, fourth, ...) pinned version file

Create a `settwo.tf` file in the `~/example/buildimage` directory with the following contents:

```
#see: https://www.terraform.io/language/providers/requirements

terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "4.10.0"
    }
    cloudinit = {
      source  = "registry.terraform.io/hashicorp/cloudinit"
      version = "2.1.0"
    }
    # only in Set 2
    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = "3.1.0"
    }
  }
}
```

The list of providers does not have to match what is in the other provider requirement file.

## Revise another Dockerfile

Next, we need to add additional commands to the Dockerfile. We will copy the last DOckerfile into another new file.

Do the following:

```
cd ~/example/buildimage
cp Dockerfile_Mirror Dockerfile_MultiVer
```

Using your preferred editor open `Dockerfile_MultiVer`.

Replace the two lines in the file:

```
## Clean up excess files
RUN rm -rf /root/.terraform.d /root/.pki /tmp/setone
```

with the following lines:

```
RUN mkdir -p /tmp/settwo
ADD ./settwo.tf /tmp/settwo

RUN terraform -chdir=/tmp/settwo \
  providers mirror \
   -platform=linux_amd64 \
  /usr/local/share/terraform/plugins

## Clean up excess files
RUN rm -rf /root/.terraform.d /root/.pki /tmp/setone /tmp/settwo
```

## Multi Version Image Build

Run the following command from a shell:

```
cd ~/example/buildimage
docker build \
   --progress plain \
   --tag "multiver_buildimage:1.0.0" \
   --tag "multiver_buildimage:latest" \
   --build-arg BUILD_IMAGE_VERSION="1.0.0" \
   --file ./Dockerfile_MultiVer .
```

If the command is successful we can now attempt to use our new build image to initialize our example Terraform environment from within the build image.

Run:

```
cd ~/example/
docker run --rm -ti \
  --name "myBuildContainer" \
  --volume $(pwd):/root/src \
  --workdir /root/src \
  "multiver_buildimage:1.0.0" \
  terraform -chdir=./app init
```

note the versions now pulled in now

---
