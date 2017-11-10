# Cloud Init Data
#data "template_file" "bootstrap-vpn" {
#  template = "${file("${path.module}/templates/bootstrap-internal.sh.tpl")}"
#  vars {
#    hostname      = "${var.host_prefix}-vpn-01.${var.internal_domain_name}"
#    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
#    pulp_server   = "${var.host_prefix}-pulp-01.${var.internal_domain_name}"
#    puppet_env    = "production"
#    role          = "vpn"
#    region        = "${var.region}"
#    host_prefix   = "${var.host_prefix}"
#  }
#}

#data "template_cloudinit_config" "vpn" {
#  part {
#    filename     = "bootstrap.sh"
#    content_type = "text/x-shellscript"
#    content      = "${data.template_file.bootstrap-vpn.rendered}"
#    content      = "${data.template_file.bootstrap.rendered}"
#  }
#  part {
#    filename     = "reboot.sh"
#    content_type = "text/x-shellscript"
#    content      = "${file("${path.module}/templates/reboot.sh")}"
#  }
#}
