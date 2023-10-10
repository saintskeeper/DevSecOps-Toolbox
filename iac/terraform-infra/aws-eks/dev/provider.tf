# Configure the AWS provider
provider "aws" {
  region = "us-west-2" # Change this to your desired AWS region
}

# Configure the Terraform backend to use an S3 bucket
terraform {
  backend "s3" {
    bucket  = "devops-infra-walt-01" # Replace with your S3 bucket name
    key     = "terraform.tfstate"    # Replace with your state file name
    region  = "us-west-2"            # Replace with your desired AWS region
    encrypt = true                   # Optional: Set to true to enable server-side encryption
  }
}
