packer {
  required_plugins {
    lxc = {
      source = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}

source "lxc" "vault" {
  config_file               = "config"
  template_name             = "download"
  template_parameters = [
    "--dist", "alpine",
    "--release", "3.18",
    "--arch", "amd64"
  ]
  create_options = [ "-f", "config" ]
  output_directory = "out"
}

build {
  sources = [ "lxc.vault" ]

  provisioner "shell" {
    inline = [
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "apk update",
      "apk add vault jq",
    ]
  }

  provisioner "shell" {
    script = "../cloud.sh"
  }

  provisioner "file" {
    source = ".profile"
    destination = "/root/.profile"
  }

  provisioner "file" {
    source = "vault.hcl"
    destination = "/etc/vault.hcl"
  }

  provisioner "file" {
    source = "init.sh"
    destination = "/etc/init.d/vault"
  }

  provisioner "file" {
    source = "vault.hcl"
    destination = "/etc/vault.hcl"
  }

  provisioner "shell" {
    inline = [
      "rc-update add vault"
    ]
  }

  post-processor "shell-local" {
    script = "../post-process.sh"
  }
}
