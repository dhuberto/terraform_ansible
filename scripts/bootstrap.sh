#!/bin/bash
set -e

echo "=========================================="
echo "BOOTSTRAP - Criando infraestrutura base"
echo "=========================================="

# 1. Criar bucket S3
echo ""
echo "Criando bucket S3..."
BUCKET_NAME="danilo-terraform-backend-2026"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region us-east-1
    echo "Bucket criado: $BUCKET_NAME"
else
    echo "Bucket ja existe: $BUCKET_NAME"
fi

# 2. Versao do bucket
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# 3. Criar tabela DynamoDB
echo ""
echo "Criando tabela DynamoDB..."
TABLE_NAME="terraform-locks"
if aws dynamodb describe-table --table-name $TABLE_NAME 2>&1 | grep -q 'ResourceNotFoundException'; then
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region us-east-1
    echo "Tabela criada: $TABLE_NAME"
else
    echo "Tabela ja existe: $TABLE_NAME"
fi

# 4. Esperar a tabela ficar ativa
echo ""
echo "Aguardando tabela ficar ativa..."
aws dynamodb wait table-exists --table-name $TABLE_NAME
echo "Tabela pronta!"

# 5. Criar Key Pair (se nao existir)
echo ""
echo "Verificando Key Pair..."
KEY_NAME="danilo-key"
if aws ec2 describe-key-pairs --key-name $KEY_NAME 2>&1 | grep -q 'InvalidKeyPair.NotFound'; then
    aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query 'KeyMaterial' \
        --output text > ~/.ssh/$KEY_NAME.pem
    chmod 400 ~/.ssh/$KEY_NAME.pem
    echo "Key Pair criado: $KEY_NAME"
else
    echo "Key Pair ja existe: $KEY_NAME"
fi

# 6. Verificar se a chave privada existe
if [ ! -f ~/.ssh/$KEY_NAME.pem ]; then
    echo "Chave privada nao encontrada: ~/.ssh/$KEY_NAME.pem"
    echo "Criando chave novamente..."
    aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --query 'KeyMaterial' \
        --output text > ~/.ssh/$KEY_NAME.pem
    chmod 400 ~/.ssh/$KEY_NAME.pem
    echo "Chave criada: ~/.ssh/$KEY_NAME.pem"
fi

# 7. Verificar permissao da chave
echo ""
echo "Verificando permissao da chave..."
chmod 400 ~/.ssh/$KEY_NAME.pem
ls -la ~/.ssh/$KEY_NAME.pem

echo ""
echo "=========================================="
echo "BOOTSTRAP CONCLUIDO COM SUCESSO!"
echo "=========================================="
echo ""
echo "Recursos criados:"
echo "  - Bucket S3: $BUCKET_NAME"
echo "  - Tabela DynamoDB: $TABLE_NAME"
echo "  - Key Pair: $KEY_NAME"
echo "  - Chave privada: ~/.ssh/$KEY_NAME.pem"
