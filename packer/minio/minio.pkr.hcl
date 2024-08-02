packer {
  required_plugins {
    lxc = {
      source = "github.com/hashicorp/lxc"
      version = "~> 1"
    }
  }
}

source "lxc" "minio" {
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
  sources = [ "lxc.minio" ]

  provisioner "file" {
    source = "init.d.sh"
    destination = "/etc/init.d/minio"
  }

  provisioner "file" {
    source = "conf.d.sh"
    destination = "/etc/conf.d/minio"
  }

  provisioner "shell" {
    inline = [
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "apk add vault jq",
      "wget https://dl.min.io/server/minio/release/linux-amd64/minio",
      "chmod +x minio",
      "chmod +x /etc/init.d/minio",
      "mv minio /usr/bin/minio",
      "addgroup -S minio 2>/dev/null",
      "adduser -S -D -H -h /var/lib/minio -s /sbin/nologin -G minio -g minio minio 2>/dev/null"
    ]
  }

  provisioner "shell" {
    script = "../cloud.sh"
  }

  provisioner "shell" {
    inline = [
      "rc-update add minio"
    ]
  }

  post-processor "shell-local" {
    script = "../post-process.sh"
  }
}
