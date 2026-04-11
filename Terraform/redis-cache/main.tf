resource "proxmox_lxc" "redis_cache" {
  target_node  = "pve" # Replace with your actual Proxmox node name
  hostname     = "redis-cache"
  ostemplate = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst" # Adjust to your preferred OS template
  password     = "14MythicalBunnyRabbitz1"
  unprivileged = true
  start        = true

  # Enable nesting to allow Redis to run properly inside the container
  features {
    nesting = true
  }

  cores  = 1
  memory = 512 # Redis is super efficient, 512MB is plenty to start
  swap   = 0

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}