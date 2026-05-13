locals {
  inventory_workers = {
    for w in local.workers_generated :
    trimprefix(w.name, "k8s-") => split("/", w.ip)[0]
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.yml"
  content  = <<-EOT
    all:
      vars:
        ansible_user: admin
        ansible_ssh_private_key_file: ~/.ssh/id_rsa
        ansible_become: yes
        ansible_become_method: sudo

      children:
        k8s_cluster:
          children:
            control_plane:
              hosts:
                control-plane:
                  ansible_host: ${split("/", var.control_plane.ip)[0]}

            workers:
              hosts:
    %{~ for name, ip in local.inventory_workers ~}
                ${name}:
                  ansible_host: ${ip}
    %{~ endfor ~}
  EOT
}
