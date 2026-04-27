# Script de Backup Avançado com S3

Um script robusto de backup que cria backups locais e os sincroniza com Amazon S3, incluindo limpeza automática, verificação de integridade e relatórios detalhados.

## 🚀 Recursos

- ✅ Backup local com compressão tar.gz
- ✅ Upload automático para Amazon S3
- ✅ Verificação de integridade dos backups
- ✅ Limpeza automática de backups antigos (local e S3)
- ✅ Logging detalhado com timestamps
- ✅ Verificação de espaço em disco
- ✅ Tratamento robusto de erros
- ✅ Relatórios de execução
- ✅ Configuração flexível via arquivo externo
- ✅ Tags S3 para organização

## 📋 Pré-requisitos

### 1. AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Ou via pip
pip install awscli
```

### 2. Configurar Credenciais AWS
```bash
aws configure
# Digite sua Access Key ID, Secret Access Key, região e formato de saída
```

### 3. Permissões Necessárias
O usuário/role AWS precisa ter as seguintes permissões no bucket S3:
- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`
- `s3:ListBucket`
- `s3:PutObjectTagging`

## ⚙️ Configuração

### 1. Editar o Arquivo de Configuração
```bash
nano backup.conf
```

Configure as seguintes variáveis:
- `SOURCE_DIR`: Diretório que será feito backup
- `S3_BUCKET`: Seu bucket S3 (ex: `s3://meu-bucket-backup`)
- `RETENTION_DAYS`: Dias para manter backups no S3
- `MAX_LOCAL_BACKUPS`: Máximo de backups locais

### 2. Configurações S3 Opcionais
- `S3_STORAGE_CLASS`: `STANDARD`, `STANDARD_IA`, `GLACIER`
- `S3_PREFIX`: Pasta dentro do bucket

## 🔧 Uso

### Execução Manual
```bash
# Tornar executável
chmod +x backup.sh

# Executar backup
./backup.sh
```

### Agendamento com Cron
```bash
# Editar crontab
crontab -e

# Adicionar linha para backup diário às 2:00 AM
0 2 * * * /caminho/completo/backup.sh

# Backup semanal aos domingos às 3:00 AM
0 3 * * 0 /caminho/completo/backup.sh
```

## 📁 Estrutura de Arquivos

```
.
├── backup.sh          # Script principal
├── backup.conf        # Arquivo de configuração
└── README.md          # Este documento
```

## 📊 Logs e Relatórios

O script gera logs detalhados em `/var/log/backup.log`:
- Timestamps em todas as operações
- Verificação de integridade
- Status de uploads S3
- Operações de limpeza
- Relatório final com estatísticas

### Exemplo de Log
```
[2024-04-27 14:30:15] === INÍCIO DO PROCESSO DE BACKUP ===
[2024-04-27 14:30:15] Iniciando backup do diretório: /var/www/html
[2024-04-27 14:30:45] Backup local criado com sucesso: /backup/backup-20240427_143045.tar.gz (245M)
[2024-04-27 14:30:45] Integridade do backup verificada com sucesso
[2024-04-27 14:31:20] Upload para S3 concluído com sucesso
[2024-04-27 14:31:21] Tags adicionadas ao objeto S3
[2024-04-27 14:31:21] === RELATÓRIO DE BACKUP ===
[2024-04-27 14:31:21] Arquivo: backup-20240427_143045.tar.gz
[2024-04-27 14:31:21] Tamanho local: 245M
[2024-04-27 14:31:21] Espaço usado local: 735M
[2024-04-27 14:31:21] Backups no S3: 12
[2024-04-27 14:31:21] Backup concluído com sucesso!
[2024-04-27 14:31:21] =========================
[2024-04-27 14:31:21] === PROCESSO DE BACKUP CONCLUÍDO ===
```

## 🔍 Verificação e Monitoramento

### Verificar Backups no S3
```bash
# Listar backups no S3
aws s3 ls s3://meu-bucket-backup/backups/

# Verificar tags de um backup específico
aws s3api get-object-tagging --bucket meu-bucket-backup --key backups/backup-20240427_143045.tar.gz
```

### Verificar Logs
```bash
# Verificar logs em tempo real
tail -f /var/log/backup.log

# Verificar últimos 50 logs
tail -n 50 /var/log/backup.log

# Filtrar erros
grep "ERRO" /var/log/backup.log
```

## 🛠️ Solução de Problemas

### Erros Comuns

#### 1. "AWS CLI não encontrado"
```bash
# Verificar instalação
which aws

# Reinstalar se necessário
pip install --upgrade awscli
```

#### 2. "Espaço em disco insuficiente"
- Aumente o espaço ou diminua `MAX_LOCAL_BACKUPS`
- Verifique se há arquivos grandes que podem ser excluídos

#### 3. "Falha no upload para S3"
- Verifique credenciais AWS: `aws sts get-caller-identity`
- Verifique permissões do bucket
- Verifique conectividade com a internet

#### 4. "Backup corrompido ou inválido"
- Verifique espaço em disco durante o backup
- Verifique se há arquivos com permissões especiais
- Execute manualmente para ver detalhes do erro

### Debug Mode
Para debug avançado, adione `set -x` no início do script:
```bash
#!/bin/bash
set -x
# ... resto do script
```

## 🔐 Segurança

### Boas Práticas
1. **IAM Roles**: Use IAM Roles em vez de chaves de acesso quando possível
2. **Princípio do Menor Privilégio**: Dê apenas as permissões necessárias
3. **Criptografia**: Considere criptografar backups sensíveis
4. **Versionamento**: Habilite versionamento no bucket S3
5. **Logging**: Monitore logs de acesso do S3

### Criptografia de Dados
Para adicionar criptografia GPG, edite `backup.conf`:
```bash
ENABLE_ENCRYPTION=true
GPG_RECIPIENT="email@example.com"
```

## 📈 Performance

### Otimizações
- Use `STANDARD_IA` para backups menos acessados
- Configure `RETENTION_DAYS` adequadamente
- Monitore uso de banda com `BANDWIDTH_LIMIT`
- Use compressão nível 6 (padrão) para bom equilíbrio

### Monitoramento
Monitore os seguintes métricas:
- Tempo de execução do backup
- Tamanho dos backups
- Uso de banda
- Espaço em disco local

## 🔄 Backup e Recovery

### Recuperação de Dados
```bash
# Baixar backup específico do S3
aws s3 cp s3://meu-bucket-backup/backups/backup-20240427_143045.tar.gz ./

# Extrair backup
tar -xzf backup-20240427_143045.tar.gz

# Listar conteúdo sem extrair
tar -tzf backup-20240427_143045.tar.gz
```

### Teste de Recovery
```bash
# Testar backup mais recente
LATEST_BACKUP=$(aws s3 ls s3://meu-bucket-backup/backups/ | sort | tail -n 1 | awk '{print $4}')
aws s3 cp "s3://meu-bucket-backup/backups/$LATEST_BACKUP" /tmp/test-backup.tar.gz
tar -tzf /tmp/test-backup.tar.gz | head -10
```

## 📝 Licença

Este script é fornecido "como está" para uso livre. Modifique conforme necessário para seu ambiente.

## 🤝 Contribuições

Sinta-se à vontade para contribuir com melhorias, correções de bugs ou novas funcionalidades.
