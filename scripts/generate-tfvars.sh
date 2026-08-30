#!/bin/bash
set -e

echo "=========================================="
echo "Gerando terraform.tfvars"
echo "=========================================="

# Pega o IP publico
IP=$(curl -s https://checkip.amazonaws.com)
echo "IP publico: $IP"

# Forca o uso de vockey
KEY_NAME="vockey"
echo "Key Pair: $KEY_NAME"

# Verifica se a chave existe na AWS
if aws ec2 describe-key-pairs --key-name $KEY_NAME 2>&1 | grep -q 'InvalidKeyPair.NotFound'; then
    echo "ERRO: Key Pair $KEY_NAME nao encontrado na AWS."
    echo "Execute o bootstrap.sh primeiro."
    exit 1
fi

# Verifica se a chave privada existe localmente
if [ ! -f ~/.ssh/$KEY_NAME.pem ]; then
    echo "Chave privada nao encontrada: ~/.ssh/$KEY_NAME.pem"
    echo "Baixando chave $KEY_NAME..."
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ~/.ssh/$KEY_NAME.pem
    chmod 400 ~/.ssh/$KEY_NAME.pem
    echo "Chave baixada: ~/.ssh/$KEY_NAME.pem"
fi

# Gera o arquivo terraform.tfvars
cat > ~/terraform_ansible/terraform/terraform.tfvars << EOF
ssh_allowed_ip   = "$IP/32"
key_name         = "$KEY_NAME"
private_key_path = "$HOME/.ssh/$KEY_NAME.pem"
bucket_name      = "danilo-terraform-backend-2026"
aws_region       = "us-east-1"
EOF

echo ""
echo "terraform.tfvars criado com sucesso!"
echo "------------------------------------------"
cat ~/terraform_ansible/terraform/terraform.tfvars
echo "------------------------------------------"
