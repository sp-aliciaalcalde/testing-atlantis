# Datadog monitoring stack
Terraform required_version is  0.13.6

## Remote Backend

Remote S3 Backend:
   - AWS Account: 3ants-ops
   - Bucket S3:  sp-sre-terraform/datadog/workspace_name/terraform.tfstate
   - Encrypted: enable ( server side encryption )
   - DynamoDB State Lock: Disabled

## External Stack Values
This datadog_keys variable in variables.tf file are Datadog keys stored in AWS secret manager.
 