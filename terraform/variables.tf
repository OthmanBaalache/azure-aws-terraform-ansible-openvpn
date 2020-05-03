# Set variables
variable "user" {
  type        = string
  description = "Root user name for virtual machine"
}

variable "ip" {}

variable "dnsLabel" {
  type        = string
  description = "DNS name label"
}

variable "hostName" {
  type        = string
  description = "Hostname of VM"
}
variable "ovpnRG" {
  type        = string
  description = "Resource Group for Solution"
}

variable "location" {}

variable "homePip" {}

variable "tags" {
  type = map(string)

  default = {
    Environment = "production"
    Dept        = "Engineering"
  }
}

variable "sku" {
  default = {
    uksouth = "19.04"
  }
}

