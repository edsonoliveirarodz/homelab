#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TF_DIR="$ROOT_DIR/terraform-vm"
SERVICE_DIR="$ROOT_DIR/services/generic"

PROXMOX_TFVARS="$TF_DIR/terraform.tfvars"
SERVICE_TFVARS="$SERVICE_DIR/terraform.tfvars"
SERVICE_STATE="$SERVICE_DIR/terraform.tfstate"

export ANSIBLE_FORCE_COLOR=1

mkdir -p "$LOG_DIR"

if [[ ! -f "$PROXMOX_TFVARS" ]]; then
  echo "Error: $PROXMOX_TFVARS not found."
  echo "  cp $TF_DIR/terraform.tfvars.example $PROXMOX_TFVARS"
  exit 1
fi

if [[ ! -f "$SERVICE_TFVARS" ]]; then
  echo "Error: $SERVICE_TFVARS not found."
  echo "  cp $SERVICE_DIR/terraform.tfvars.example $SERVICE_TFVARS"
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
  export TF_LOG_PATH="$LOG_DIR/vm-terraform_${TIMESTAMP}.log"
  echo "==> Logs saved to: $LOG_DIR"
fi

case "$action" in
  1)
    read -rp "Extra disk size in GB (0 = none) [0]: " extra_disk_size
    extra_disk_size="${extra_disk_size:-0}"

    if ! [[ "$extra_disk_size" =~ ^[0-9]+$ ]]; then
      echo "Error: enter a non-negative integer."
      exit 1
    fi

    echo "==> Provisioning VM..."
    cd "$TF_DIR"
    terraform init -upgrade -reconfigure \
      -backend-config="path=$SERVICE_STATE"
    terraform apply -auto-approve \
      -var-file="$PROXMOX_TFVARS" \
      -var-file="$SERVICE_TFVARS" \
      -var="extra_disk_size=$extra_disk_size"

    VM_IP=$(terraform output -raw vm_ip)
    echo "==> VM ready at ${VM_IP%%/*}!"
    ;;
  2)
    read -rp "Are you sure you want to destroy the VM? [y/N]: " confirm
    confirm="${confirm:-N}"

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      echo "==> Destroying VM..."
      cd "$TF_DIR"
      terraform init -reconfigure \
        -backend-config="path=$SERVICE_STATE"
      terraform destroy -auto-approve \
        -var-file="$PROXMOX_TFVARS" \
        -var-file="$SERVICE_TFVARS"
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
