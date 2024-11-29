
terraform {
  source = "./instance"
  
}

include {
  path = find_in_parent_folders()
}