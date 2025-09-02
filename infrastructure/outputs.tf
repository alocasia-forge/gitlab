output "gitlab" {
  value = {
    connect = "aws ssm start-session --target ${aws_instance.this.id} --profile alocasia"
  }
}