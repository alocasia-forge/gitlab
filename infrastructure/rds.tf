resource "random_password" "rds" {
  length  = 36
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  engine_version = "16.4"

  db_name  = "gitlab"
  username = "postgres"
  password = random_password.rds.result

  instance_class    = "db.t3.medium"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  publicly_accessible = false
  multi_az            = false

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  backup_retention_period = var.rds_backup_retention_days
  backup_window           = "07:00-09:00"
  maintenance_window      = "sun:09:00-sun:09:30"
  skip_final_snapshot     = var.rds_skip_final_snapshot
  snapshot_identifier     = var.rds_snapshot_identifier
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = data.terraform_remote_state.core.outputs.data_subnets[*].id
}