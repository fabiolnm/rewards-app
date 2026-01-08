terraform {
  backend "s3" {
    # Bucket name will be: rewards-app-tf-state-{account-id}
    # Replace {account-id} with your AWS account ID or run:
    #   terraform init -backend-config="bucket=rewards-app-tf-state-$(aws sts get-caller-identity --query Account --output text)"

    key            = "terraform.tfstate"
    region         = "ca-west-1"
    encrypt        = true
    dynamodb_table = "rewards-app-tf-locks"
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
