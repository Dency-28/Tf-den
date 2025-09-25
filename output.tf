output "ec2_public_ip" {
  value = aws_instance.demo.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mydb.endpoint
}