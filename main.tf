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
  name                        = "SSH"
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

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.hostName
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [
  azurerm_network_interface.nic.id]
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

  provisioner "file" {
    connection {
      host        = azurerm_public_ip.publicip.ip_address
      type        = "ssh"
      user        = var.user
      private_key = file("~/mykeys/id_rsa")
    }
    source      = "./scripts"
    destination = "~/scripts"
  }

  provisioner "remote-exec" {
    connection {
      host        = azurerm_public_ip.publicip.ip_address
      type        = "ssh"
      user        = var.user
      private_key = file("~/mykeys/id_rsa")
    }

    inline = [
      "ls -latrh",
      "ls -latrh ~/scripts",
    ]
  }
}

# Data template Bash bootstrapping file
data "template_file" "linux-vm-cloud-init" {
  template = file("./scripts/bash/azure-user-data.sh")
}