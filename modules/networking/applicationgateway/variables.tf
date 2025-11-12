variable "resource_group_name" {
  description = "The name of the resource group in which to create the Application Gateway."
  type        = string
}
variable "location" {
  description = "The Azure region where the Application Gateway will be created."
  type        = string
}
variable "application_gateway_details"{
  type = list(string)
}
variable "application_pool_details"{
  type = map(object(
    {
      network_interface_name = string
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

