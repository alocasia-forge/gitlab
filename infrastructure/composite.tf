# CPU Composite Alarm
resource "aws_cloudwatch_composite_alarm" "cpu_monitoring" {
  alarm_name          = "${local.name_prefix}-cpu-monitoring"
  alarm_description   = "CPU monitoring: Warning(${var.cpu_warning_threshold}%) OR Critical(${var.cpu_critical_threshold}%)"
  alarm_rule          = "ALARM(${aws_cloudwatch_metric_alarm.cpu_warning.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.cpu_critical.alarm_name})"
  actions_enabled     = true
  alarm_actions       = []
}

# Memory Composite Alarm
resource "aws_cloudwatch_composite_alarm" "memory_monitoring" {
  alarm_name          = "${local.name_prefix}-memory-monitoring"
  alarm_description   = "Memory monitoring: Warning(${var.memory_warning_threshold}%) OR Critical(${var.memory_critical_threshold}%)"
  alarm_rule          = "ALARM(${aws_cloudwatch_metric_alarm.memory_warning.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.memory_critical.alarm_name})"
  actions_enabled     = true
  alarm_actions       = []
}

# Disk Composite Alarm
resource "aws_cloudwatch_composite_alarm" "disk_monitoring" {
  alarm_name          = "${local.name_prefix}-disk-monitoring"
  alarm_description   = "Disk monitoring: Warning(${var.disk_warning_threshold}%) OR Critical(${var.disk_critical_threshold}%)"

  alarm_rule          = "ALARM(${aws_cloudwatch_metric_alarm.disk_warning.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.disk_critical.alarm_name})"
  actions_enabled     = true
  alarm_actions       = []
}