# wordpress-aws-terraform
A deployment of Wordpress on AWS with Terraform

## Terraform Installation

https://learn.hashicorp.com/tutorials/terraform/install-cli

## AWS CLI

for the terraform to AWS access:

You will have to create an IAM user with AdministratorAccess. After that you click on the user name and choose the "Security Credentials" tab. Create and Access key. Copy the Access key and the secret key. 

You will need to install AWS CLI from here: https://aws.amazon.com/cli/ and run:

``` aws configure ```

add the Access Key and the Secret Key from the IAM user account you have created earlier. Type json for the default output format and type your region.

## Additional setup

You will have to create a Key Pair in AWS which is being used to login to the web servers that will host WordPress and install it using Ansible

For the DB credentials and the SSH Key you will have to edit the terraform/variables.tf with the desired DB name, username for the DB and the password. Terraform will use those.

When you create the Key Pair you should download the key automatically. Please edit the terraform/servers.tmpl with the location of the .pem file.


## Deploy

After you clone the git repo edit the DB credentials and the DB name, add your ssh key and run 

``` terraform init ``` in the terraform/ directory.

After successful completion you will have to modify the terraform/main.tf on line 286 and rename the ```aws_instance.wp0.public_ip``` to ```aws_instance.wp1.public_ip```

and run the ``` terraform apply -replace="null_resource.ansible" ``` command in order to have Ansible install the second WordPress instance.

After a successful run there should be an output of a public dns which you can use to open WordPress.
