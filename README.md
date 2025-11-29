# Azure Application Gateway with Terraform

A complete Terraform infrastructure-as-code solution for deploying an Azure Application Gateway with path-based routing to multiple backend virtual machines running nginx web servers.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Modules Reference](#modules-reference)
- [Security Considerations](#security-considerations)
- [Monitoring](#monitoring)
- [Cleanup](#cleanup)
- [Contributing](#contributing)

## 📋 Overview

This Terraform project provisions a complete web application infrastructure in Azure with:

- **Virtual Network** with isolated subnets for workloads and Application Gateway
- **Linux Virtual Machines** running Ubuntu with automated nginx deployment
- **Network Security Groups** with configurable inbound rules
- **Azure Storage Account** for hosting deployment scripts
- **Application Gateway** with path-based routing and backend health probes
- **VM Extensions** for automated web server configuration

### Key Features

✅ **Path-Based Routing** - Route traffic based on URL paths (`/images/*`, `/videos/*`)  
✅ **Automated Deployment** - VMs self-configure using CustomScript extensions  
✅ **Modular Design** - Reusable Terraform modules for each component  
✅ **Security** - NSG rules and private subnets for backend VMs  
✅ **Scalability** - Application Gateway with autoscaling capabilities  
✅ **High Availability** - Multi-instance VM deployment supported

## 🏗️ Architecture

```
                              Internet
                                 ↓
                    ┌────────────────────────┐
                    │  Application Gateway   │
                    │   (Public IP: Static)  │
                    │   Standard_v2 SKU      │
                    └────────────────────────┘
                                 ↓
                    ┌────────────────────────┐
                    │  Path-Based Routing    │
                    ├────────────────────────┤
                    │  /images/* → Pool A    │
                    │  /videos/* → Pool B    │
                    └────────────────────────┘
                         ↙              ↘
            ┌──────────────────┐   ┌──────────────────┐
            │   imagesvm01     │   │   videosvm01     │
            │  10.0.0.0/24     │   │  10.0.1.0/24     │
            │  Ubuntu + Nginx  │   │  Ubuntu + Nginx  │
            └──────────────────┘   └──────────────────┘
```

### Network Topology

```
app01-network (VNet: 10.0.0.0/16)
├── imagessubnet (10.0.0.0/24)
│   └── imagesvm01
│       └── images-interface-01 (Private IP: Dynamic)
├── videossubnet (10.0.1.0/24)
│   └── videosvm01
│       └── videos-interface-01 (Private IP: Dynamic)
└── app-gatewaysubnet (10.0.10.0/24)
    └── Application Gateway
        └── gateway-ip (Public IP: Static)
```

## 📁 Project Structure

```
application Gateway/
├── main.tf                                  # Root module - orchestrates all modules
├── variables.tf                             # Variable declarations
├── terraform.tfvars                         # Variable values (configuration)
├── locals.tf                                # Local value transformations
├── outputs.tf                               # Output values
├── README.md                                # This file
│
├── modules/
│   ├── general/
│   │   └── resourcegroup/                   # Resource group module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── networking/
│   │   ├── vnet/                            # VNet, subnets, NSGs, NICs
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   └── applicationgateway/              # Application Gateway
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── Compute/
│   │   └── VirtualMachines/                 # VMs and extensions
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── install_web_images.sh        # Images server setup script
│   │       └── install_web_videos.sh        # Videos server setup script
│   │
│   └── storage/
│       └── azurestorage/                    # Storage account and blobs
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
└── imports.tf                               # (Optional) Import existing resources
```

## 🚀 Prerequisites

### Required Tools

- **Terraform** >= 1.0 - [Download](https://www.terraform.io/downloads)
- **Azure CLI** >= 2.0 - [Download](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **PowerShell** (Windows) or **Bash** (Linux/macOS)

### Azure Requirements

- Active Azure subscription
- Permissions to create resources in a resource group
- Subscription ID ready for authentication

### Verify Installation

```powershell
# Check Terraform
terraform version

# Check Azure CLI
az version

# Login to Azure
az login
az account show
```

## ⚡ Quick Start

```powershell
# 1. Clone or navigate to the project
cd "C:\Terraform\application Gateway"

# 2. Authenticate to Azure
az login
az account set --subscription "your-subscription-id"

# 3. Initialize Terraform
terraform init

# 4. Review and customize terraform.tfvars
# (Edit resource names, IP ranges, VM credentials, etc.)

# 5. Preview changes
terraform plan

# 6. Deploy infrastructure
terraform apply

# 7. Get Application Gateway public IP
$gatewayIp = az network public-ip show -g app-grp -n gateway-ip --query ipAddress -o tsv

# 8. Test the deployment
curl http://$gatewayIp/images/
curl http://$gatewayIp/videos/
```

## 🔧 Configuration

### Main Configuration File: `terraform.tfvars`

```hcl
# Resource Group
resource_group_name = "app-grp"
location            = "UK South"

# Network Security Rules
network_security_group_rules = [
  {
    priority               = 300
    destination_port_range = "22"  # SSH
  },
  {
    priority               = 310
    destination_port_range = "80"  # HTTP
  }
]

# Virtual Network and Subnets
environment = {
  "app01-network" = {
    virtual_network_address_space = "10.0.0.0/16"
    subnets = {
      images = {
        subnet_address_prefix = "10.0.0.0/24"
        network_interfaces = [
          {
            name                 = "images-interface-01"
            virtual_machine_name = "imagesvm01"
            script_name          = "install_web_images.sh"
          }
        ]
      }
      videos = {
        subnet_address_prefix = "10.0.1.0/24"
        network_interfaces = [
          {
            name                 = "videos-interface-01"
            virtual_machine_name = "videosvm01"
            script_name          = "install_web_videos.sh"
          }
        ]
      }
    }
  }
}

# Application Gateway Configuration
application_gateway_details = [
  "app01-network",      # VNet name
  "app-gatewaysubnet",  # Subnet name
  "10.0.10.0/24"        # Subnet CIDR
]

# Backend Pools
application_pool_details = {
  "images" = {
    network_interface_name = "images-interface-01"
  }
  "videos" = {
    network_interface_name = "videos-interface-01"
  }
}

# Storage Account
storage_account_details = {
  account_prefix          = "appstore"
  account_tier            = "Standard"
  account_replication_key = "LRS"
  account_kind            = "StorageV2"
}

# Blob Storage
container_names = ["scripts", "data"]

blobs = {
  "install_web_images.sh" = {
    container_name = "scripts"
    blob_location  = "./modules/Compute/VirtualMachines/install_web_images.sh"
  }
  "install_web_videos.sh" = {
    container_name = "scripts"
    blob_location  = "./modules/Compute/VirtualMachines/install_web_videos.sh"
  }
}
```

### Virtual Machine Credentials

Default credentials (change in production):
- **Username**: `adminuser`
- **Password**: `Azure@1234`

**⚠️ Security Warning**: Change these credentials before deploying to production!

## 📦 Deployment

### Standard Deployment

```powershell
# Navigate to project directory
cd "C:\Terraform\application Gateway"

# Initialize Terraform (download providers)
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Preview changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Deployment with Auto-Approve

```powershell
terraform apply -auto-approve
```

### Targeted Deployment

```powershell
# Deploy only networking resources
terraform apply -target=module.network

# Deploy only VMs
terraform apply -target=module.VirtualMachines

# Deploy only Application Gateway
terraform apply -target=module.applicationgateway
```

## 🔄 Importing Existing Resources

If you have existing Azure resources that need to be managed by Terraform:

### Method 1: PowerShell Import Commands

```powershell
# Import Virtual Network
terraform import "module.network.azurerm_virtual_network.virtual_network[\"app01-network\"]" "/subscriptions/2ab4f266-3113-46c7-9a11-16bcb8ae5659/resourceGroups/app-grp/providers/Microsoft.Network/virtualNetworks/app01-network"

# Import VM Extension
terraform import "module.VirtualMachines.azurerm_virtual_machine_extension.vmextension[\"imagesvm01\"]" "/subscriptions/2ab4f266-3113-46c7-9a11-16bcb8ae5659/resourceGroups/app-grp/providers/Microsoft.Compute/virtualMachines/imagesvm01/extensions/vmextension"
```

### Method 2: Declarative Import (Terraform 1.5+)

Create `imports.tf`:

```hcl
import {
  to = module.network.azurerm_virtual_network.virtual_network["app01-network"]
  id = "/subscriptions/2ab4f266-3113-46c7-9a11-16bcb8ae5659/resourceGroups/app-grp/providers/Microsoft.Network/virtualNetworks/app01-network"
}

import {
  to = module.VirtualMachines.azurerm_virtual_machine_extension.vmextension["imagesvm01"]
  id = "/subscriptions/2ab4f266-3113-46c7-9a11-16bcb8ae5659/resourceGroups/app-grp/providers/Microsoft.Compute/virtualMachines/imagesvm01/extensions/vmextension"
}
```

Then run:
```powershell
terraform plan
terraform apply
```

After import succeeds, delete `imports.tf`.

## 🧪 Testing

### Get Application Gateway Public IP

```powershell
# PowerShell
$gatewayIp = az network public-ip show `
  -g app-grp `
  -n gateway-ip `
  --query ipAddress `
  -o tsv

Write-Host "Application Gateway IP: $gatewayIp"
```

```bash
# Bash
gatewayIp=$(az network public-ip show \
  -g app-grp \
  -n gateway-ip \
  --query ipAddress \
  -o tsv)

echo "Application Gateway IP: $gatewayIp"
```

### Test Path-Based Routing

```powershell
# Test images backend
curl http://$gatewayIp/images/

# Test videos backend
curl http://$gatewayIp/videos/
```

### Expected Responses

**Images Endpoint** (`/images/`):
```html
<h1>This is the images server imagesvm01</h1>
```

**Videos Endpoint** (`/videos/`):
```html
<h1>This is the videos server videosvm01</h1>
```

### Check Backend Health

```powershell
az network application-gateway show-backend-health `
  -g app-grp `
  -n appgateway `
  --query "backendAddressPools[].backendHttpSettingsCollection[].servers[]" `
  -o table
```

Expected output:
```
Address        HealthState    Health
-------------  -------------  --------
10.0.0.x       Healthy        Healthy
10.0.1.x       Healthy        Healthy
```

### Direct VM Testing

```powershell
# Get VM public IPs (if assigned)
az vm list-ip-addresses -g app-grp -o table

# SSH into VM
ssh adminuser@<vm-public-ip>
# Password: Azure@1234

# Test locally on VM
curl http://localhost/images/
curl http://localhost/videos/
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. 502 Bad Gateway Error

**Symptom**: Application Gateway returns 502 when accessing `/images/` or `/videos/`

**Cause**: Backend VM is unhealthy - nginx not running or content missing

**Solution**:

```powershell
# Check backend health
az network application-gateway show-backend-health `
  -g app-grp -n appgateway `
  --query "backendAddressPools[].backendHttpSettingsCollection[].servers[]" `
  -o table

# SSH into affected VM
ssh adminuser@<vm-ip>

# Check nginx status
sudo systemctl status nginx

# Restart nginx
sudo systemctl restart nginx

# Verify content exists
ls -la /var/www/html/images/
ls -la /var/www/html/videos/

# Test locally
curl http://localhost/images/
curl http://localhost/videos/
```

#### 2. VM Extension Failed

**Symptom**: Extension provisioning state is "Failed"

**Cause**: Script execution failed (permissions, apt lock, syntax errors)

**Solution**:

```powershell
# View extension status
az vm extension list -g app-grp --vm-name imagesvm01 -o table

# Delete failed extension
az vm extension delete -g app-grp --vm-name imagesvm01 -n vmextension

# Fix the script in modules/Compute/VirtualMachines/install_web_images.sh

# Reapply
terraform apply -auto-approve

# Check logs on VM
ssh adminuser@<vm-ip>
sudo cat /var/log/azure/custom-script/handler.log
sudo journalctl -u custom-script-extension -n 50
```

#### 3. Import Command Fails with "Index value required"

**Symptom**: `Error: Index value required` when running import

**Cause**: Shell stripping quotes from Terraform address

**Solution for PowerShell**:

```powershell
# Use escaped quotes
terraform import "module.VirtualMachines.azurerm_virtual_machine_extension.vmextension[\"imagesvm01\"]" "/subscriptions/.../vmextension"
```

**Alternative**: Use declarative imports (see [Importing Existing Resources](#importing-existing-resources))

#### 4. Connection Refused on Port 80

**Symptom**: `curl: (7) Failed to connect to localhost port 80`

**Cause**: Nginx not installed or not running

**Solution**:

```bash
# SSH into VM
ssh adminuser@<vm-ip>

# Install nginx manually
sudo apt-get update
sudo apt-get install -y nginx

# Start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Verify
sudo systemctl status nginx
sudo netstat -tlnp | grep :80
```

#### 5. NSG Blocking Traffic

**Symptom**: Cannot access VMs even with correct nginx configuration

**Cause**: NSG rules too restrictive

**Solution**:

```powershell
# List NSG rules
az network nsg rule list -g app-grp --nsg-name imagesnetwork-nsg -o table

# Verify port 80 is allowed
az network nsg rule show `
  -g app-grp `
  --nsg-name imagesnetwork-nsg `
  -n Allow-80
```

#### 6. Terraform State Issues

**Symptom**: Resource already exists errors

**Cause**: Resources created outside Terraform or state file out of sync

**Solution**:

```powershell
# View current state
terraform state list

# Remove resource from state (if needed)
terraform state rm "module.VirtualMachines.azurerm_virtual_machine_extension.vmextension[\"imagesvm01\"]"

# Reimport or recreate
terraform import "..." "..."
# OR
terraform apply
```

### Debug Mode

Enable detailed logging:

```powershell
# Windows PowerShell
$env:TF_LOG="DEBUG"
terraform apply

# Linux/Mac
export TF_LOG=DEBUG
terraform apply
```

## 📚 Modules Reference

### Resource Group Module

**Path**: `modules/general/resourcegroup`

**Purpose**: Creates the Azure resource group

**Inputs**:
- `resource_group_name` - Name of the resource group
- `location` - Azure region

**Outputs**:
- `resource_group_name` - Created resource group name
- `resource_group_location` - Resource group location

---

### Network Module

**Path**: `modules/networking/vnet`

**Purpose**: Manages VNet, subnets, NSGs, and network interfaces

**Resources Created**:
- Virtual Network
- Subnets (dynamic based on configuration)
- Network Security Groups (one per subnet)
- Network Interfaces
- NSG-Subnet associations

**Key Features**:
- Dynamic subnet creation using `for_each`
- Dynamic NSG rules
- Automatic NSG association to subnets

**Inputs**:
- `virtual_network_details` - VNet configuration
- `subnet_details` - Subnet configurations
- `network_interface_details` - NIC configurations
- `network_security_group_rules` - NSG rule list

**Outputs**:
- Network interface IDs
- Subnet IDs
- Virtual network details

---

### Virtual Machines Module

**Path**: `modules/Compute/VirtualMachines`

**Purpose**: Creates Linux VMs with automated nginx deployment

**Resources Created**:
- Linux Virtual Machines (Ubuntu)
- VM Extensions (CustomScript for nginx installation)

**Key Features**:
- Dynamic VM creation using `for_each`
- Automated script execution via CustomScript extension
- Password authentication (can be changed to SSH keys)
- Lifecycle rule to ignore identity changes

**Inputs**:
- `virtual_machine_details` - VM configurations
- `network_interface_details` - Associated NICs
- `storage_account_name` - Storage account for scripts
- `container_name` - Blob container name

**Outputs**:
- VM IDs
- VM names

**Important Notes**:
- Default VM size: `Standard_B1s`
- Default credentials: `adminuser` / `Azure@1234`
- Scripts must include `sudo` for all privileged operations
- Extension waits for apt lock before installing packages

---

### Application Gateway Module

**Path**: `modules/networking/applicationgateway`

**Purpose**: Creates Application Gateway with path-based routing

**Resources Created**:
- Public IP (Static)
- Application Gateway Subnet
- Application Gateway (Standard_v2)

**Key Features**:
- Path-based routing (`/images/*`, `/videos/*`)
- Dynamic backend pool creation
- Health probes
- Auto-scaling capable (capacity: 2)

**Routing Configuration**:
- `/images/*` → images-pool
- `/videos/*` → videos-pool

**Inputs**:
- `application_gateway_details` - [VNet name, subnet name, subnet CIDR]
- `application_pool_details` - Backend pool configurations
- `network_interface_details` - Backend NIC details

**Outputs**:
- Application Gateway ID
- Public IP address

---

### Storage Module

**Path**: `modules/storage/azurestorage`

**Purpose**: Creates storage account and uploads deployment scripts

**Resources Created**:
- Storage Account
- Blob Containers
- Blobs (uploaded scripts)

**Key Features**:
- Random suffix for unique storage account name
- Public blob access for VM extensions
- Supports multiple containers and blobs

**Inputs**:
- `storage_account_details` - Account configuration
- `container_names` - List of container names
- `blobs` - Map of blob configurations

**Outputs**:
- Storage account name
- Primary connection string

## 🔐 Security Considerations

### Current Configuration (Development)

⚠️ **Not suitable for production** - Implements basic security for testing:

- Public inbound access from any IP (`*`)
- Password authentication enabled
- Default credentials hardcoded
- HTTP only (no HTTPS)

### Production Security Checklist

#### 1. Network Security Groups

**Current**:
```hcl
source_address_prefix = "*"  # ❌ Allows all IPs
```

**Recommended**:
```hcl
source_address_prefix = "your-ip/32"  # ✅ Specific IP or range
# OR
source_address_prefix = "10.0.10.0/24"  # ✅ Application Gateway subnet only
```

#### 2. VM Authentication

**Current**:
```hcl
admin_password = "Azure@1234"
disable_password_authentication = false
```

**Recommended**:
```hcl
disable_password_authentication = true
admin_ssh_key {
  username   = "adminuser"
  public_key = file("~/.ssh/id_rsa.pub")
}
```

#### 3. Storage Account Security

**Add to storage module**:
```hcl
network_rules {
  default_action             = "Deny"
  ip_rules                   = ["your-ip"]
  virtual_network_subnet_ids = [azurerm_subnet.appgatewaysubnet.id]
}
```

#### 4. HTTPS Configuration

**Add SSL certificate to Application Gateway**:
```hcl
ssl_certificate {
  name     = "ssl-cert"
  data     = filebase64("path/to/cert.pfx")
  password = var.cert_password
}

frontend_port {
  name = "https-port"
  port = 443
}

http_listener {
  name                           = "https-listener"
  frontend_ip_configuration_name = "frontend-ip"
  frontend_port_name             = "https-port"
  protocol                       = "Https"
  ssl_certificate_name           = "ssl-cert"
}
```

#### 5. Secrets Management

Use Azure Key Vault for sensitive data:

```hcl
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = var.key_vault_id
}

resource "azurerm_linux_virtual_machine" "virtualmachines" {
  admin_password = data.azurerm_key_vault_secret.vm_password.value
  # ...
}
```

#### 6. Enable Diagnostic Logging

```hcl
resource "azurerm_monitor_diagnostic_setting" "appgateway_diag" {
  name                       = "appgateway-diagnostics"
  target_resource_id         = azurerm_application_gateway.appgateway.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
  
  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }
  
  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}
```

## 📊 Monitoring

### View Application Gateway Metrics

```powershell
# List available metrics
az monitor metrics list-definitions `
  --resource "/subscriptions/{subscription-id}/resourceGroups/app-grp/providers/Microsoft.Network/applicationGateways/appgateway"

# Get specific metrics
az monitor metrics list `
  --resource "/subscriptions/{subscription-id}/resourceGroups/app-grp/providers/Microsoft.Network/applicationGateways/appgateway" `
  --metric "Throughput" "ResponseStatus" "HealthyHostCount" "UnhealthyHostCount" `
  --start-time 2025-11-29T00:00:00Z `
  --end-time 2025-11-29T23:59:59Z
```

### Key Metrics to Monitor

| Metric | Description | Healthy Range |
|--------|-------------|---------------|
| `HealthyHostCount` | Number of healthy backend hosts | > 0 |
| `UnhealthyHostCount` | Number of unhealthy backend hosts | 0 |
| `ResponseStatus` | HTTP status codes returned | Mostly 2xx |
| `Throughput` | Data processed by gateway | Based on workload |
| `FailedRequests` | Number of failed requests | Low (<1%) |
| `BackendResponseStatus` | Backend HTTP responses | Mostly 2xx |

### Enable Azure Monitor Alerts

```powershell
# Create alert for unhealthy backends
az monitor metrics alert create `
  --name "appgateway-unhealthy-backend" `
  --resource-group app-grp `
  --scopes "/subscriptions/{subscription-id}/resourceGroups/app-grp/providers/Microsoft.Network/applicationGateways/appgateway" `
  --condition "avg UnhealthyHostCount > 0" `
  --description "Alert when any backend becomes unhealthy" `
  --evaluation-frequency 1m `
  --window-size 5m `
  --severity 2
```

### View Logs

```powershell
# View Activity Log
az monitor activity-log list `
  --resource-group app-grp `
  --start-time 2025-11-29T00:00:00Z `
  --query "[].{Time:eventTimestamp, Operation:operationName.value, Status:status.value}"

# Query Log Analytics (if configured)
az monitor log-analytics query `
  --workspace "{workspace-id}" `
  --analytics-query "AzureDiagnostics | where ResourceType == 'APPLICATIONGATEWAYS' | take 100"
```

## 🧹 Cleanup

### Destroy All Resources

```powershell
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm when prompted
# Type 'yes' to proceed
```

### Destroy Specific Resources

```powershell
# Remove only Application Gateway
terraform destroy -target=module.applicationgateway

# Remove only VMs
terraform destroy -target=module.VirtualMachines

# Remove only storage
terraform destroy -target=module.StorageAccount
```

### Manual Cleanup (if Terraform fails)

```powershell
# Delete resource group (removes all contained resources)
az group delete --name app-grp --yes --no-wait

# Verify deletion
az group list --query "[?name=='app-grp']"
```

### Clean Terraform State

```powershell
# Remove local state files (only after destroying resources)
Remove-Item .terraform -Recurse -Force
Remove-Item terraform.tfstate
Remove-Item terraform.tfstate.backup
Remove-Item .terraform.lock.hcl
```

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Format code**:
   ```bash
   terraform fmt -recursive
   ```
5. **Validate**:
   ```bash
   terraform validate
   ```
6. **Commit changes**:
   ```bash
   git commit -am "Add feature: description"
   ```
7. **Push to branch**:
   ```bash
   git push origin feature/your-feature-name
   ```
8. **Submit a pull request**

### Code Standards

- Use descriptive resource names
- Add comments for complex logic
- Follow Terraform best practices
- Update README for new features
- Test changes in a dev environment
- Ensure `terraform fmt` and `terraform validate` pass

### Testing Checklist

Before submitting:

- [ ] Code is formatted (`terraform fmt`)
- [ ] Code is validated (`terraform validate`)
- [ ] Deployment succeeds in clean environment
- [ ] All modules work independently
- [ ] Application Gateway routes correctly
- [ ] Backend health checks pass
- [ ] Documentation is updated

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Additional Resources

### Terraform Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Terraform Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)

### Azure Documentation
- [Azure Application Gateway](https://learn.microsoft.com/azure/application-gateway/)
- [Azure Virtual Network](https://learn.microsoft.com/azure/virtual-network/)
- [Azure VM Extensions](https://learn.microsoft.com/azure/virtual-machines/extensions/overview)
- [Azure Network Security Groups](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)

### Learning Resources
- [HashiCorp Learn - Terraform](https://learn.hashicorp.com/terraform)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)
- [Terraform Azure Examples](https://github.com/hashicorp/terraform-provider-azurerm/tree/main/examples)

---

## 📞 Support

For issues and questions:

1. **Check [Troubleshooting](#troubleshooting)** section first
2. **Review [Azure Documentation](https://learn.microsoft.com/azure/)**
3. **Search existing GitHub issues**
4. **Create a new issue** with:
   - Terraform version
   - Azure CLI version
   - Error messages
   - Steps to reproduce

---

**Project**: Azure Application Gateway with Terraform  
**Author**: Viplav  
**Last Updated**: November 29, 2025  
**Terraform Version**: >= 1.0  
**Azure Provider Version**: >= 3.0  
**Infrastructure Type**: IaC (Infrastructure as Code)

---

## 🎯 Future Enhancements

Planned improvements:

- [ ] Add WAF (Web Application Firewall) configuration
- [ ] Implement HTTPS with Let's Encrypt integration
- [ ] Add Azure Key Vault for secrets management
- [ ] Implement VM scale sets for auto-scaling
- [ ] Add Azure Monitor dashboards
- [ ] Implement Azure DevOps pipeline
- [ ] Add custom health probes
- [ ] Implement geo-redundancy
- [ ] Add backup and disaster recovery
- [ ] Implement cost optimization recommendations

Contributions for these features are welcome!
