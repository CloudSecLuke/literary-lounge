# 🚀 Terraform WordPress Deployment on DigitalOcean

This project provisions a secure, Dockerized WordPress server on a **DigitalOcean Droplet**, complete with:

- **Dockerized WordPress + MySQL**
- **NGINX + Let's Encrypt SSL certificate**
- **Custom domain DNS record**
- **Automated infrastructure provisioning with Terraform**

---

## 🧰 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [DigitalOcean CLI (doctl)](https://docs.digitalocean.com/reference/doctl/) (optional, for API tokens)
- A DigitalOcean account
- A registered domain name
- Your SSH key added to DigitalOcean

---

## ⚙️ Configuration

Create a `terraform.tfvars` file with the following contents:

```hcl
do_token             = "your_digitalocean_api_token"
ssh_key_fingerprint  = "your_ssh_key_fingerprint"
domain_name          = "yourdomain.com"
letsencrypt_email    = "you@example.com"
ssh_private_key_path = "~/.ssh/id_rsa"

