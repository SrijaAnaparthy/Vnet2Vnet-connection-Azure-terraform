#connection between two Azure virtual network in different locations/regions.


#Resource group creation at location - West Europe
resource "azurerm_resource_group" "Eur-rg" {
  name     = "Europe-RG"
  location = "West Europe"
}

#NSG for US-RG
resource "azurerm_network_security_group" "Eur-NSG" {
  name                = "Europe-NSG"
  location            = azurerm_resource_group.Eur-rg.location
  resource_group_name = azurerm_resource_group.Eur-rg.name
}

#Vnet creation with address space 10.0.0.0/16
resource "azurerm_virtual_network" "Eur-Vnet" {
  name                = "Europe-network"
  location            = azurerm_resource_group.Eur-rg.location
  resource_group_name = azurerm_resource_group.Eur-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

#subnet 1 in vnet named Eur-Vnet - addr prefix : 10.0.2.0/24
  subnet {
    name           = "Eur-subnet1"
    address_prefix = "10.0.2.0/24"
  }

#subnet 2 in vnet named Eur-Vnet - addr prefix : 10.0.3.0/24
  subnet {
    name           = "Eur-subnet2"
    address_prefix = "10.0.3.0/24"
    security_group = azurerm_network_security_group.Eur-NSG.id
  }

  tags = {
    environment = "Production"
  }
}

#gateway subnet creation with address space : 10.0.1.0/24
resource "azurerm_subnet" "Eur-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.Eur-rg.name
  virtual_network_name = azurerm_virtual_network.Eur-Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#Dynamic public ip creation to associate it with gateway
resource "azurerm_public_ip" "Eur-pubip" {
  name                = "Eur-pubip"
  location            = azurerm_resource_group.Eur-rg.location
  resource_group_name = azurerm_resource_group.Eur-rg.name

  allocation_method = "Dynamic"
}

#Vnet gateway creation - Eur-Vnet
resource "azurerm_virtual_network_gateway" "Eur-Vnet-gateway" {
  name                = "Eur-gateway"
  location            = azurerm_resource_group.Eur-rg.location
  resource_group_name = azurerm_resource_group.Eur-rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "Eur-vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.Eur-pubip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.Eur-subnet.id
  }
}




#Vnet2 creation at location - East US

#Resource group creation at location - East US
resource "azurerm_resource_group" "US-rg" {
  name     = "US-RG"
  location = "East US"
}

#NSG for US-RG 
resource "azurerm_network_security_group" "US-NSG" {
  name                = "US-NSG"
  location            = azurerm_resource_group.US-rg.location
  resource_group_name = azurerm_resource_group.US-rg.name
}

#Vnet creation with address space 10.1.0.0/16
resource "azurerm_virtual_network" "US-Vnet" {
  name                = "US-network"
  location            = azurerm_resource_group.US-rg.location
  resource_group_name = azurerm_resource_group.US-rg.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = ["10.1.0.4", "10.1.0.5"]

#subnet 1 in vnet named US-Vnet - addr prefix : 10.1.2.0/24
  subnet {
    name           = "US-subnet1"
    address_prefix = "10.1.2.0/24"
  }

#subnet 2 in vnet named US-Vnet - addr prefix : 10.1.3.0/24
  subnet {
    name           = "US-subnet2"
    address_prefix = "10.1.3.0/24"
    security_group = azurerm_network_security_group.US-NSG.id
  }

  tags = {
    environment = "Production"
  }
}

#gateway subnet creation with address space : 10.1.1.0/24
resource "azurerm_subnet" "US-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.US-rg.name
  virtual_network_name = azurerm_virtual_network.US-Vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

#Dynamic public ip creation to associate it with gateway
resource "azurerm_public_ip" "US-pubip" {
  name                = "US-pubip"
  location            = azurerm_resource_group.US-rg.location
  resource_group_name = azurerm_resource_group.US-rg.name

  allocation_method = "Dynamic"
}

#Vnet gateway creation for US-Vnet
resource "azurerm_virtual_network_gateway" "US-Vnet-gateway" {
  name                = "US-gateway"
  location            = azurerm_resource_group.US-rg.location
  resource_group_name = azurerm_resource_group.US-rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "US-vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.US-pubip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.US-subnet.id
  }
}


#connection between two Vnets in different locations/regions.
resource "azurerm_virtual_network_gateway_connection" "europe_to_us" {
  name                = "europe-to-us"
  location            = azurerm_resource_group.Eur-rg.location
  resource_group_name = azurerm_resource_group.Eur-rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.Eur-Vnet-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.US-Vnet-gateway.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_virtual_network_gateway_connection" "us_to_europe" {
  name                = "us-to-europe"
  location            = azurerm_resource_group.US-rg.location
  resource_group_name = azurerm_resource_group.US-rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.US-Vnet-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.Eur-Vnet-gateway.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

