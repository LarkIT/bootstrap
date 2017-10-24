data "template_file" "railsapp-bootstrap" {
#  template = "${file("${path.module}/templates/bootstrap-internal.sh.tpl")}"
  template = "${file("${path.module}/templates/bootstrap.sh.tpl")}"
  vars {
    hostname      = "${var.host_prefix}-stageapp-01.${var.internal_domain_name}"
    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
    pulp_server   = "${var.host_prefix}-pulp-01.${var.internal_domain_name}"
    puppet_env    = "production"
    role          = "railsapp"
    region        = "${var.region}"
    host_prefix   = "${var.host_prefix}"
  }
}

data "template_cloudinit_config" "railsapp" {
  part {
    filename = "bootstrap.sh"
    content_type = "text/x-shellscript"
    content = "${data.template_file.railsapp-bootstrap.rendered}"
  }
  part {
    filename = "reboot.sh"
    content_type = "text/x-shellscript"
    content = "${file("${path.module}/templates/reboot.sh")}"
  }
}
