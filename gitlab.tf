data "template_file" "gitlab-bootstrap" {
  template = "${file("${path.module}/templates/bootstrap.sh.tpl")}"
  vars {
    hostname      = "${var.host_prefix}-gitlab-01.${var.internal_domain_name}"
    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
    gitlab_server = "${var.host_prefix}-gitlab-01.${var.internal_domain_name}"
    puppet_env    = "production"
    role          = "base"
  }
}

data "template_file" "gitlab" {
  template = "${file("${path.module}/templates/gitlab-install.sh.tpl")}"
  vars {
    hostname      = "${var.host_prefix}-gitlab-01.${var.internal_domain_name}"
    puppet_server = "${var.host_prefix}-foreman-01.${var.internal_domain_name}"
    puppet_env    = "production"
    role          = "gitlab"
  }
}

data "template_cloudinit_config" "gitlab" {
  part {
    filename     = "${var.bootscript_script}"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.gitlab-bootstrap.rendered}"
  }

  part {
    filename = "gitlab-install.sh"
    content_type = "text/x-shellscript"
    content = "${data.template_file.gitlab.rendered}"
  }

  part {
    filename     = "${var.reboot_script}"
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/templates/reboot.sh")}"
  }
}
