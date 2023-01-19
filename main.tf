locals {
  zone             = "ru-central1-a"
  network_name     = "network1"
  subnet_name      = "subnet1"
  vm_name          = "ubuntu"
  image_id         = "fd81hgrcv6lsnkremf32"
}

terraform {
  required_providers {
    yandex    = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.47.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "authorized_key.json"
  cloud_id  = "b1gmm7o7pt50hkvtsig1"
  folder_id = "b1guhc3e5if3hpdvi62v"
  zone = "ru-central1-a"
}

resource "yandex_vpc_network" "docker-vm-network" {
  name = local.network_name
}

resource "yandex_vpc_subnet" "docker-vm-network-subnet-a" {
  name           = local.subnet_name
  zone           = local.zone
  v4_cidr_blocks = ["192.168.1.0/24"]
  network_id     = yandex_vpc_network.docker-vm-network.id

}

data "yandex_compute_image" "container-optimized-image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "docker-vm" {
  name               = local.vm_name
  platform_id        = "standard-v3"
  zone               = local.zone
  service_account_id = "ajesh4d1h72qghglqran"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.docker-vm-network-subnet-a.id
    nat       = true
  }

  metadata = {
    user-data = "${file("config.yaml")}"
    docker-container-declaration = file("declaration.yaml")
  }
}

output "external_ip" {
  value = yandex_compute_instance.docker-vm.network_interface.0.nat_ip_address
}