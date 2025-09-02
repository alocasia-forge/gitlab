###########################
#### COMPOSITE ALARMS #####
###########################
# CPU Composite Alarm
resource "aws_cloudwatch_composite_alarm" "cpu_monitoring" {
  alarm_name        = "${local.name_prefix}-cpu-monitoring"
  alarm_description = "CPU monitoring: Warning(${var.cpu_warning_threshold}%) OR Critical(${var.cpu_critical_threshold}%)"
  alarm_rule        = "ALARM(${aws_cloudwatch_metric_alarm.cpu_warning.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.cpu_critical.alarm_name})"
  actions_enabled   = true
  alarm_actions     = []
}

# Memory Composite Alarm
resource "aws_cloudwatch_composite_alarm" "memory_monitoring" {
  alarm_name        = "${local.name_prefix}-memory-monitoring"
  alarm_description = "Memory monitoring: Warning(${var.memory_warning_threshold}%) OR Critical(${var.memory_critical_threshold}%)"
  alarm_rule        = "ALARM(${aws_cloudwatch_metric_alarm.memory_warning.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.memory_critical.alarm_name})"
  actions_enabled   = true
  alarm_actions     = []
}

# Disk Composite Alarm
resource "aws_cloudwatch_composite_alarm" "disk_monitoring" {
  alarm_name        = "${local.name_prefix}-disk-monitoring"
  alarm_description = "Disk monitoring: Warning(${var.disk_warning_threshold}%) OR Critical(${var.disk_critical_threshold}%)"

  alarm_rule      = "ALARM(${aws_cloudwatch_metric_alarm.disk_warning.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.disk_critical.alarm_name})"
  actions_enabled = true
  alarm_actions   = []
}

############################
#### ALARMS DEFINITION #####
############################
# CPU Utilization Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_warning" {
  alarm_name          = "${local.name_prefix}-cpu-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_warning_threshold
  alarm_description   = "CPU Warning - ${var.cpu_warning_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_critical" {
  alarm_name          = "${local.name_prefix}-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_critical_threshold
  alarm_description   = "CPU Critical - ${var.cpu_critical_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors GitLab instance cpu utilization - LOW"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

# Memory Utilization Alarms
resource "aws_cloudwatch_metric_alarm" "memory_warning" {
  alarm_name          = "${local.name_prefix}-memory-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_warning_threshold
  alarm_description   = "Memory Warning - ${var.memory_warning_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId   = aws_instance.this.id
    InstanceType = aws_instance.this.instance_type
    ImageId      = aws_instance.this.ami
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_critical" {
  alarm_name          = "${local.name_prefix}-memory-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_critical_threshold
  alarm_description   = "Memory Critical - ${var.memory_critical_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId   = aws_instance.this.id
    InstanceType = aws_instance.this.instance_type
    ImageId      = aws_instance.this.ami
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${local.name_prefix}-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_low_threshold
  alarm_description   = "This metric monitors GitLab instance memory utilization - LOW"
  alarm_actions       = []

  dimensions = {
    InstanceId   = aws_instance.this.id
    InstanceType = aws_instance.this.instance_type
    ImageId      = aws_instance.this.ami
  }
}

# Disk Utilization Alarms
resource "aws_cloudwatch_metric_alarm" "disk_warning" {
  alarm_name          = "${local.name_prefix}-disk-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_warning_threshold
  alarm_description   = "Disk Warning - ${var.disk_warning_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId   = aws_instance.this.id
    InstanceType = aws_instance.this.instance_type
    ImageId      = aws_instance.this.ami
    device       = "/dev/xvda1"
    fstype       = "ext4"
    path         = "/"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_critical" {
  alarm_name          = "${local.name_prefix}-disk-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_critical_threshold
  alarm_description   = "Disk Critical - ${var.disk_critical_threshold}%"
  alarm_actions       = []

  dimensions = {
    InstanceId   = aws_instance.this.id
    InstanceType = aws_instance.this.instance_type
    ImageId      = aws_instance.this.ami
    device       = "/dev/xvda1"
    fstype       = "ext4"
    path         = "/"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_low" {
  alarm_name          = "${local.name_prefix}-disk-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "disk_free_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_low_threshold
  alarm_description   = "This metric monitors GitLab instance disk free space - LOW (less than 10% free)"
  alarm_actions       = []

  dimensions = {
    InstanceId   = aws_instance.this.id
    InstanceType = aws_instance.this.instance_type
    ImageId      = aws_instance.this.ami
    device       = "/dev/xvda1"
    fstype       = "ext4"
    path         = "/"
  }
}