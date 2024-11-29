resource "aws_db_instance" "default" {
  allocated_storage = var.instance.allocated_storage
  engine = var.instance.engine
  instance_class = var.instance.instance_class
  username = var.instance.username
  password = var.instance.password
  skip_final_snapshot = var.instance.skip_final_snapshot
  tags = var.app_settings.tags
}