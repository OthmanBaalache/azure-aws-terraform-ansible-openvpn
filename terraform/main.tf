# Configure the Azure provider
terraform {
  required_version = ">=0.12"
}

provider "azurerm" {
  version = "~>2.0"
  features {}
}

# Create a new resource group
resource "azurerm_resource_group" "rg" {
  name     = var.ovpnRG
  location = var.location

  tags = {
    Environment = "production"
    Deployment  = "IaC"
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-uks-production"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}


# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subn-uks-ovpn"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/29"]
}

resource random_id "dns_suffix" {
  byte_length = 3
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "pip-uks-ovpn"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = format("%s-%s", var.dnsLabel, random_id.dns_suffix.dec)
}

# Create Network Security Group rule
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-uks-ovpn"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create Network Security Rule
resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.homePip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create Network Security Rule
resource "azurerm_network_security_rule" "vpn" {
  name                        = "VPN"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1194"
  source_address_prefix       = var.homePip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "nic-uks-ovpn"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "staticConfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = var.ip
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

#Create an NSG association with the NIC
resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.hostName
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.nic.id]
  size                            = "Standard_B1ls"
  admin_username                  = var.user
  computer_name                   = var.hostName
  disable_password_authentication = true
  custom_data                     = base64encode(data.template_file.linux-vm-cloud-init.rendered)

  admin_ssh_key {
    username   = var.user
    public_key = file("~/mykeys/id_rsa.pub")
  }

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = var.sku.uksouth
    version   = "latest"
  }
}

#Downloads and runs scripts on Azure virtual machines. This extension is useful for post-deployment tasks.
#The extension will only run a script once, if you want to run a script on every boot, use cloud-init (next)
#resource "azurerm_virtual_machine_extension" "vmExt" {
#  name                 = "test"
#  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
#  publisher            = "Microsoft.Azure.Extensions"
#  type                 = "CustomScript"
#  type_handler_version = "2.0"
#  protected_settings = <<PROT
#    {
#      "script": "${base64encode(file(var.custom-extScript))}"
#    }
#PROT
#}

#Here we will bootstrap the VM using the native cloud-init as it boots for the first time.
#Use cloud-config.yaml to install packages and write files, or to configure users and security.
#https://docs.microsoft.com/en-gb/azure/virtual-machines/linux/using-cloud-init
data "template_file" "linux-vm-cloud-init" {
  template = file(var.cloud-initScript)
}