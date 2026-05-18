#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TF_DIR="$ROOT_DIR/terraform-vm"
SERVICE_DIR="$ROOT_DIR/services/vault"

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
echo "  1) Create Vault VM"
echo "  2) Destroy Vault VM"
read -rp "Choose [1/2]: " action

read -rp "Enable verbose mode for troubleshooting? [y/N]: " verbose
verbose="${verbose:-N}"

if [[ "$verbose" =~ ^[yY]$ ]]; then
  export TF_LOG=DEBUG
  export TF_LOG_PATH="$LOG_DIR/vault-terraform_${TIMESTAMP}.log"
  ANSIBLE_VERBOSE="-vvv"
  echo "==> Logs saved to: $LOG_DIR"
else
  ANSIBLE_VERBOSE=""
fi

case "$action" in
  1)
    echo "==> [1/2] Provisioning VM with Terraform..."
    cd "$TF_DIR"
    terraform init -upgrade -reconfigure \
      -backend-config="path=$SERVICE_STATE"
    terraform apply -auto-approve \
      -var-file="$PROXMOX_TFVARS" \
      -var-file="$SERVICE_TFVARS"

    VM_IP=$(terraform output -raw vm_ip)
    VM_IP="${VM_IP%%/*}"

    echo "==> [2/2] Configuring Vault with Ansible..."
    cd "$ROOT_DIR/ansible"
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook \
      -i "$VM_IP," \
      -u admin \
      vault.yml \
      $ANSIBLE_VERBOSE \
      | tee "$LOG_DIR/vault-ansible_${TIMESTAMP}.log"

    echo "==> Vault VM ready at http://$VM_IP:8200"
    echo "==> IMPORTANT: save the unseal keys and root token printed above!"
    ;;
  2)
    read -rp "Are you sure you want to destroy the Vault VM? [y/N]: " confirm
    confirm="${confirm:-N}"

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      echo "==> Destroying Vault VM..."
      cd "$TF_DIR"
      terraform init -reconfigure \
        -backend-config="path=$SERVICE_STATE"
      terraform destroy -auto-approve \
        -var-file="$PROXMOX_TFVARS" \
        -var-file="$SERVICE_TFVARS"
      echo "==> Vault VM destroyed."
    else
      echo "Operation cancelled."
    fi
    ;;
  *)
    echo "Invalid option. Choose 1 or 2."
    exit 1
    ;;
esac
