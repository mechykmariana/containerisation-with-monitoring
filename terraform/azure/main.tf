terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features{}
}

# Resource Group creation
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network and Subnet creation
resource "azurerm_virtual_network" "main" {
  name                = "ci-cd-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "ci-cd-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP and Network Interface
resource "azurerm_public_ip" "main" {
  name                = "ci-cd-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                = "ci-cd-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Security group creation
resource "azurerm_network_security_group" "main" {
  name                = "ci-cd-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "App"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_ranges    = ["3000", "4000", "5173", "9090"]
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine creation
resource "azurerm_linux_virtual_machine" "main" {
  name                = "ci-cd-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.main.id
  ]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${path.module}/id_rsa_azure.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk"
  }

  custom_data = filebase64("${path.module}/user_data.sh")

   # Create app directory first
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.admin_username}/app"
    ]
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_path)
      host        = azurerm_public_ip.main.ip_address
    }
  }

  # Upload docker-compose.yml
  provisioner "file" {
    source      = "${path.module}/../../docker-compose.yml"
    destination = "/home/${var.admin_username}/app/docker-compose.yml"
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_path)
      host        = azurerm_public_ip.main.ip_address
    }
  }

  # Upload alertmanager directory
  provisioner "file" {
    source      = "${path.module}/../../alertmanager"
    destination = "/home/${var.admin_username}/app/alertmanager/"
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_path)
      host        = azurerm_public_ip.main.ip_address
    }
  }

  # Upload prometheus directory
  provisioner "file" {
    source      = "${path.module}/../../prometheus"
    destination = "/home/${var.admin_username}/app/prometheus/"
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_path)
      host        = azurerm_public_ip.main.ip_address
    }
  }

  # Final step: run docker compose up
  provisioner "remote-exec" {
    inline = [
      "timeout=120; while ! command -v docker &> /dev/null && [ $timeout -gt 0 ]; do echo 'Waiting for Docker...'; sleep 5; timeout=$((timeout - 5)); done",
      "sleep 10",
      "sudo systemctl start docker",
      "sudo docker --version", # verify it's available
      "sudo docker stop $(sudo docker ps -aq) || true",
      "sudo docker rm $(sudo docker ps -aq) || true",
      "cd /home/${var.admin_username}/app",
      "sudo docker-compose up -d"
    ]
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_path)
      host        = azurerm_public_ip.main.ip_address
    }
  }
}
