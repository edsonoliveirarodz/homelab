output "control_plane_ip" {
  description = "Control-plane IP"
  value       = var.control_plane.ip
}

output "worker_ips" {
  description = "Workers' IPs"
  value       = { for w in local.workers_generated : w.name => w.ip }
}