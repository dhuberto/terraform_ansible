# AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name     = "${var.environment}-vpc"
    Curso    = "Infraestrutura como Codigo"
    Ambiente = var.environment
    Projeto  = "terraform_ansible"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name     = "${var.environment}-subnet-public"
    Curso    = "Infraestrutura como Codigo"
    Ambiente = var.environment
    Projeto  = "terraform_ansible"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name     = "${var.environment}-igw"
    Curso    = "Infraestrutura como Codigo"
    Ambiente = var.environment
    Projeto  = "terraform_ansible"
  }
}

# Tabela de Roteamento
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name     = "${var.environment}-rt-public"
    Curso    = "Infraestrutura como Codigo"
    Ambiente = var.environment
    Projeto  = "terraform_ansible"
  }
}

# Associação da Tabela de Roteamento com a Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Permite SSH (seu IP) e porta 3000 (publica)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH do meu IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_ip]
  }

  ingress {
    description = "Porta 3000 da aplicacao"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.environment}-web-sg"
    Curso    = "Infraestrutura como Codigo"
    Ambiente = var.environment
    Projeto  = "terraform_ansible"
  }
}

# Instância EC2
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  tags = {
    Name     = "${var.environment}-web-server"
    Curso    = "Infraestrutura como Codigo"
    Ambiente = var.environment
    Projeto  = "terraform_ansible"
  }
}

# Recurso para executar o Ansible localmente
resource "null_resource" "run_ansible" {
  depends_on = [aws_instance.web]

  provisioner "local-exec" {
    command = <<EOT
      echo "Aguardando a instancia ficar pronta para SSH (90 segundos)..."
      sleep 90
      echo "Executando Ansible playbook..."
      cd ../ansible && \
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i ${aws_instance.web.public_ip}, \
                       -u ec2-user \
                       --private-key ${var.private_key_path} \
                       --vault-password-file vault_pass.txt \
                       playbook.yml
    EOT
  }

  triggers = {
    instance_id = aws_instance.web.id
  }
}
  triggers = {
    instance_id = aws_instance.web.id
  }
}
