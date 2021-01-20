# SmartProtection AWS Infrastructure with Terraform

## Prerequisites
### Install Terraform

Download Terraform package and add the binary to the PATH 
https://www.terraform.io/downloads.html

If you need several terraform versions use this tool: https://github.com/tfutils/tfenv

## Structure 

This is the SmartProtection structure
```
|- terraform
   |- stacks
      |- datadog
          |- workspace.tf
          |- variables.tf
          |- locals.tf
          |- stack.tf
          |- remoteTfstate.tf
          |- outputs.tf
      |- vpn
          |- workspace.tf
          |- variables.tfvars
          |- stack.tf
          |- remoteTfstate.tf
          |- outputs.tf
   |- modules
      |- datadog_monitor
      

```

### Configure remote tfstate 
1.- Create your S3 remote tfstate configuration file following this documentation: https://www.terraform.io/docs/backends/types/s3.html 
2.- Create and IAM User and assign the following IAM policy

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::mybucket"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::mybucket/path/to/my/key"
    }
  ]
}
```

3.- Configure your IAM User credentials or create and profile in $HOME/.aws/credentials

### Initialize environment

* Initialize terraform

```
AWS_PROFILE="devops-ops-admin" terraform init
```
* Create the workspace, for example  pro

```
export TF_WORKSPACE=pro
AWS_PROFILE="devops-ops-admin" terraform workspace select $ TF_WORKSPACE|| AWS_PROFILE="devops-ops-admin" terraform workspace new $TF_WORKSPACE
```


### Running the stack
* Plan your terraform
  
```
export TF_WORKSPACE=pro
AWS_PROFILE="devops-ops-admin" terraform workspace select <TF_WORKSPACE>
AWS_PROFILE="devops-ops-admin" terraform workspace plan
```
