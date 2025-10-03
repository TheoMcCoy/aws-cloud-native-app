variable "region" {
  type = string
  default = "us-east-1"
}

variable "name_prefix" {
  type = string
  default = "demo"
}

variable "project" {
  description = "Project name 9used in bucket names, tags, etc."
  type = string
  default = "webapp-demo"
}

variable "vpc_cidr" {
  type = string
  default = "10.100.0.0/16"
}

variable "public_subnet_cidr" {
  type = list(string)
  default = [ "10.100.0.0/24", "10.100.1.0/24" ]
}

variable "private_subnet_cidr" {
  type = list(string)
  default = [ "10.100.100.0/24", "10.100.101.0/24" ]
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name (existing) - optional if using SSM only"
  type        = string
  default     = "solution"
}

variable "allowed_ssh_cidr" {
  description = "CIDR for ssh access (set to your IP/32) - keep tight or set 0.0.0.0/0 for testing"
  type = string
  default = "0.0.0.0/0"
}

variable "asg_min_size" {
  type = number
  default = 2
}

variable "asg_max_size" {
  type = number
  default = 4
}

variable "asg_desired_capacity" {
  type = number
  default = 2
}

variable "web_git_repo" {
  type = string
  default = "https://github.com/cloudacademy/webgl-globe.git"
}

variable "db_instance_type" {
  description = "MongoDB instance type"
  type = string
  default = "t3.small"
}

variable "frontend_repo" {
  description = "Github repo for frontend releases in form owner/repo"
  type = string
  default = "cloudacodemy/voteapp-frontend-reach-2020"
}

variable "api-repo" {
  description = "Github repo for API release in form wner/repo"
  type = string
  default = "cloudacademy/voteapp-api-go"
}

