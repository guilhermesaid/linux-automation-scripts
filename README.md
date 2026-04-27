# Linux Automation Scripts 🐧

Este repositório contém scripts Bash desenvolvidos para automatizar tarefas críticas de administração de sistemas Linux. O foco principal é aumentar a confiabilidade da infraestrutura através de rotinas de proteção de dados e monitoramento preventivo.

##  Conteúdo do Repositório

- `scripts/backup.sh`: Realiza o backup compactado de diretórios estratégicos.
- `scripts/disk-alert.sh`: Monitora o uso de disco e dispara alertas caso o limite seja atingido.

---

## Detalhes dos Scripts

### 1. Script de Backup (`backup.sh`)
Garante a durabilidade dos dados criando arquivos compactados com data e hora.
- **Formato:** `.tar.gz`
- **Destino:** Armazena backups em diretórios definidos e gera logs de sucesso/erro.
- **Uso Comum:** Backup de pastas de configuração (`/etc`) ou dados de aplicação (`/var/www`).

### 2. Alerta de Disco (`disk-alert.sh`)
Implementa uma camada básica de observabilidade para evitar *downtime* por disco cheio.
- **Threshold:** Configurado por padrão para 80%.
- **Ação:** Analisa todas as partições montadas e envia uma notificação via e-mail para o administrador.

---
