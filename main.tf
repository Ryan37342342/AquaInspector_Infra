terraform {
  required_version = ">= 0.12.6"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.1.0"
    }
  }
}

// Provider Configuration
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
// look up availability domains (AZ)
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

// look up ubuntu image
data "oci_core_images" "ubuntu_image" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
}

//create a vcn (VPC)
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "aquainspector-vcn"
  dns_label = "AQI"
  
}

// attach an internet gateway to vcn
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "aquainspector-ig"
  enabled     = true
}

// add a route to the gateway from the vcn
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "aquainspector-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

// create a subnet withing the vcn
resource "oci_core_subnet" "subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "aquainspector-subnet"
  route_table_id             = oci_core_route_table.route_table.id
  prohibit_public_ip_on_vnic = false
  dns_label                  = "aquainspector"
}

// create security list (sec group) for the vcn
resource "oci_core_security_list" "sec_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  //allow ssh
  ingress_security_rules {
    protocol = "6"
    source   = var.my_ip
    tcp_options {
      min = 22
      max = 22
    }
  }
  //allow 8080
  ingress_security_rules {
    protocol = "6"
    source   = var.my_ip
    tcp_options {
      min = 8080
      max = 8080
    }
  }
  //allow port 3000 for grafana
  ingress_security_rules {
    protocol = "6"
    source   = var.my_ip
    tcp_options {
      min = 3000
      max = 3000
    }
  }
  // allow all traffic out
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

// create a free vim to host AquaInspector
resource "oci_core_instance" "aquainspector_vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "aquainspector-vm"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_image.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("cloud-init.yaml"))
  }
}
