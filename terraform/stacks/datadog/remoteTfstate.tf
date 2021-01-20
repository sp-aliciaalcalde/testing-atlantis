terraform {
  required_version = "= 0.13.6"
  
  backend "s3" {
    bucket               = "sp-sre-terraform"
    region               = "eu-west-1"
    encrypt              = true
    key                  = "terraform.tfstate"
    workspace_key_prefix = "datadog"
  }
}