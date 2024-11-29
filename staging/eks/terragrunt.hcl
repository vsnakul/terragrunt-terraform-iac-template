
terraform {
    source = "git::your_remote_terraform_module?ref=v<release_version>"
}

include {
  path = find_in_parent_folders()
}