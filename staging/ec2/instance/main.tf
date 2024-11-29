
resource "aws_instance" "example" {
  ami                    = var.instance.ami_id
  instance_type          = var.instance.instance_type              
  subnet_id              = var.instance.subnet_id        
  key_name               = var.instance.key_name
  iam_instance_profile   = var.instance.iam_instance_profile
  security_groups        = var.instance.security_groups
  tags = var.app_settings.tags
}
