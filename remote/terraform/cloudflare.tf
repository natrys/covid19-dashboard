variable "cloudflare_api_token" {
  type = string
}
variable "cloudflare_zone_id" {
  type = string
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "azure" {
  zone_id = var.cloudflare_zone_id
  value = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
  name = "az"
  type = "A"
  depends_on = [ azurerm_linux_virtual_machine.myterraformvm ]
}

resource "cloudflare_record" "covid19" {
  zone_id = var.cloudflare_zone_id
  value = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
  name = "covid19"
  type = "A"
  depends_on = [ azurerm_linux_virtual_machine.myterraformvm ]
}
