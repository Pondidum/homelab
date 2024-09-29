packer {
  required_plugins {
    lxc = {
      source = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}

source "lxc" "coredns" {
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
  sources = [ "lxc.coredns" ]

  provisioner "file" {
    source = "etc/coredns"
    destination = "/etc"
  }

  provisioner "shell" {
    inline = [
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "apk add vault coredns",
      "rc-update add coredns",
    ]
  }

  provisioner "shell" {
    script = "../cloud.sh"
  }

  provisioner "shell" {
    inline = [
      "rc-update add coredns"
    ]
  }

  post-processor "shell-local" {
    script = "../post-process.sh"
  }
}
