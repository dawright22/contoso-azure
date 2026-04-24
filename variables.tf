# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  default     = "us-west-1"
}

variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.micro"
}

variable "instance_name" {
  description = "EC2 instance name"
  default     = "contoso-web-server"
}

variable "app_name" {
  description = "Application name"
  default     = "contoso-web"
}

variable "app_artifact_path" {
  description = "Path to the local application archive in this repository"
  default     = "app/contoso-web.tar.gz"
}

variable "enable_https" {
  description = "Enable HTTPS (requires SSL certificate)"
  default     = false
}

variable "node_env" {
  description = "Node environment"
  default     = "production"
}

