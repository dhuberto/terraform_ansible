#!/bin/bash
set -e

echo "=========================================="
echo "DESTRUINDO TODOS OS RECURSOS"
echo "=========================================="

echo ""
echo "ATENCAO: Isso vai destruir TODOS os recursos da AWS!"
read -p "Tem certeza? (digite 'sim' para confirmar): " CONFIRMATION

if [ "$CONFIRMATION" != "sim" ]; then
    echo "Operacao cancelada."
    exit 1
fi

# 1. Destruir recursos do Terraform
echo ""
echo "Destruindo recursos do Terraform..."
cd ~/terraform_ansible/terraform

# DEV
echo "  - Destruindo workspace dev..."
terraform workspace select dev 2>/dev/null || true
terraform destroy -auto-approve -lock=false

# PROD
echo "  - Destruindo workspace prod..."
terraform workspace select prod 2>/dev/null || true
terraform destroy -auto-approve -lock=false

echo "Recursos do Terraform destruidos!"

# 2. Remover bucket S3
echo ""
echo "Removendo bucket S3..."
BUCKET_NAME="danilo-terraform-backend-2026"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Bucket ja nao existe: $BUCKET_NAME"
else
    aws s3 rb s3://$BUCKET_NAME --force
    echo "Bucket removido: $BUCKET_NAME"
fi

# 3. Remover tabela DynamoDB
echo ""
echo "Removendo tabela DynamoDB..."
TABLE_NAME="terraform-locks"
if aws dynamodb describe-table --table-name $TABLE_NAME 2>&1 | grep -q 'ResourceNotFoundException'; then
    echo "Tabela ja nao existe: $TABLE_NAME"
else
    aws dynamodb delete-table --table-name $TABLE_NAME
    echo "Tabela removida: $TABLE_NAME"
fi

# 4. Remover Key Pair da AWS
echo ""
echo "Removendo Key Pair da AWS..."
KEY_NAME="danilo-key"
if aws ec2 describe-key-pairs --key-name $KEY_NAME 2>&1 | grep -q 'InvalidKeyPair.NotFound'; then
    echo "Key Pair ja nao existe: $KEY_NAME"
else
    aws ec2 delete-key-pair --key-name $KEY_NAME
    echo "Key Pair removido: $KEY_NAME"
fi

# 5. Remover chave privada local
echo ""
echo "Removendo chave privada local..."
rm -f ~/.ssh/$KEY_NAME.pem
echo "Chave privada removida"

# 6. Remover estado local do Terraform
echo ""
echo "Removendo estado local do Terraform..."
cd ~/terraform_ansible/terraform
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform
echo "Estado local removido"

echo ""
echo "=========================================="
echo "DESTRUICAO COMPLETA CONCLUIDA!"
echo "=========================================="
echo ""
echo "Para recriar tudo:"
echo "  make setup"
