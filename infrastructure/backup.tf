# AWS Backup Vault
resource "aws_backup_vault" "this" {
  name        = "${local.name_prefix}-gitlab-vault"
  kms_key_arn = aws_kms_key.this.arn

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-gitlab-backup-vault"
  })
}

# KMS Key for backup encryption
resource "aws_kms_key" "this" {
  description             = "KMS key for GitLab backup encryption"
  deletion_window_in_days = 7

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-backup-kms-key"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name_prefix}-backup"
  target_key_id = aws_kms_key.this.key_id
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Plan
resource "aws_backup_plan" "this" {
  name = "${local.name_prefix}-backup-plan"

  # Daily backup
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 3 ? * * *)" # 0300UTC

    start_window      = 480
    completion_window = 600

    recovery_point_tags = {
      BackupType = "daily"
    }

    lifecycle {
      cold_storage_after = var.backup_cold_storage_after
      delete_after       = var.backup_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.this.arn

      lifecycle {
        cold_storage_after = var.backup_cold_storage_after
        delete_after       = var.backup_retention_days
      }
    }
  }

  # Weekly backup (longer retention)
  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 4 ? * SUN *)" # Sunday 0400UTC

    start_window      = 480
    completion_window = 600

    recovery_point_tags = {
      BackupType = "weekly"
    }

    lifecycle {
      cold_storage_after = var.backup_cold_storage_after
      delete_after       = var.backup_weekly_retention_days
    }
  }

  tags = {
    Name = "${local.name_prefix}-backup-plan"
  }
}

# Backup Selection
resource "aws_backup_selection" "this" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${local.name_prefix}-selection"
  plan_id      = aws_backup_plan.this.id

  resources = [
    aws_instance.this.arn
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/alocasia:services"
      value = "gitlab-core"
    }
  }
}

# SNS Topic for backup notifications
resource "aws_sns_topic" "this" {
  name = "${local.name_prefix}-backup-notifications"

  tags = {
    Name = "${local.name_prefix}-backup-notifications"
  }
}

# Backup Vault Notifications
resource "aws_backup_vault_notifications" "this" {
  backup_vault_name = aws_backup_vault.this.name
  sns_topic_arn     = aws_sns_topic.this.arn

  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]
}