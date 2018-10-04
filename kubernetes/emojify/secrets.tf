# Setup the intial Vault secrets required to enable the K8s auth and 
# dynamic secrets for our applicaton
data "template_file" "provision_secrets" {
  template = "${file("${path.module}/scripts/provision_secrets.sh")}"

  vars {
    redis_key    = "${azurerm_redis_cache.emojify_cache.primary_access_key}"
    redis_server = "${azurerm_redis_cache.emojify_cache.hostname}"
    db_server    = "${azurerm_postgresql_server.emojify_db.fqdn}"
    db_database  = "keratin"
    db_username  = "${azurerm_postgresql_server.emojify_db.administrator_login}"
    db_password  = "${azurerm_postgresql_server.emojify_db.administrator_login_password}"
  }
}

resource "null_resource" "provision_secrets" {
  triggers {
    private_key_id = "${data.terraform_remote_state.core.vault_key}"
  }

  connection {
    host        = "${data.terraform_remote_state.core.vault_host}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${data.terraform_remote_state.core.vault_key}"
    agent       = false
  }

  provisioner "file" {
    content     = "${data.template_file.provision_secrets.rendered}"
    destination = "/tmp/provision_secrets.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision_secrets.sh",
      "sudo /tmp/provision_secrets.sh",
    ]
  }
}
