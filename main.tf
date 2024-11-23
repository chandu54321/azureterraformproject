resource "azurerm_resource_group" "resource" {
  name     = var.azure_resource.name
  location = var.azure_resource.location
}
resource "azurerm_virtual_network" "vnet" {
  name                = var.azure_vnet.name
  address_space       = var.azure_vnet.address_space
  resource_group_name = azurerm_resource_group.resource.name
  location            = var.azure_vnet.location
}

resource "azurerm_subnet" "subnets" {
  count                = length(var.azurerm_subnet)
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.resource.name
  name                 = var.azurerm_subnet[count.index].name
  address_prefixes     = var.azurerm_subnet[count.index].address_space
}
resource "azurerm_network_security_group" "webnsg" {
  name                = var.security_group.name
  resource_group_name = azurerm_resource_group.resource.name
  location            = var.azure_resource.location

}

resource "azurerm_network_security_rule" "webnsgrules" {
  count                        = length(var.security_group.rules)
  name                         = var.security_group.rules[count.index].name
  resource_group_name          = azurerm_resource_group.resource.name
  network_security_group_name  = azurerm_network_security_group.webnsg.name
  priority                     = var.security_group.rules[count.index].priority
  description                  = var.security_group.rules[count.index].description
  direction                    = var.security_group.rules[count.index].direction
  access                       = var.security_group.rules[count.index].access
  protocol                     = var.security_group.rules[count.index].protocol
  source_port_range            = var.security_group.rules[count.index].source_port_range
  destination_port_range       = var.security_group.rules[count.index].destination_port_range
  source_address_prefix        = var.security_group.rules[count.index].source_address_prefix
  destination_address_prefixes = [var.security_group.rules[count.index].destination_address_prefix]
}

resource "azurerm_public_ip" "example" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.resource.name
  location            = azurerm_resource_group.resource.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.webnsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "first"
  count               = 2
  resource_group_name = azurerm_resource_group.resource.name
  location            = azurerm_resource_group.resource.location


  size = "Standard_B1s"

  admin_username                  = var.aws_pas.admin_username
  admin_password                  = var.aws_pas.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    name                 = "firstt"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"

  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = base64encode(file("repairs.sh"))
  zone        = element(["1", "2"], count.index % length(["1", "2"]))
}
resource "azurerm_network_interface" "example1" {
  name                = "example-nic1"
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "first2"
  count               = 2
  resource_group_name = azurerm_resource_group.resource.name
  location            = azurerm_resource_group.resource.location

  size = "Standard_B1s"

  admin_username                  = var.aws_pas.admin_username
  admin_password                  = var.aws_pas.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.example1.id,
  ]

  os_disk {
    name                 = "firstt23"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"

  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  custom_data = base64encode(file("woody.sh"))
  zone        = element(["1", "2"], count.index % length(["1", "2"]))
}