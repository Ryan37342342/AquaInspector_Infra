# AquaInspector_Infra

This repository contains the Terraform code to provision and manage the Oracle Cloud Infrastructure (OCI) resources required for the AquaInspector project.

## Features

- **Provider Configuration:** Uses the official HashiCorp OCI provider.
- **Networking:** Provisions a Virtual Cloud Network (VCN), subnet, internet gateway, and route table.
- **Security:** Configures security lists to allow SSH (22), HTTP (8080), and Grafana (3000) access.
- **Compute:** Deploys a free-tier Ubuntu VM (VM.Standard.E2.1.Micro) with Docker and Docker Compose installed via cloud-init.
- **Image Lookup:** Dynamically fetches the latest Ubuntu 22.04 image.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 0.12.6
- An Oracle Cloud account with appropriate permissions
- SSH key pair for VM access
