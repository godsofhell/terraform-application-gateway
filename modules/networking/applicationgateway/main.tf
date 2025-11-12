resource "azurerm_public_ip" "gateway_ip" {
  name                = "gateway-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                = "Standard"
  sku_tier = "Regional"
}

resource "azurerm_subnet" "appgatewaysubnet" {
  name                 = var.application_gateway_details[1]
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.application_gateway_details[0]
  address_prefixes     = [var.application_gateway_details[2]]
}
data "azurerm_network_interface" "networkinterface" {
     for_each = {for networkinterface in var.network_interface_details:networkinterface.network_interface_name=>networkinterface}
  name                = each.key
  resource_group_name = var.resource_group_name
}

resource "azurerm_application_gateway" "appgateway" {
  name                = "appgateway"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgatewaysubnet.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.gateway_ip.id
  }

  dynamic backend_address_pool {
    for_each = var.application_pool_details
    
    content {
        name     = "${backend_address_pool.key}-pool"
        ip_addresses = [
            data.azurerm_network_interface.networkinterface[backend_address_pool.value.network_interface_name].private_ip_address
        ]
  }
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "gateway-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "RoutingRuleA"
    priority                   = 100
    rule_type                  = "PathBasedRouting"
    url_path_map_name          = "RoutingPath"
    http_listener_name         = "gateway-listener"
   
  }
  url_path_map {
    name                = "RoutingPath"
    default_backend_address_pool_name = "images-pool"
    default_backend_http_settings_name = "backend-http-settings"

    dynamic path_rule {
      for_each = var.application_pool_details

      content {
        name                       = "${path_rule.key}RoutingPath"
        paths                      = [
            "/${path_rule.key}/*"
            ]
        backend_address_pool_name  = "${path_rule.key}-pool"
        backend_http_settings_name = "backend-http-settings"
      }
    }
  }
}