# wordpress-aws-terraform
A deployment of Wordpress on AWS with Terraform

## Terraform Installation

https://learn.hashicorp.com/tutorials/terraform/install-cli

## AWS CLI

for the terraform to AWS access:

You will have to create an IAM user with AdministratorAccess. You will need to install AWS CLI from here: https://aws.amazon.com/cli/ and run:

``` aws configure ```

and add the Access Key and the Secret Key from the IAM user account you have created earlier.

## Addiotional setup

You will have to create a Key Pair in AWS which is being used to login to the web servers that will host WordPress and install it using Ansible

For the DB crentials and the SSH Key you will have to edit the terraform/variables.tf 

When you create the Key Pair you should download the key automatically. Please edit the terraform/servers.tmpl with the location of the .pem file.


## Deploy

After you clone the git repe edit the DB credentials and the DB name, add your ssh key and run 

``` terraform init ``` in the terraform/ directory.

After successful completion you will have to modify the terraform/main.tf on line 286 and rename the ```aws_instance.wp0.public_ip``` to ```aws_instance.wp1.public_ip```

and run the ``` terraform apply -replace="null_resource.ansible" ``` command in order to have Ansible install the second WordPress instance.

After a successful run there should be an output of a public dns which you can use to open WordPress.
