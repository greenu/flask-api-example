provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> v1.0"

  name = "${var.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${slice(data.aws_availability_zones.available.names, 0, var.max_availability_zones)}"]
  # TODO: automation on below lists length. must be same as max_availability_zones
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "${var.environment}"
  }
}

# create a zip of your deployment with terraform
data "archive_file" "api_dist_zip" {
  type        = "zip"
  source_dir = "${path.root}/../../app/"
  output_path = "${path.root}/dist.zip"
}

resource "aws_s3_bucket" "dist_bucket" {
  bucket = "${var.namespace}-beanstalk-deploy"
  acl    = "private"
}
resource "aws_s3_bucket_object" "dist_item" {
  key    = "${var.environment}/dist-${uuid()}"
  bucket = "${aws_s3_bucket.dist_bucket.id}"
  source = "${data.archive_file.api_dist_zip.output_path}"
}

module "elastic_beanstalk_application" {
  source  = "cloudposse/elastic-beanstalk-application/aws"
  version = "0.1.6"
  namespace = "${var.namespace}"
  stage     = "${var.environment}"
  name      = "${var.app}"
  description = "Test elastic_beanstalk_application"
}

module "elastic_beanstalk_environment" {
  source  = "cloudposse/elastic-beanstalk-environment/aws"
  version = "0.13.0"
  # insert the 8 required variables here
  namespace = "${var.namespace}"
  stage     = "${var.environment}"
  name      = "${var.app}"
#   zone_id   = "${var.zone_id}"
  app       = "${module.elastic_beanstalk_application.app_name}"
#   application_port = "5000"

  instance_type           = "t2.small"
  autoscale_min           = 1
  autoscale_max           = 2
  updating_min_in_service = 0
  updating_max_batch      = 1

  loadbalancer_type   = "application"
  vpc_id              = "${module.vpc.vpc_id}"
  public_subnets      = "${module.vpc.public_subnets}"
  private_subnets     = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_security_group_id}"]
#   solution_stack_name = "64bit Amazon Linux 2018.03 v2.12.10 running Docker 18.06.1-ce"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.9.1 running Python 3.6"
  force_destroy       = true
  keypair             = "${var.keypair}"

  env_vars = "${
      map(
        "FLASK_ENV", "production"
      )
    }"
}

resource "aws_elastic_beanstalk_application_version" "default" {
  name        = "${var.namespace}-${var.environment}-${uuid()}"
  application = "${module.elastic_beanstalk_application.app_name}"
  description = "application version created by terraform"
  bucket      = "${aws_s3_bucket.dist_bucket.id}"
  key         = "${aws_s3_bucket_object.dist_item.id}"
}