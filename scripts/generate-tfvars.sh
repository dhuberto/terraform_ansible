#!/bin/bash
set -e

echo "=========================================="
echo "Gerando terraform.tfvars"
echo "=========================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Pega o IP público
IP=$(curl -s https://checkip.amazonaws.com)
echo -e "${YELLOW}📡 IP público: $IP${NC}"

# Pega o nome do Key Pair
KEY_NAME=$(aws ec2 describe-key-pairs --query 'KeyPairs[0].KeyName' --output text)
if [ -z "$KEY_NAME" ]; then
    echo "Nenhum Key Pair encontrado na AWS. Execute o bootstrap.sh primeiro."
    exit 1
fi
echo -e "${YELLOW}Key Pair: $KEY_NAME${NC}"

# Gera o arquivo terraform.tfvars
cat > ~/terraform_ansible/terraform/terraform.tfvars << EOF
ssh_allowed_ip   = "$IP/32"
key_name         = "$KEY_NAME"
private_key_path = "~/.ssh/$KEY_NAME.pem"
bucket_name      = "danilo-terraform-backend-2026"
aws_region       = "us-east-1"
EOF

echo -e "${GREEN}terraform.tfvars criado com sucesso!${NC}"
echo "------------------------------------------"
cat ~/terraform_ansible/terraform/terraform.tfvars
echo "------------------------------------------"
