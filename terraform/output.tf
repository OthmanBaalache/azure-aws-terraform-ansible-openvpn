output ipAddress {
  value = azurerm_public_ip.publicip.ip_address
}
output dnsLabel {
  value = azurerm_public_ip.publicip.domain_name_label
}