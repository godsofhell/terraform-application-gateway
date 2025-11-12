variable "resource_group_name" {
    type = string 
    description = "contains the name of resource group "
}
variable "location" {
    type = string 
    description = "contains the location of resource group "
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

variable "environment" {
   type=map(object(
   {
      virtual_network_address_space=string      
      subnets=map(object( 
        {       
          subnet_address_prefix=string         
          network_interfaces=list(object(
          {
              name=string
              virtual_machine_name=string
              script_name=string
          }   ))       
        }
          ))           
        }
      ))             
}
variable "storage_account_details"{
    type = map(string)
}
variable "container_names"{
    type = list(string)
}
variable "blobs"{
    type = map(object(
        {
        container_name = string
        blob_location = string
        }
    ))
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



/*variable "network_interface_private_ip_address" {
    type = list(string)
    description = "this is the private IP Addresses of the network interface attached"
}
variable "virtual_network_id" {
  type = string
  description = "Virtual network id of the VMs"
}*/