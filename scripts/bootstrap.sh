#!/bin/bash
set -e

echo "=========================================="
echo " BOOTSTRAP - Criando infraestrutura base"
echo "=========================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Criar bucket S3
echo -e "\n${YELLOW}Criando bucket S3...${NC}"
BUCKET_NAME="danilo-terraform-backend-2026"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region us-east-1 \
        --create-bucket-configuration LocationConstraint=us-east-1
    echo -e "${GREEN}Bucket criado: $BUCKET_NAME${NC}"
else
    echo -e "${YELLOW}Bucket já existe: $BUCKET_NAME${NC}"
fi

# 2. Versão do bucket
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# 3. Criar tabela DynamoDB
echo -e "\n${YELLOW}🗄️ Criando tabela DynamoDB...${NC}"
TABLE_NAME="terraform-locks"
if aws dynamodb describe-table --table-name $TABLE_NAME 2>&1 | grep -q 'ResourceNotFoundException'; then
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region us-east-1
    echo -e "${GREEN}Tabela criada: $TABLE_NAME${NC}"
else
    echo -e "${YELLOW}Tabela já existe: $TABLE_NAME${NC}"
fi

# 4. Esperar a tabela ficar ativa
echo -e "\n${YELLOW}Aguardando tabela ficar ativa...${NC}"
aws dynamodb wait table-exists --table-name $TABLE_NAME
echo -e "${GREEN}Tabela pronta!${NC}"

# 5. Criar Key Pair (se não existir)
echo -e "\n${YELLOW}Verificando Key Pair...${NC}"
KEY_NAME="danilo-key"
if aws ec2 describe-key-pairs --key-name $KEY_NAME 2>&1 | grep -q 'InvalidKeyPair.NotFound'; then
    aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query 'KeyMaterial' \
        --output text > ~/.ssh/$KEY_NAME.pem
    chmod 400 ~/.ssh/$KEY_NAME.pem
    echo -e "${GREEN}Key Pair criado: $KEY_NAME${NC}"
else
    echo -e "${YELLOW}Key Pair já existe: $KEY_NAME${NC}"
fi

echo -e "\n${GREEN}=========================================="
echo "BOOTSTRAP CONCLUÍDO COM SUCESSO!"
echo "==========================================${NC}"
