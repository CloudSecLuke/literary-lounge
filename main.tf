terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "wordpress" {
  image  = "ubuntu-22-04-x64"
  name   = "wordpress-docker-host"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  ssh_keys = [var.ssh_key_fingerprint]
  tags = ["wordpress"]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx awscli cron",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo systemctl enable nginx && sudo systemctl start nginx",
      "mkdir -p ~/wordpress-docker",
      "cat <<EOF > ~/wordpress-docker/uploads.ini\nupload_max_filesize = 100M\npost_max_size = 100M\nEOF",
      "cat <<EOF > ~/wordpress-docker/docker-compose.yml\nversion: '3.8'\nservices:\n  wordpress:\n    image: wordpress:latest\n    ports:\n      - \"8080:80\"\n    volumes:\n      - wordpress_data:/var/www/html\n      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini\n    environment:\n      WORDPRESS_DB_HOST: db\n      WORDPRESS_DB_USER: wordpress\n      WORDPRESS_DB_PASSWORD: wordpress\n      WORDPRESS_DB_NAME: wordpress\n    restart: always\n  db:\n    image: mysql:5.7\n    environment:\n      MYSQL_DATABASE: wordpress\n      MYSQL_USER: wordpress\n      MYSQL_PASSWORD: wordpress\n      MYSQL_ROOT_PASSWORD: rootpass\n    volumes:\n      - db_data:/var/lib/mysql\n    restart: always\nvolumes:\n  wordpress_data:\n  db_data:\nEOF",
      "cd ~/wordpress-docker && docker-compose up -d",
      "cat <<EOF | sudo tee /etc/nginx/sites-available/wordpress\nserver {\n    listen 80;\n    server_name ${var.domain_name};\n    location / {\n        proxy_pass http://localhost:8080;\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto $scheme;\n    }\n}\nEOF",
      "sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress || true",
      "sudo nginx -t",
      "sudo systemctl reload nginx",
      "sudo certbot --nginx --non-interactive --agree-tos -m ${var.letsencrypt_email} -d ${var.domain_name}",
      "mkdir -p /root/backups",
      "cat <<EOF > /usr/local/bin/wordpress-backup.sh\n#!/bin/bash\nDATE=$(date +%F_%H-%M-%S)\nBACKUP_DIR=/root/backups\nS3_BUCKET=${var.s3_bucket}\n\n# Dump DB\ndocker exec \$(docker ps -qf \"name=wordpress.*db\") mysqldump -u wordpress -pwordpress wordpress > \$BACKUP_DIR/db_\$DATE.sql\n\n# Copy WordPress content\ndocker cp \$(docker ps -qf \"name=wordpress.*wordpress\"):/var/www/html \$BACKUP_DIR/html_\$DATE\n\n# Upload to S3\naws s3 cp \$BACKUP_DIR/db_\$DATE.sql s3://\$S3_BUCKET/\naws s3 cp --recursive \$BACKUP_DIR/html_\$DATE s3://\$S3_BUCKET/html_\$DATE/\n\n# Clean up local backup\nrm -rf \$BACKUP_DIR/*\nEOF",
      "chmod +x /usr/local/bin/wordpress-backup.sh",
      "echo \"30 2 * * * root /usr/local/bin/wordpress-backup.sh\" | sudo tee /etc/cron.d/wordpress-backup"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key_path)
      host        = self.ipv4_address
    }
  }
}

resource "digitalocean_domain" "wordpress_domain" {
  name = var.domain_name
}

resource "digitalocean_record" "a_record" {
  domain = digitalocean_domain.wordpress_domain.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.wordpress.ipv4_address
  ttl    = 3600
}