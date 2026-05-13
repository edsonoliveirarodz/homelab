# k8s-cluster-baremetal

Ansible role that provisions a production-like Kubernetes cluster on bare-metal or virtual machines.

Handles the full lifecycle from OS-level prerequisites to a GitOps-ready cluster with networking, storage, and continuous delivery.

## What it installs

| Component | Version variable | Notes |
|---|---|---|
| containerd | — | Runtime with `SystemdCgroup = true` |
| kubelet / kubeadm / kubectl | `kubernetes_version` | Pinned via apt |
| Gateway API CRDs | `gateway_api_version` | Experimental channel (includes TLSRoute) |
| Cilium | `cilium_version` | CNI + kube-proxy replacement + Gateway API controller |
| Local Path Provisioner | `local_path_provisioner_version` | Default StorageClass |
| MetalLB | `metallb_version` | L2 mode, configures `IPAddressPool` |
| ArgoCD | `argocd_version` | Server-side apply; bootstraps App of Apps |

## Requirements

- Debian-based OS (Debian 12+ or Ubuntu 22.04+)
- cgroup v2 active — the role fails fast if not found
- SSH access with passwordless sudo
- Inventory with `control_plane` and `workers` groups (see example below)

## Role Variables

All variables have defaults in `defaults/main.yml`:

```yaml
kubernetes_version: "1.36"
k8s_admin_user: "admin"
pod_network_cidr: "10.244.0.0/16"

gateway_api_version: "1.5.1"
cilium_version: "1.19.3"
cilium_cli_version: "0.19.2"

local_path_provisioner_version: "0.0.36"

metallb_version: "0.15.3"
metallb_ip_pool_range: "192.168.1.240-192.168.1.250"

argocd_version: "3.4.1"
gitops_repo_url: "https://github.com/your-user/your-repo.git"

kernel_modules:
  - overlay
  - br_netfilter
```

| Variable | Description |
|---|---|
| `kubernetes_version` | Kubernetes minor version for apt pinning |
| `k8s_admin_user` | OS user that receives the kubeconfig |
| `pod_network_cidr` | Pod CIDR passed to `kubeadm init` |
| `gateway_api_version` | Gateway API CRDs version |
| `cilium_version` | Cilium Helm chart version |
| `cilium_cli_version` | Cilium CLI binary version |
| `local_path_provisioner_version` | Rancher Local Path Provisioner version |
| `metallb_version` | MetalLB manifest version |
| `metallb_ip_pool_range` | IP range for `IPAddressPool` (L2 mode) |
| `argocd_version` | ArgoCD manifest version |
| `gitops_repo_url` | Git repository ArgoCD will track for App of Apps |

## Inventory structure

The role uses `inventory_hostname in groups[...]` to scope tasks per node type:

```yaml
all:
  children:
    k8s_cluster:
      children:
        control_plane:
          hosts:
            control-plane:
              ansible_host: 192.168.1.201
        workers:
          hosts:
            worker-1:
              ansible_host: 192.168.1.202
            worker-2:
              ansible_host: 192.168.1.203
```

Tasks exclusive to `control_plane`: cluster init, kubeconfig, Gateway API, Cilium, Local Path Provisioner, MetalLB, ArgoCD.  
Tasks exclusive to `workers`: join cluster via `kubeadm join`.

## Example Playbook

```yaml
- hosts: k8s_cluster
  roles:
    - role: k8s-cluster-baremetal
      vars:
        metallb_ip_pool_range: "10.0.0.200-10.0.0.210"
        gitops_repo_url: "https://github.com/your-user/your-repo.git"
```

## Dependencies

None. No external Ansible Galaxy roles required.

## License

MIT
