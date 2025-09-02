# IAM Role for SSM access
resource "aws_iam_role" "ssm" {
  name = "${local.name_prefix}-gitlab-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for the EC2 instance
resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}-profile"
  role = aws_iam_role.ssm.name
}

# Maintenance Window for GitLab
resource "aws_ssm_maintenance_window" "this" {
  name        = "${local.name_prefix}-maintenance"
  description = "Maintenance window for GitLab instance"

  # Sunday 02:00-04:00 UTC
  schedule                   = "cron(0 2 ? * SUN *)"
  duration                   = 2
  cutoff                     = 1
  allow_unassociated_targets = false
  enabled                    = true

  tags = {
    Name = "${local.name_prefix}-maintenance-window"
  }
}

# Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "this" {
  window_id     = aws_ssm_maintenance_window.this.id
  name          = "${local.name_prefix}-gitlab-target"
  description   = "GitLab instance target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.this.id]
  }
}

resource "aws_ssm_patch_baseline" "this" {
  name             = "${local.name_prefix}-gitlab-patch-baseline"
  description      = "Patch baseline for GitLab instance"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    approve_after_days  = 7
    compliance_level    = "CRITICAL"
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix", "Recommended"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }
}

# Maintenance Window Task for patching
resource "aws_ssm_maintenance_window_task" "this" {
  window_id        = aws_ssm_maintenance_window.this.id
  name             = "${local.name_prefix}-gitlab-patch-task"
  description      = "Patch GitLab instance"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.maintenance_window.arn
  max_concurrency  = "1"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.this.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

# IAM role for maintenance window tasks
resource "aws_iam_role" "maintenance_window" {
  name = "${local.name_prefix}-maintenance-window-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maintenance_window" {
  role       = aws_iam_role.maintenance_window.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}