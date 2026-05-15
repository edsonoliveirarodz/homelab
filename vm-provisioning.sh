#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TF_DIR="$ROOT_DIR/terraform-vm"

mkdir -p "$LOG_DIR"

if [[ ! -f "$TF_DIR/terraform.tfvars" ]]; then
  echo "Error: $TF_DIR/terraform.tfvars not found."
  echo "Copy the example and fill in your values:"
  echo "  cp $TF_DIR/terraform.tfvars.example $TF_DIR/terraform.tfvars"
  exit 1
fi

echo "What do you want to do?"
echo "  1) Create VM"
echo "  2) Destroy VM"
read -rp "Choose [1/2]: " action

read -rp "Enable verbose mode for troubleshooting? [y/N]: " verbose
verbose="${verbose:-N}"

if [[ "$verbose" =~ ^[yY]$ ]]; then
  export TF_LOG=DEBUG
  export TF_LOG_PATH="$LOG_DIR/terraform-vm_${TIMESTAMP}.log"
  echo "==> Logs saved to: $LOG_DIR"
fi

case "$action" in
  1)
    echo "==> Provisioning VM..."
    cd "$TF_DIR"
    terraform init -upgrade
    terraform apply -auto-approve
    echo "==> VM ready!"
    ;;
  2)
    read -rp "Are you sure you want to destroy the VM? [y/N]: " confirm
    confirm="${confirm:-N}"

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      echo "==> Destroying VM..."
      cd "$TF_DIR"
      terraform destroy -auto-approve
      echo "==> VM destroyed."
    else
      echo "Operation cancelled."
    fi
    ;;
  *)
    echo "Invalid option. Choose 1 or 2."
    exit 1
    ;;
esac
