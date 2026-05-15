#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

export ANSIBLE_FORCE_COLOR=1

mkdir -p "$LOG_DIR"

echo "What do you want to do?"
echo "  1) Create laboratory"
echo "  2) Destroy laboratory"
read -rp "Choose [1/2]: " action

read -rp "Enable verbose mode for troubleshooting? [y/N]: " verbose
verbose="${verbose:-N}"

if [[ "$verbose" =~ ^[yY]$ ]]; then
  export TF_LOG=DEBUG
  export TF_LOG_PATH="$LOG_DIR/terraform_${TIMESTAMP}.log"
  ANSIBLE_VERBOSE="-vvv"
  echo "==> Logs saved to: $LOG_DIR"
else
  ANSIBLE_VERBOSE=""
fi

case "$action" in
  1)
    read -rp "How many workers to provision? [1]: " worker_count
    worker_count="${worker_count:-1}"

    if ! [[ "$worker_count" =~ ^[1-9][0-9]*$ ]]; then
      echo "Error: enter a positive integer."
      exit 1
    fi

    echo "==> [1/2] Provisioning infrastructure with Terraform ($worker_count workers)..."
    cd "$ROOT_DIR/terraform-k8s"
    terraform init -upgrade
    terraform apply -auto-approve \
      -var="worker_count=$worker_count"

    echo "==> [2/2] Provisioning Kubernetes cluster with Ansible..."
    cd "$ROOT_DIR/ansible"
    ansible-playbook -i inventory.yml k8s-cluster.yml $ANSIBLE_VERBOSE \
      | tee "$LOG_DIR/ansible_${TIMESTAMP}.log"

    echo "==> Cluster ready with $worker_count workers!"
    ;;
  2)
    read -rp "Are you sure you want to destroy the laboratory? [y/N]: " confirm
    confirm="${confirm:-N}"

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      echo "==> Destroying infrastructure..."
      cd "$ROOT_DIR/terraform-k8s"
      terraform destroy -auto-approve
      echo "==> Lab destroyed."
    else
      echo "Operation cancelled."
    fi
    ;;
  *)
    echo "Invalid option. Choose 1 or 2."
    exit 1
    ;;
esac
