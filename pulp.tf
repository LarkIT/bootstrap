data "template_file" "pulp-bootstrap" {
  template = "${file("${path.module}/templates/bootstrap.sh.tpl")}"
  vars {
    hostname      = "${var.host_prefix}-pulp-01.${var.internal_domain_name}"
    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
    puppet_env    = "production"
    role          = "pulp"
    pp_env        = "${var.pp_env}"
    region        = "${var.region}"
    host_prefix   = "${var.host_prefix}"
  }
}

data "template_cloudinit_config" "pulp" {
  part {
    filename     = "${var.bootscript_script}"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.pulp-bootstrap.rendered}"
  }

  part {
    filename     = "${var.reboot_script}"
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/templates/reboot.sh")}"
  }
}
