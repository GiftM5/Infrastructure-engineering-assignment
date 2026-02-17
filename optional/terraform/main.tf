resource "local_file" "server_inventory" {
  content  = join("\n", var.servers)
  filename = "${path.module}/inventory.txt"
}
