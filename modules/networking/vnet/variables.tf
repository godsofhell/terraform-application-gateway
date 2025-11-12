
variable "resource_group_name" {
  type        = string
  description = "The name of the Virtual Network."
}

variable "location" {
  type        = string
  description = "The name of the Virtual Network."
}

variable "network_security_group_rules" {
  type        = list(object(
    {
      priority = number
      destination_port_range = string
    }
  ))
  description = "This variable defines the network security group rules."
}
variable "virtual_network_details"{
  type = list(object(
    {
      virtual_network_name = string
      virtual_network_address_space = string
    }
  ))
}
variable "subnet_details"{
  type = list(object(
    {
      subnet_name = string
      virtual_network_name = string
      subnet_address_prefix = string
    }
  ))
}
variable "network_interface_details"{
  type = list(object(
    {
      network_interface_name = string
      subnet_name = string
    }
  ))
}
