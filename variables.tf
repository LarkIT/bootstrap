variable "region" {
  description = "The AWS region where virtual machines will be deployed."
}

variable "host_prefix" {
  description = "Hostname prefix (abc)"
}

variable "internal_domain_name" {
  description = "Hostname prefix (abc)"
}

variable "bootscript_script" {
  description = "Shell script to bootstrap the system."
  default     = "bootstrap.sh"
}

variable "reboot_script" {
  description = "Shell script to reboot the system."
  default     = "reboot.sh"
}

variable "role" {
  description = "Puppet classification role"
  default     = "base"
}

variable "hostname" {
  description = "Name of the host"
}

variable "pp_env" {
  description = "Trusted fact pp_env setting"
  default     = "production" 
}

variable "bootstrap_template" {
  description = "Custom bootstrap template"
  default     = "blank"
}

variable "puppet_server" {
  description = "Default Puppet server name."
  default     = "foreman-01"
}

variable "gitlab_server" {
  description = "Default Gitlab server name."
  default     = "gitlab-01"
}
