variable "azure_subscription_id" {
  type = string
}

variable "prefix" {
  default = "novelCovid"
}

variable "location" {
  default = "eastus"
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {}
}

resource "azurerm_resource_group" "myterraformgroup" {
  name     = "host"
  location = var.location

  tags = {
    environment = "main_host"
  }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    environment = "main_host"
  }
}

resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "myterraformpublicip" {
  name                         = "${var.prefix}-publicip"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  allocation_method            = "Static"

  tags = {
    environment = "main_host"
  }
}

resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "${var.prefix}-securitygroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  
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
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DEBUG"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PING"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = {
    environment = "main_host"
  }
}

resource "azurerm_network_interface" "myterraformnic" {
  name                 = "${var.prefix}-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "main_host"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "machine"
  location              = var.location
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk"
    #caching             = "ReadWrite"
    caching              = "ReadOnly"
    storage_account_type = "StandardSSD_LRS"
    #disk_size_gb        = 8
  }

  source_image_reference {
    publisher       = "OpenLogic"
    offer           = "CentOS"
    sku             = "7.7"
    version         = "latest"
  }

  computer_name  = "machine"
  admin_username = "natrys"
  disable_password_authentication = true
  
  admin_ssh_key {
    username       = "natrys"
    public_key     = file("~/.ssh/azure.pub")
  }

  tags = {
    environment = "main_host"
  }
}

resource "azurerm_managed_disk" "mydisk" {
  name                 = "${var.prefix}-datadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 4
  tags                 = {
    environment        = "main_host"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "vmdisk" {
  managed_disk_id = azurerm_managed_disk.mydisk.id
  virtual_machine_id = azurerm_linux_virtual_machine.myterraformvm.id
  lun = 2
  caching = "None"
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
}
