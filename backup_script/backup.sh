#!/bin/bash
# Script de Backup Avançado com S3 Upload   ########################
#                                                                  #
#Instale AWS CLI: pip install awscli                               #
#Configure credenciais: aws configure                              #
#Edite backup.conf com suas configurações                          #
#Execute: chmod +x backup.sh && ./backup.sh                        #
#O script age automaticamente conforme configurado em backup.conf  #
####################################################################


# Configurações
SOURCE_DIR="/var/www/html"
LOCAL_BACKUP_DIR="/backup"
LOG_FILE="/var/log/backup.log"
S3_BUCKET="s3://meu-bucket-backup"
S3_PREFIX="backups"
RETENTION_DAYS=7
MAX_LOCAL_BACKUPS=5

# Variáveis dinâmicas
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILENAME="backup-${TIMESTAMP}.tar.gz"
LOCAL_FILE_PATH="${LOCAL_BACKUP_DIR}/${BACKUP_FILENAME}"
S3_FILE_PATH="${S3_BUCKET}/${S3_PREFIX}/${BACKUP_FILENAME}"

# Função de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Função de tratamento de erro
handle_error() {
    log "ERRO: $1"
    exit 1
}

# Função de verificação de dependências
check_dependencies() {
    command -v aws >/dev/null 2>&1 || handle_error "AWS CLI não encontrado. Instale com: pip install awscli"
    command -v tar >/dev/null 2>&1 || handle_error "tar não encontrado"
}

# Função para criar diretórios
create_directories() {
    [ ! -d "$LOCAL_BACKUP_DIR" ] && mkdir -p "$LOCAL_BACKUP_DIR"
    [ ! -d "$(dirname "$LOG_FILE")" ] && mkdir -p "$(dirname "$LOG_FILE")"
}

# Função para verificar espaço em disco
check_disk_space() {
    local required_space=$(du -sb "$SOURCE_DIR" | cut -f1)
    local available_space=$(df -B1 "$LOCAL_BACKUP_DIR" | awk 'NR==2 {print $4}')
    
    if [ "$required_space" -gt "$available_space" ]; then
        handle_error "Espaço em disco insuficiente. Necessário: ${required_space} bytes, Disponível: ${available_space} bytes"
    fi
}

# Função para criar backup local
create_backup() {
    log "Iniciando backup do diretório: $SOURCE_DIR"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        handle_error "Diretório fonte $SOURCE_DIR não encontrado"
    fi
    
    if tar -czf "$LOCAL_FILE_PATH" "$SOURCE_DIR" 2>/dev/null; then
        local file_size=$(du -h "$LOCAL_FILE_PATH" | cut -f1)
        log "Backup local criado com sucesso: $LOCAL_FILE_PATH ($file_size)"
        return 0
    else
        handle_error "Falha ao criar backup local"
    fi
}

# Função para verificar integridade do backup
verify_backup() {
    if tar -tzf "$LOCAL_FILE_PATH" >/dev/null 2>&1; then
        log "Integridade do backup verificada com sucesso"
        return 0
    else
        handle_error "Backup corrompido ou inválido"
    fi
}

# Função para upload para S3
upload_to_s3() {
    log "Iniciando upload para S3: $S3_FILE_PATH"
    
    if aws s3 cp "$LOCAL_FILE_PATH" "$S3_FILE_PATH" --storage-class STANDARD_IA 2>/dev/null; then
        log "Upload para S3 concluído com sucesso"
        
        # Adicionar tag de data ao objeto S3
        aws s3api put-object-tagging \
            --bucket "$(echo "$S3_BUCKET" | sed 's|s3://||')" \
            --key "${S3_PREFIX}/${BACKUP_FILENAME}" \
            --tagging "Key=BackupDate,Value=${TIMESTAMP}" \
            2>/dev/null && log "Tags adicionadas ao objeto S3"
        
        return 0
    else
        handle_error "Falha no upload para S3"
    fi
}

# Função para limpar backups locais antigos
cleanup_local_backups() {
    log "Limpando backups locais antigos (mantendo $MAX_LOCAL_BACKUPS mais recentes)"
    
    cd "$LOCAL_BACKUP_DIR" || handle_error "Não foi possível acessar $LOCAL_BACKUP_DIR"
    
    local backup_count=$(ls -1 backup-*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$MAX_LOCAL_BACKUPS" ]; then
        ls -1t backup-*.tar.gz | tail -n +$((MAX_LOCAL_BACKUPS + 1)) | xargs -r rm
        log "Limpeza local concluída. Removidos $((backup_count - MAX_LOCAL_BACKUPS)) backups"
    fi
}

# Função para limpar backups S3 antigos
cleanup_s3_backups() {
    log "Limpando backups S3 antigos (mais de $RETENTION_DAYS dias)"
    
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y%m%d)
    
    aws s3 ls "$S3_BUCKET/$S3_PREFIX/" 2>/dev/null | \
    awk -v prefix="$S3_PREFIX/" -v cutoff="$cutoff_date" '
    $NF ~ /^backup-[0-9]{8}_[0-9]{6}\.tar\.gz$/ {
        match($NF, /backup-([0-9]{8})_[0-9]{6}\.tar\.gz/, parts);
        if (parts[1] < cutoff) {
            print prefix $NF;
        }
    }' | \
    while read -r file; do
        aws s3 rm "$S3_BUCKET/$file" 2>/dev/null && log "Removido backup antigo: $file"
    done
}

# Função para gerar relatório
generate_report() {
    local local_size=$(du -sh "$LOCAL_BACKUP_DIR" 2>/dev/null | cut -f1 || echo "0")
    local s3_count=$(aws s3 ls "$S3_BUCKET/$S3_PREFIX/" 2>/dev/null | wc -l)
    
    log "=== RELATÓRIO DE BACKUP ==="
    log "Arquivo: $BACKUP_FILENAME"
    log "Tamanho local: $(du -h "$LOCAL_FILE_PATH" | cut -f1)"
    log "Espaço usado local: $local_size"
    log "Backups no S3: $s3_count"
    log "Backup concluído com sucesso!"
    log "========================="
}

# Função principal
main() {
    log "=== INÍCIO DO PROCESSO DE BACKUP ==="
    
    # Verificações iniciais
    check_dependencies
    create_directories
    check_disk_space
    
    # Processo de backup
    create_backup
    verify_backup
    upload_to_s3
    
    # Limpeza
    cleanup_local_backups
    cleanup_s3_backups
    
    # Relatório final
    generate_report
    
    log "=== PROCESSO DE BACKUP CONCLUÍDO ==="
}

# Execução principal
main "$@"