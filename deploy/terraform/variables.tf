variable "app" {
  default = "flask-api"
}

variable "api_dist" {
    default = "flask_api"
}

variable "namespace" {
    default = "example-namespace"
}

variable "environment" {
  default = "demo-env"
}

variable "region" {
  default = "us-west-2"
}

variable "max_availability_zones" {
    default = 2
}

variable "keypair" {
    default = "devops_vpc_infra"
}
