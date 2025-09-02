locals {
  default_tags = {
    "alocasia:environment" = var.environment
    "alocasia:services"    = "gitlab-core"
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

data "aws_availability_zones" "available" {
  state = "available"
}

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket  = "alocasia-tfstate-${var.environment}"
    key     = "core/terraform.tfstate"
    profile = "alocasia"
    region  = "eu-west-1"
  }
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"

  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.this.zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  wait_for_validation = true

  tags = {
    Name = var.domain_name
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = "${local.name_prefix}-alb"
  vpc_id                     = data.terraform_remote_state.core.outputs.vpc.id
  subnets                    = data.terraform_remote_state.core.outputs.public_subnets[*].id
  enable_deletion_protection = false

  route53_records = {
    gitlab = {
      zone_id                   = data.aws_route53_zone.this.zone_id
      name                      = var.domain_name
      type                      = "A"
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
      cidr_ipv4   = "0.0.0.0/0"
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
      name_prefix       = "gitlab"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false
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
