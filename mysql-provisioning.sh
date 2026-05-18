#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TF_DIR="$ROOT_DIR/terraform-vm"
SERVICE_DIR="$ROOT_DIR/services/mysql"

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
echo "  1) Create MySQL VM"
echo "  2) Destroy MySQL VM"
read -rp "Choose [1/2]: " action

read -rp "Enable verbose mode for troubleshooting? [y/N]: " verbose
verbose="${verbose:-N}"

if [[ "$verbose" =~ ^[yY]$ ]]; then
  export TF_LOG=DEBUG
  export TF_LOG_PATH="$LOG_DIR/mysql-terraform_${TIMESTAMP}.log"
  ANSIBLE_VERBOSE="-vvv"
  echo "==> Logs saved to: $LOG_DIR"
else
  ANSIBLE_VERBOSE=""
fi

case "$action" in
  1)
    while true; do
      read -rp "Extra disk size in GB: " extra_disk_size
      if [[ "$extra_disk_size" =~ ^[1-9][0-9]*$ ]]; then
        break
      fi
      echo "Error: enter a positive integer."
    done

    echo "==> [1/2] Provisioning VM with Terraform..."
    cd "$TF_DIR"
    terraform init -upgrade -reconfigure \
      -backend-config="path=$SERVICE_STATE"
    terraform apply -auto-approve \
      -var-file="$PROXMOX_TFVARS" \
      -var-file="$SERVICE_TFVARS" \
      -var="extra_disk_size=$extra_disk_size"

    VM_IP=$(terraform output -raw vm_ip)
    VM_IP="${VM_IP%%/*}"

    echo "==> [2/2] Configuring MySQL with Ansible..."
    cd "$ROOT_DIR/ansible"
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook \
      -i "$VM_IP," \
      -u admin \
      mysql.yml \
      $ANSIBLE_VERBOSE \
      | tee "$LOG_DIR/mysql-ansible_${TIMESTAMP}.log"

    echo "==> MySQL VM ready at $VM_IP!"
    ;;
  2)
    read -rp "Are you sure you want to destroy the MySQL VM? [y/N]: " confirm
    confirm="${confirm:-N}"

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      echo "==> Destroying MySQL VM..."
      cd "$TF_DIR"
      terraform init -reconfigure \
        -backend-config="path=$SERVICE_STATE"
      terraform destroy -auto-approve \
        -var-file="$PROXMOX_TFVARS" \
        -var-file="$SERVICE_TFVARS"
      echo "==> MySQL VM destroyed."
    else
      echo "Operation cancelled."
    fi
    ;;
  *)
    echo "Invalid option. Choose 1 or 2."
    exit 1
    ;;
esac
