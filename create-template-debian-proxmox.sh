#!/usr/bin/env bash
set -euo pipefail

VM_ID=1000
STORAGE="tank"
IMAGE="/var/lib/vz/template/iso/debian-13-genericcloud-amd64.qcow2"

# --- Create base VM ---
qm create "$VM_ID" \
  --name debian13-template \
  --bios ovmf \
  --cpu host \
  --sockets 1 \
  --cores 2 \
  --memory 2048 \
  --machine q35 \
  --vga virtio \
  --agent 1 \
  --ostype l26 \
  --numa 0 \
  --balloon 0 \
  --scsihw virtio-scsi-single \
  --net0 virtio,bridge=vmbr0,firewall=1

# --- Import and configure disk ---
qm importdisk "$VM_ID" "$IMAGE" "$STORAGE"

qm set "$VM_ID" --scsi0 ${STORAGE}:vm-${VM_ID}-disk-0,iothread=1,discard=on,ssd=1

# --- EFI + TPM ---
qm set "$VM_ID" --efidisk0 ${STORAGE}:0,efitype=4m,pre-enrolled-keys=1
qm set "$VM_ID" --tpmstate0 ${STORAGE}:0,version=v2.0

# --- Boot and Cloud-Init ---
qm set "$VM_ID" --boot order=scsi0
qm set "$VM_ID" --ide2 ${STORAGE}:cloudinit

# --- Expand disk to 32G ---
qm disk resize "$VM_ID" scsi0 +5G

# --- Identification tags ---
qm set "$VM_ID" --tags "template,debian13"

# --- Convert to template ---
qm template "$VM_ID"

echo "Template $VM_ID created successfully!"
