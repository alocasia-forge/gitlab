# GitLab EC2 Instance
resource "aws_instance" "this" {
  ami           = data.aws_ami.this.id
  instance_type = "t3.large"
  key_name      = var.key_name
  subnet_id     = data.terraform_remote_state.core.outputs.private_subnets[0].id

  vpc_security_group_ids = [aws_security_group.gitlab_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name

  user_data = templatefile("${path.module}/templates/userdata.sh", {
    gitlab_external_url = "https://${var.domain_name}"
    rds_endpoint        = aws_db_instance.this.endpoint
    rds_username        = aws_db_instance.this.username
    rds_password        = random_password.rds.result
    rds_database        = aws_db_instance.this.db_name
  })
}

# Target Group Attachment for GitLab Instance
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = module.alb.target_groups["tg"].arn
  target_id        = aws_instance.this.id
  port             = 80
}

# Security Group
resource "aws_security_group" "gitlab_sg" {
  name   = "${local.name_prefix}-sg"
  vpc_id = data.terraform_remote_state.core.outputs.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.core.outputs.vpc_cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.core.outputs.vpc_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.core.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

