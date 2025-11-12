
//module is used to create a resource group
module "resourcegroup" {
  source              = "./modules/general/resourcegroup"
  resource_group_name = var.resource_group_name
  location            = var.location
}
module "network" {
    source = "./modules/networking/vnet"
    
    resource_group_name = module.resourcegroup.resource_group_name
    location            = module.resourcegroup.resource_group_location
    network_security_group_rules = var.network_security_group_rules
    virtual_network_details =  local.virtual_network_details
    subnet_details = local.subnet_details
    network_interface_details = local.network_interface_details
    //to ensure that resourcegroup is created before vnet
    depends_on = [ module.resourcegroup ]
}
module "VirtualMachines" {
    source = "./modules/Compute/VirtualMachines"
    
    resource_group_name = module.resourcegroup.resource_group_name
    location            = module.resourcegroup.resource_group_location
    virtual_machine_details = local.virtual_machine_details
    network_interface_details = local.network_interface_details
    storage_account_name = module.StorageAccount.storage_account_name
    container_name = "scripts"
    depends_on = [module.network,module.StorageAccount]



}
 module "StorageAccount" {
    source = "./modules/storage/azurestorage"
    resource_group_name = module.resourcegroup.resource_group_name
    location            = module.resourcegroup.resource_group_location
    storage_account_details = var.storage_account_details
    container_names = var.container_names
    blobs = var.blobs
    depends_on = [ module.resourcegroup ]
 }
 module "applicationgateway" {
    source = "./modules/networking/applicationgateway"
    
    resource_group_name = module.resourcegroup.resource_group_name
    location            = module.resourcegroup.resource_group_location
    application_gateway_details = var.application_gateway_details
    network_interface_details = local.network_interface_details
    application_pool_details = var.application_pool_details
    depends_on = [ module.VirtualMachines ]
 }
 