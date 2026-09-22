terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-a"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "vm" {
  count = 3

  name = "vm-${count.index + 1}"
  zone = "ru-central1-a"

  # Terraform can stop VM for update
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = "e9b2blvgbdq24a6prj7r"
    nat       = true
  }

  metadata = {
    enable-oslogin = "false"

    user-data = <<-EOF
    #cloud-config
    datasource:
      Ec2:
        strict_id: false

    ssh_pwauth: false

    users:
      - name: minder
        groups: sudo
        shell: /bin/bash
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        ssh_authorized_keys:
          - ${file("~/.ssh/id_ed25519.pub")}
  EOF
  }

}

output "vm_external_ips" {
  value = {
    for vm in yandex_compute_instance.vm :
    vm.name => vm.network_interface[0].nat_ip_address
  }
}
