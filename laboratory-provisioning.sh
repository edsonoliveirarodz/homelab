#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

export ANSIBLE_FORCE_COLOR=1

mkdir -p "$LOG_DIR"

echo "What do you want to do?"
echo "  1) Create lab"
echo "  2) Destroy lab"
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

    read -rp "Extra disk size per worker for Ceph in GB (0 = no Ceph disk) [0]: " ceph_disk_size
    ceph_disk_size="${ceph_disk_size:-0}"

    if ! [[ "$ceph_disk_size" =~ ^[0-9]+$ ]]; then
      echo "Error: enter a non-negative integer."
      exit 1
    fi

    if [[ "$ceph_disk_size" -gt 0 && "$worker_count" -lt 3 ]]; then
      echo "Error: Ceph requires at least 3 workers (one OSD per node). Got: $worker_count."
      exit 1
    fi

    echo "==> [1/2] Provisioning infrastructure with Terraform ($worker_count workers, Ceph disk: ${ceph_disk_size}GB)..."
    cd "$ROOT_DIR/terraform"
    terraform init -upgrade
    terraform apply -auto-approve \
      -var="worker_count=$worker_count" \
      -var="ceph_disk_size=$ceph_disk_size"

    echo "==> [2/2] Provisioning Kubernetes cluster with Ansible..."
    cd "$ROOT_DIR/ansible"
    ansible-playbook -i inventory.yml site.yml $ANSIBLE_VERBOSE \
      | tee "$LOG_DIR/ansible_${TIMESTAMP}.log"

    echo "==> Cluster ready with $worker_count workers!"
    ;;
  2)
    read -rp "Are you sure you want to destroy the lab? [y/N]: " confirm
    confirm="${confirm:-N}"

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      echo "==> Destroying infrastructure..."
      cd "$ROOT_DIR/terraform"
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
