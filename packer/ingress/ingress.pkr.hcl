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
      "apk add caddy",
    ]
  }

  provisioner "file" {
    source = "conf.d/caddy"
    destination = "/etc/conf.d/caddy"
  }

  provisioner "file" {
    source = "Caddyfile"
    destination = "/etc/caddy/Caddyfile"
  }

  provisioner "shell" {
    inline = [
      "rc-update add caddy"
    ]
  }

  post-processor "shell-local" {
    script = "../post-process.sh"
  }
}
