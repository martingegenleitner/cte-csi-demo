variable "nfs_ssh_key" {
  description = "SSH key and user for nfs server"
}

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
    ssh-keys = var.nfs_ssh_key
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
  name    = "demo-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "nfs-rule" {
  name    = "nfs-4-gke"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["2049"]
  }
  source_ranges = ["10.10.0.0/16"]
}