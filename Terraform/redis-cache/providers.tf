# 1. Declare the variables so Terraform knows to look for them
variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true # Hides it from terminal output
}

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

# 2. Reference the variables using "var."
provider "proxmox" {
  pm_api_url          = "https://192.168.1.4:8006/api2/json"
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
  pm_minimum_permission_check = false # <--- This bypasses the Proxmox 9 bug
}