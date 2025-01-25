packer {
  required_plugins {
    lxc = {
      source = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}

locals {
  vault_version = "1.18.3"
}


source "lxc" "postgres" {
  config_file               = "config"
  template_name             = "download"
  template_parameters = [
    "--dist", "alpine",
    "--release", "3.20",
    "--arch", "amd64"
  ]
  create_options = [ "-f", "config" ]
  output_directory = "out"
}

build {
  sources = [ "lxc.postgres" ]

  provisioner "shell" {
    inline = [
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "apk add jq postgresql16 postgresql16-contrib postgresql16-openrc",
      "rc-update add postgresql",

      "wget https://releases.hashicorp.com/vault/${local.vault_version}/vault_${local.vault_version}_linux_amd64.zip -O vault.zip",
      "unzip vault.zip vault",
      "mv vault /usr/local/bin/",
      "rm vault.zip"
    ]
  }

  provisioner "file" {
    source = "etc/conf.d/postgresql"
    destination = "/etc/conf.d/postgresql"
  }

  provisioner "file" {
    source = "etc/postgresql16"
    destination = "/etc"
  }

  provisioner "shell" {
    script = "../cloud.sh"
  }

  post-processor "shell-local" {
    script = "../post-process.sh"
  }
}
