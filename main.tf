provider "aws" {
  region = var.aws_region
}

# Automatically generate a secure SSH key locally
resource "tls_private_key" "wazuh_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key_pem" {
  content         = tls_private_key.wazuh_ssh_key.private_key_pem
  filename        = "${path.module}/wazuh-lab-key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "wazuh_aws_key" {
  key_name   = "wazuh-lab-key-dynamic"
  public_key = tls_private_key.wazuh_ssh_key.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_vpc" "security_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.security_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.security_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.security_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "security_sg" {
  name   = "wazuh-suricata-sg"
  vpc_id = aws_vpc.security_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1514
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sec_lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.security_sg.id]
  key_name               = aws_key_pair.wazuh_aws_key.key_name

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -ex

              # Step 1: Update system packages and install prerequisites
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git

              # Step 2: Set memory limit parameter required by Wazuh Indexer (OpenSearch)
              sysctl -w vm.max_map_count=262144
              echo "vm.max_map_count=262144" >> /etc/sysctl.conf

              # Step 3: Install Docker Engine and Compose Plugin
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              systemctl enable docker
              systemctl start docker

              until docker info >/dev/null 2>&1; do
                sleep 2
              done

              # Step 4: Clone repo, generate TLS certificates, and start Wazuh single-node stack
              git clone --branch v4.8.2 https://github.com/wazuh/wazuh-docker.git /opt/wazuh-docker
              cd /opt/wazuh-docker/single-node
              rm -rf config/wazuh_indexer_ssl_certs
              docker compose -f generate-indexer-certs.yml run --rm generator
              docker compose up -d
              EOF

  tags = {
    Name = "Security-Lab-Node"
  }
}