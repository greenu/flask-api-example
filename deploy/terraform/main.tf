terraform {
  required_version = "~>0.11.14"
}

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
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]


  enable_nat_gateway = true
  enable_vpn_gateway = false
  create_database_subnet_group = true

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
  # TODO: fix https://github.com/cloudposse/terraform-aws-elastic-beanstalk-environment/issues/43
  source  = "cloudposse/elastic-beanstalk-environment/aws"
  version = "0.13.0"
  namespace = "${var.namespace}"
  stage     = "${var.environment}"
  name      = "${var.app}"
  app       = "${module.elastic_beanstalk_application.app_name}"

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
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.9.1 running Python 3.6"
  force_destroy       = true
  keypair             = "${var.keypair}"

  # TODO: find some way to secure RDS_PASSWORD
  env_vars = "${
      map(
        "FLASK_ENV", "production",
        "RDS_HOSTNAME", "${aws_db_instance.default.address}",
        "RDS_PORT", "${aws_db_instance.default.port}",
        "RDS_DB_NAME", "${aws_db_instance.default.name}",
        "RDS_USERNAME", "${aws_db_instance.default.username}",
        "RDS_PASSWORD", "${random_password.password.result}"
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


resource "aws_db_instance" "default" {
  name                 = "${var.namespace}-${var.environment}-${var.app}"
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "flask"
  username             = "flaskuser"
  # password stored as plaintext in tfstate, so use secure backend for it.
  password             = "${random_password.password.result}"
  parameter_group_name = "default.mysql5.7"
  # consider to make it false for production
  skip_final_snapshot  = true

  vpc_security_group_ids = ["${aws_security_group.db_security_group.id}"]
  db_subnet_group_name = "${module.vpc.database_subnet_group}"

  lifecycle {
   ignore_changes = ["password"]
 }
}

resource "random_password" "password" {
 length = 16
 special = true
}

resource "aws_security_group" "db_security_group" {
  name        = "${var.namespace}-${var.environment}-${var.app}-db-sg"
  description = "DB Security Group"
  vpc_id      = "${module.vpc.vpc_id}"

  // egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks}"]
  }

  // allow traffic for TCP 3306
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks}"]
  }
}