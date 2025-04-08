variable "resource_group_name" {
  default = "ci-cd-hybrid-rg"
}

variable "location" {
  default = "North Europe"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to your public SSH key"
  type        = string
  #default     = "key_path"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "private_key_path" {
  description = "Path to the SSH private key used by provisioners"
  type        = string
  #default     = "key_path"
}
