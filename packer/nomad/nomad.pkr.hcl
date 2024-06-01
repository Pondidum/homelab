packer {
  required_plugins {
    lxc = {
      source = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}

source "lxc" "nomad" {
  config_file               = "config"
  template_name             = "download"
  template_parameters = [
    "--dist", "ubuntu",
    "--release", "jammy",
    "--arch", "amd64"
  ]
  create_options = [ "-f", "config" ]
  output_directory = "out"
}

build {
  sources = [ "lxc.nomad" ]

  // provisioner "shell" {
  //   inline = [
  //     "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
  //   ]
  // }

  provisioner "shell" {
    script = "./install-nomad.sh"
  }

  provisioner "file" {
    source = "nomad.hcl"
    destination = "/etc/nomad.d/nomad.hcl"
  }

  post-processor "shell-local" {
    script = "../post-process.sh"
  }
}
