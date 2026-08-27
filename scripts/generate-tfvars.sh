#!/bin/bash
set -e

echo "=========================================="
echo "Gerando terraform.tfvars"
echo "=========================================="

# Pega o IP publico
IP=$(curl -s https://checkip.amazonaws.com)
echo "IP publico: $IP"

# Pega o nome do Key Pair
KEY_NAME=$(aws ec2 describe-key-pairs --query 'KeyPairs[0].KeyName' --output text)
if [ -z "$KEY_NAME" ]; then
    echo "ERRO: Nenhum Key Pair encontrado na AWS. Execute o bootstrap.sh primeiro."
    exit 1
fi
echo "Key Pair: $KEY_NAME"

# Gera o arquivo terraform.tfvars
cat > ~/terraform_ansible/terraform/terraform.tfvars << EOF
ssh_allowed_ip   = "$IP/32"
key_name         = "$KEY_NAME"
private_key_path = "~/.ssh/$KEY_NAME.pem"
bucket_name      = "danilo-terraform-backend-2026"
aws_region       = "us-east-1"
EOF

echo ""
echo "terraform.tfvars criado com sucesso!"
echo "------------------------------------------"
cat ~/terraform_ansible/terraform/terraform.tfvars
echo "------------------------------------------"
