variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_ip" {
  description = "Seu IP público (formato x.x.x.x/32)"
  type        = string
}

variable "key_name" {
  description = "Nome do par de chaves SSH na AWS"
  type        = string
}

variable "private_key_path" {
  description = "Caminho para a chave privada SSH"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev ou prod)"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Bucket S3 para state remoto"
  type        = string
}
