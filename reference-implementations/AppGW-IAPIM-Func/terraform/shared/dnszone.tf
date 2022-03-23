/* Creates a Private DNS ZOne, A Records and Vnet Link for each of the below endpoints
API Gateway	                contosointernalvnet.azure-api.net
Developer portal	        contosointernalvnet.portal.azure-api.net
The new developer portal	contosointernalvnet.developer.azure-api.net
Direct management endpoint	contosointernalvnet.management.azure-api.net
Git	                        contosointernalvnet.scm.azure-api.net */


#-------------------------------
# DNS zones 
#-------------------------------
resource "azurerm_private_dns_zone" "gateway" {
  name                = "azure-api.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}

resource "azurerm_private_dns_zone" "dev_portal" {
  name                = "portal.azure-api.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}

resource "azurerm_private_dns_zone" "new_dev_portal" {
  name                = "developer.azure-api.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}

resource "azurerm_private_dns_zone" "mgmt_portal" {
  name                = "management.azure-api.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}

resource "azurerm_private_dns_zone" "scm" {
  name                = "scm.azure-api.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}

#-------------------------------
# A records for the DNS zones
#-------------------------------
resource "azurerm_dns_a_record" "gateway_record" {
  name                = "azure-api.net/${var.apim_name}"
  zone_name           = azurerm_private_dns_zone.gateway.name
  resource_group_name = azurerm_resource_group.shared_rg.name
  ttl                 = 300
  records             = var.private_ip_address
}

resource "azurerm_dns_a_record" "dev_portal_record" {
  name                = "portal.azure-api.net/${var.apim_name}"
  zone_name           = azurerm_private_dns_zone.dev_portal.name
  resource_group_name = azurerm_resource_group.shared_rg.name
  ttl                 = 300
  records             = var.private_ip_address
}

resource "azurerm_dns_a_record" "new_dev_portal_record" {
  name                = "developer.azure-api.net/${var.apim_name}"
  zone_name           = azurerm_private_dns_zone.new_dev_portal.name
  resource_group_name = azurerm_resource_group.shared_rg.name
  ttl                 = 300
  records             = var.private_ip_address
}

resource "azurerm_dns_a_record" "mgmt_portal_record" {
  name                = "management.azure-api.net/${var.apim_name}"
  zone_name           = azurerm_private_dns_zone.mgmt_portal.name
  resource_group_name = azurerm_resource_group.shared_rg.name
  ttl                 = 300
  records             = var.private_ip_address
}

resource "azurerm_dns_a_record" "scm_record" {
  name                = "scm.azure-api.net/${var.apim_name}"
  zone_name           = azurerm_private_dns_zone.scm.name
  resource_group_name = azurerm_resource_group.shared_rg.name
  ttl                 = 300
  records             = var.private_ip_address
}

#-------------------------------
# Vnet links
#-------------------------------