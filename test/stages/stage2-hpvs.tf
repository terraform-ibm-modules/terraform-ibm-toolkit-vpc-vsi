module "dev_hpvs" {
  source = "./module"

  ibmcloud_api_key    = var.ibmcloud_api_key
  resource_group_name = module.resource_group.name
  resource_location   = "dal10"
  name_prefix         = var.name_prefix
  plan                = "entry"
  sshPublicKey        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzz9XOjhB99/2X2+3wb0hBij+fQpv6FPJZ3A02UHKBW7sLdPnbwHKj7Np9+atFeRWY+V+gtStAveLKWoMrVGab0e+vtYVRzq5HjClDWpqgJZTqwpK2yhQx2bBaT+RTl/fQWpoT4+JENXHupvVi1oMRhyMkKyZT+r6Tb+E85RhfRRnohOcReC+4frZLq8HKTREANM30k3lZs7cGw+tmTgLCRVeR2V+Z1T6LA+tC6JbQq7UrsvLUpwmqc9VN84hVuKtiktSeX7aGkuEib0U6thQYlGrlfZzRNXsXYtW7tyZK2+yd3ctezhKCs25ReAc+Ek7tUA3TZCNcvL5LdXKk72n7 yogendra@yogendras-mbp.c4l-in.ibmmobiledemo.com"
}
