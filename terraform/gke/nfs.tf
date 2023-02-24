resource "google_compute_instance" "nfs_server" {
  name         = "nfs-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  metadata = {
    ssh-keys = "martin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhTwcLPwfFp+oS/sqWpgmF3s7MTBUBINhbcqnZAg6IRS2f79C5CpUbd6Xywm4FH+Mk2IY5nEB9KP+6vHuX+R9Jyw201QA/5YLaDprs8SRCMcvDzYNqA4f6T0D4aYDwFrhQEOuK2rgKDCShVthcZr8Mgdt5wZztTzGzQ/DgSeobjThXBwfbW/AE7CovbIh0Kzp/qH/H6I4M6WYKmuE7Xm7vfEy6aYnhKfKgKOqFNR6Yfudlb6kVjcctD6KAdyTVFplwV5XG0j3vpYrX+hrRes/mOwImw0KckO6gVwf8KixL+6O8VO/jVTy2EYE0LVr3+DY5nYcfr1PAtgSM3LNmStpskHnhgh29rl+jWqL5JMnd618ScjZ0T5EWngBugMSAL6u0EIjIxcO07k3sosW8T06oxkYWNzHNMTp5rn4hSPlGcelL03b9KsnnFGKywqGPWZeYUtefj7QTY7XyxO/+KSVh6+L305O9RVYJ/XGCId3f9JCbLepteE6+o34fcaCXahQONyQUAlmbCBSbwkAE28gr5L1XkD+WtNPz7n1NqWMuzjNT8Y+ZbFg8540f12EgiOfhBB69xMvcZ29r9eB2b/Ss8Rfg+x4uFfhL+B+w54oRqtMl7bricZvxhWmMDPaGtziAjKHpKM8aHwntdBANtUtPRAKA4OdMMPLAXHUj3LaJsw== martin.gegenleitner@thalesgroup.com"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    network_ip = "10.10.0.2"
    access_config {
      // Ephemeral public IP
    }
  }
}

resource "google_compute_firewall" "ssh-rule" {
  name = "demo-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "nfs-rule" {
  name = "nfs-4-gke"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports = ["2049"]
  }
  source_ranges = ["10.10.0.0/16"]
}