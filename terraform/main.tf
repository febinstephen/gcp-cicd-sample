provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name = "stephen-vpc"
}

# Public Subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
}

# NAT Gateway using Cloud NAT for the private subnet
resource "google_compute_router" "router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.name
  region  = var.region
}

resource "google_compute_address" "google_compute_address" {
  name   = "nat-ip"
  region = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.google_compute_address.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall to allow internal traffic within the VPC
resource "google_compute_firewall" "internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}

# Firewall to allow external traffic to application port
resource "google_compute_firewall" "firewall" {
  name    = "allow-5000"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Compute Engine instance within the public subnet
resource "google_compute_instance" "default" {
  name         = "flask-app-instance"
  machine_type = "e2-medium"
  zone         = var.zones[0]
  tags         = ["flask-app"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    access_config {
      // Empty block to assign a public IP
    }
  }

  metadata = {
  gce-container-declaration = <<-EOT
spec:
  containers:
    - name: flask-app
      image: northamerica-northeast1-docker.pkg.dev/ci-lab-412213/flask-app/flask-img:latest
      env:
        - name: PORT
          value: "5000"
      ports:
        - containerPort: 5000
  restartPolicy: Always
EOT
}


  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = ["cloud-platform"]
  }

  # Ensure the instance can start after being created or updated
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

}

output "instance_public_ip" {
    value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
