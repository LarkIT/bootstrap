data "template_file" "bootstrap" {
  template = "${file("${path.module}/templates/bootstrap.sh.tpl")}"
  vars {
    hostname      = "${var.host_prefix}-${var.hostname}.${var.internal_domain_name}"
    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
    gitlab_server = "${var.host_prefix}-gitlab-01.${var.internal_domain_name}"
    puppet_env    = "production"
    role          = "${var.role}" 
    pp_env        = "${var.pp_env}"
    region        = "${var.region}"
    host_prefix   = "${var.host_prefix}"
  }
}

data "template_file" "fragment" {
  template = "${file("${path.module}/templates/${var.bootstrap_template}.sh.tpl")}"
  vars {
    hostname      = "${var.host_prefix}-${var.hostname}.${var.internal_domain_name}"
    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
    gitlab_server = "${var.host_prefix}-gitlab-01.${var.internal_domain_name}"
    puppet_env    = "production"
    role          = "${var.role}"
    pp_env        = "${var.pp_env}"
    region        = "${var.region}"
    host_prefix   = "${var.host_prefix}"
  }
}

data "template_cloudinit_config" "base" {
  part {
    filename     = "${var.bootscript_script}"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.bootstrap.rendered}"
  }

  part {
    filename     = "${var.bootstrap_template}.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.fragment.rendered}"
  }

  part {
    filename     = "${var.reboot_script}"
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/templates/reboot.sh")}"
  }
}
