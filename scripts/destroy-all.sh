#!/bin/bash
set -e

echo "=========================================="
echo "DESTRUINDO TODOS OS RECURSOS"
echo "=========================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Confirmar destruição
echo -e "${RED}⚠️ ATENÇÃO: Isso vai destruir TODOS os recursos da AWS!${NC}"
read -p "Tem certeza? (digite 'sim' para confirmar): " CONFIRMATION

if [ "$CONFIRMATION" != "sim" ]; then
    echo "Operação cancelada."
    exit 1
fi

# 1. Destruir recursos do Terraform
echo -e "\n${YELLOW} Destruindo recursos do Terraform...${NC}"
cd ~/terraform_ansible/terraform

# DEV
echo -e "${YELLOW}  - Destruindo workspace dev...${NC}"
terraform workspace select dev 2>/dev/null || true
terraform destroy -auto-approve -lock=false

# PROD
echo -e "${YELLOW}  - Destruindo workspace prod...${NC}"
terraform workspace select prod 2>/dev/null || true
terraform destroy -auto-approve -lock=false

echo -e "${GREEN}Recursos do Terraform destruídos!${NC}"

# 2. Remover bucket S3
echo -e "\n${YELLOW}Removendo bucket S3...${NC}"
BUCKET_NAME="danilo-terraform-backend-2026"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo -e "${YELLOW}Bucket já não existe: $BUCKET_NAME${NC}"
else
    aws s3 rb s3://$BUCKET_NAME --force
    echo -e "${GREEN}Bucket removido: $BUCKET_NAME${NC}"
fi

# 3. Remover tabela DynamoDB
echo -e "\n${YELLOW}Removendo tabela DynamoDB...${NC}"
TABLE_NAME="terraform-locks"
if aws dynamodb describe-table --table-name $TABLE_NAME 2>&1 | grep -q 'ResourceNotFoundException'; then
    echo -e "${YELLOW}Tabela já não existe: $TABLE_NAME${NC}"
else
    aws dynamodb delete-table --table-name $TABLE_NAME
    echo -e "${GREEN}Tabela removida: $TABLE_NAME${NC}"
fi

# 4. Remover Key Pair da AWS
echo -e "\n${YELLOW}Removendo Key Pair da AWS...${NC}"
KEY_NAME="danilo-key"
if aws ec2 describe-key-pairs --key-name $KEY_NAME 2>&1 | grep -q 'InvalidKeyPair.NotFound'; then
    echo -e "${YELLOW}Key Pair já não existe: $KEY_NAME${NC}"
else
    aws ec2 delete-key-pair --key-name $KEY_NAME
    echo -e "${GREEN}Key Pair removido: $KEY_NAME${NC}"
fi

# 5. Remover chave privada local
echo -e "\n${YELLOW}Removendo chave privada local...${NC}"
rm -f ~/.ssh/$KEY_NAME.pem
echo -e "${GREEN}Chave privada removida${NC}"

# 6. Remover estado local do Terraform
echo -e "\n${YELLOW}Removendo estado local do Terraform...${NC}"
cd ~/terraform_ansible/terraform
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform
echo -e "${GREEN}Estado local removido${NC}"

echo -e "\n${GREEN}=========================================="
echo "DESTRUIÇÃO COMPLETA CONCLUÍDA!"
echo "=========================================="
echo -e "${YELLOW}Para recriar tudo:"
echo "  make setup${NC}"
