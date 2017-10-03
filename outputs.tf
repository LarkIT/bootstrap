output "foreman_cloutinit" {
  value = "${data.template_cloudinit_config.foreman.rendered}"
}

output "gitlab_cloutinit" {
  value = "${data.template_cloudinit_config.gitlab.rendered}"
}

output "base_cloutinit" {
  value = "${data.template_cloudinit_config.base.rendered}"
}
