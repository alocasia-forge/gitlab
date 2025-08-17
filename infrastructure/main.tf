locals {
  default_tag = {
    "alocasia:environment" = var.environment
    "alocasia:services"     = "gitlab-core"
  }
  name_prefix = "alocasia-gitlab-${var.environment}"
}

data "aws_route53_zone" "this" {
  name         = "matih.eu"
  private_zone = false
}

# GitLab AMI 18.0.2
data "aws_ami" "this" {
  most_recent = false
  owners      = ["782774275127"]
  
  filter {
    name   = "image-id"
    values = ["ami-01423c5ee7f64241a"]
  }
}


module "acm" {
  source  = "terraform-aws-modules/acm/aws"

  domain_name  = var.domain_name
  zone_id      = data.aws_route53_zone.this.zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  wait_for_validation = true

  tags = {
    Name = var.domain_name
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name_prefix
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "${local.name_prefix}-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  enable_deletion_protection = false

  route53_records = {
    gitlab = {
      zone_id = data.aws_route53_zone.this.zone_id
      name    =  var.domain_name
      type    = "A"
      subject_alternative_names = ["*.${var.domain_name}"]
      alias = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      } 
    }
  }

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn

      forward = {
        target_group_key = "tg"
      }
    }
  }

  target_groups = {
    tg = {
      name_prefix        = "gitlab"
      protocol           = "HTTP"
      port               = 80
      target_type        = "instance"
      create_attachment  = false
      health_check = {
        enabled             = true
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        path                = "/users/sign_in"
        matcher             = "200"
        port                = "80"
        protocol            = "HTTP"
      }
    }
  }
}
