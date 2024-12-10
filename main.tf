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
  count               = 1
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
  count               = 1
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

resource "azurerm_application_gateway" "example" {
  name                = "example-app-gateway"
  resource_group_name = azurerm_resource_group.resource.name
  location            = azurerm_resource_group.resource.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnets[2].id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.app_gateway_ip.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  # Backend pool for identity service
  backend_address_pool {
    name = "identity-backend-pool"
    backend_addresses {
      azurerm_linux_virtual_machine = azurerm_linux_virtual_machine.vm
    }
  }

  # Backend pool for authorization service
  backend_address_pool {
    name = "authorization-backend-pool"
    backend_addresses {
    azurerm_linux_virtual_machine= azurerm_linux_virtual_machine.vm2
    }
  }


  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  url_path_map {
    name                = "path-map"

    path_rule {
      name       = "identity-path-rule"
      paths      = ["/repair/*"]
      backend_address_pool_name = "identity-backend-pool"
      backend_http_settings_name = "backend-http-settings"
    }

    path_rule {
      name       = "authorization-path-rule"
      paths      = ["/woody/*"]
      backend_address_pool_name = "authorization-backend-pool"
      backend_http_settings_name = "backend-http-settings"
    }

    default_backend_address_pool_name   = "default-backend-pool"
    default_backend_http_settings_name   = "backend-http-settings"
  }

  request_routing_rule {
    name                       = "path-based-routing-rule"
    rule_type                 = "PathBasedRouting"
    http_listener_name        = "http-listener"
    url_path_map_name         = "path-map"
  }
}