variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string

  default = "alocasia-keypair"
}

variable "domain_name" {
  description = "Domain name for the GitLab instance"
  type        = string
  default     = "git.matih.eu"
}

# CloudWatch Alarm Thresholds
variable "cpu_warning_threshold" {
  description = "CPU warning threshold percentage"
  type        = number
  default     = 75
}

variable "cpu_critical_threshold" {
  description = "CPU critical threshold percentage"
  type        = number
  default     = 90
}

variable "cpu_low_threshold" {
  description = "CPU low utilization threshold percentage"
  type        = number
  default     = 2
}

variable "memory_warning_threshold" {
  description = "Memory warning threshold percentage"
  type        = number
  default     = 80
}

variable "memory_critical_threshold" {
  description = "Memory critical threshold percentage"
  type        = number
  default     = 95
}

variable "memory_high_threshold" {
  description = "Memory high utilization threshold percentage"
  type        = number
  default     = 95
}

variable "memory_low_threshold" {
  description = "Memory low utilization threshold percentage"
  type        = number
  default     = 2
}

variable "disk_warning_threshold" {
  description = "Disk warning threshold percentage"
  type        = number
  default     = 85
}

variable "disk_critical_threshold" {
  description = "Disk critical threshold percentage"
  type        = number
  default     = 95
}

variable "disk_low_threshold" {
  description = "Disk low free space threshold percentage"
  type        = number
  default     = 2
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for alarms"
  type        = number
  default     = 3
}

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 600
}

# AWS Backup Variables
variable "backup_retention_days" {
  description = "Number of days to retain daily backups"
  type        = number
  default     = 120 # (90d + cold storage)
}

variable "backup_weekly_retention_days" {
  description = "Number of days to retain weekly backups"
  type        = number
  default     = 180
}

variable "backup_cold_storage_after" {
  description = "Number of days before moving backup to cold storage"
  type        = number
  default     = 30
}

# RDS Variables
variable "rds_backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS cluster"
  type        = bool
  default     = true
}

variable "rds_snapshot_identifier" {
  description = "Identifier for an existing RDS snapshot to restore from (if any)"
  type        = string
  default     = null
}