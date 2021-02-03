# SmartProtection Terraform Stack

## Prerequisites

### Terraform version

Terraform required version: 0.14.4

## Structure 

This is the SmartProtection stack structure
```
|- base
  |- workspace.tf
  |- variables.tf
  |- locals.tf
  |- stack.tf
  |- remoteTfstate.tf
  |- outputs.tf
```

### Initialize environment

* Necessary AWS authentication
```
awsauth -p smart -e <environment> -r <your_role> --refresh
awsauth -p devops -e ops -r <your_role> --refresh
```

* Initialize terraform
```
terraform init
```

* Create the workspace
```
terraform workspace select <environment> || terraform workspace new <environment>
```

### Running the stack

* Plan your terraform
```
terraform plan
```

* Apply your terraform
```
terraform apply
```
