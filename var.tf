variable "VM_Publisher_ubuntu" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Canonical"
}

variable "VM_offer_ubuntu" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "VM_sku_ubuntu" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "server"
}

variable "VM_version_ubuntu" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "latest"
}