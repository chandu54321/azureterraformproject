variable "azure_resource" {
  type = object({
    name     = string
    location = string
  })
  default = {
    name     = "first_resourcegroup"
    location = "Central India"
  }
}

variable "azure_vnet" {
  type = object({
    name          = string
    address_space = list(string)
    location      = string
  })
  default = {
    name          = "firstvnet"
    address_space = ["10.0.0.0/16"]
    location      = "Central India"
  }
}

variable "azurerm_subnet" {
  type = list(object({
    name          = string
    address_space = list(string)
  }))
  default = [{
    name          = "web-1"
    address_space = ["10.0.1.0/24"]
    }, {
    name          = "db-1"
    address_space = ["10.0.2.0/24"]
    }
  ]
}
variable "security_group" {
  type = object({
    name = string
    rules = list(object({
      name                       = string
      priority                   = number
      description                = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

  })
  default = {
    name = "firstweb"
    rules = [{
      name                       = "openssh"
      priority                   = 300
      description                = "open ssh"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "0.0.0.0/0"
      },
      {
        name                       = "openhttp"
        priority                   = 250
        description                = "open http"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "0.0.0.0/0"
      },
      {
        name                       = "openhttps"
        priority                   = 450
        description                = "open https"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "0.0.0.0/0"
    }]
  }
}

variable "aws_pas" {
  type = object({
    admin_username = string
    admin_password = string
  })
  default = {
    admin_username = "dell"
    admin_password = "chandu54331@!"
  }
}