variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint uploaded to DigitalOcean"
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the WordPress site"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address to register with Let's Encrypt"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private key for SSH access"
  type        = string
}
