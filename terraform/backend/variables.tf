variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile used for authentication."
  type        = string
  default     = "default"
}

variable "tags" {
  description = "A map of tags to apply to all AWS resources."
  type        = map(string)

  default = {
    environment = "develop"
    owner       = "devops"
    managedBy   = "terraform"
  }
}