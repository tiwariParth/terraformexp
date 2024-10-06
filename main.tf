terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.1.0"
    }
  }
}

provider "civo" {
  credentials_file = "creds.json"
  region           = "LON1"
}

# Create a firewall with default rules
resource "civo_firewall" "example" {
  name                 = "example-firewall"
  create_default_rules = true
}

# Query instance disk image (Debian 10)
data "civo_disk_image" "ubuntu" {
  filter {
    key    = "name"
    values = ["ubuntu-focal"]
  }
}

# Define the SSH key to be used
resource "civo_ssh_key" "example" {
  name       = "example-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a new instance with an external script
# cloud-init script to setup a systemd service for the hello_world.sh script
resource "civo_instance" "example" {
  hostname    = "example"
  tags        = ["example", "documentation"]
  notes       = "This is an example instance"
  firewall_id = civo_firewall.example.id
  size        = "g3.large"
  disk_image  = data.civo_disk_image.ubuntu.diskimages[0].id
  sshkey_id   = civo_ssh_key.example.id

  # Pass the external init script
  script = file("init_script.sh")
}


# Output the instance's public IP
output "instance_ip" {
  value = civo_instance.example.public_ip
}
