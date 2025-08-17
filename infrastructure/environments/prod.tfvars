environment = "production"
key_name = ""

# CloudWatch configuration
# CPU Thresholds
cpu_warning_threshold = 70    
cpu_critical_threshold = 85   
cpu_low_threshold = 5         

# Memory Thresholds
memory_warning_threshold = 75 
memory_critical_threshold = 90
memory_low_threshold = 5      

# Disk Thresholds
disk_warning_threshold = 80   
disk_critical_threshold = 95  
disk_low_threshold = 5        

alarm_evaluation_periods = 2

# AWS Backup Configuration
backup_retention_days = 90
backup_weekly_retention_days = 365
backup_cold_storage_after = 7     