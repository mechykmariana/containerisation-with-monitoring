variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "thesis-key"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "private_key_path" {
  description = "Path to SSH private key for EC2 provisioners"
  type        = string
  default     = "key_path"
}
