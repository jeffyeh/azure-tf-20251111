# Azure Terraform Infrastructure Deployment

此 Terraform 配置會在 Azure 上部署完整的應用服務基礎設施，包括 VM、網路、DNS、Redis 和 Key Vault。

## 架構概覽

```
┌─────────────────────────────────────────┐
│       Azure Resource Group              │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │    Virtual Network (VNet)         │  │
│  │    10.0.0.0/16                    │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │    Subnet                   │  │  │
│  │  │    10.0.1.0/24              │  │  │
│  │  │                             │  │  │
│  │  │  ┌─────────────────────┐   │  │  │
│  │  │  │  Linux VM           │   │  │  │
│  │  │  │  - 8 vCPU           │   │  │  │
│  │  │  │  - 32 GB RAM        │   │  │  │
│  │  │  │  - 256 GB SSD       │   │  │  │
│  │  │  │  - Ubuntu 24.04 LTS │   │  │  │
│  │  │  │                     │   │  │  │
│  │  │  │  Services:          │   │  │  │
│  │  │  │  - Docker           │   │  │  │
│  │  │  │  - Nginx            │   │  │  │
│  │  │  │  - MongoDB Cluster  │   │  │  │
│  │  │  │  - App Services     │   │  │  │
│  │  │  └─────────────────────┘   │  │  │
│  │  │           ↕                 │  │  │
│  │  │  ┌─────────────────────┐   │  │  │
│  │  │  │  Public IP          │   │  │  │
│  │  │  │  (Static)           │   │  │  │
│  │  │  └─────────────────────┘   │  │  │
│  │  │                             │  │  │
│  │  │  ┌─────────────────────┐   │  │  │
│  │  │  │  NSG Rules:         │   │  │  │
│  │  │  │  - HTTP (80)        │   │  │  │
│  │  │  │  - HTTPS (443)      │   │  │  │
│  │  │  │  - SSH (22)         │   │  │  │
│  │  │  └─────────────────────┘   │  │  │
│  │  └─────────────────────────────┘  │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Azure Cache for Redis          │   │
│  │  - 250 MB (Basic)               │   │
│  │  - SSL/TLS 1.2+                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Azure Key Vault                │   │
│  │  - SSL Certificates             │   │
│  │  - Secrets Management           │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  DNS Zone (Optional)            │   │
│  │  - A Records pointing to PIP    │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## 需求

- Terraform >= 1.0
- Azure CLI (az) 已安裝並已登入
- SSH 密鑰對（用於 VM 訪問）

```bash
# 安裝 Terraform
brew install terraform

# 安裝 Azure CLI
brew install azure-cli

# 登入 Azure
az login

# 設置 Azure 訂閱
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

## 資源配置詳情

### 1. **虛擬機 (VM)**
- **規格**: Standard_D8s_v3 (8 vCPU, 32 GB RAM)
- **作業系統**: Ubuntu 24.04 LTS
- **儲存**: 256 GB SSD (Premium_LRS)
- **預裝軟體**:
  - Docker & Docker Compose
  - Nginx
  - Node.js 20.x
  - Git
  
### 2. **公有 IP 位址**
- **類型**: Static (靜態)
- **SKU**: Standard
- **用途**: 對外提供 Web 服務

### 3. **網路設定**
- **VNet**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24
- **NSG 規則**:
  - HTTP (80): 允許所有
  - HTTPS (443): 允許所有
  - SSH (22): 可自訂來源 IP

### 4. **Azure Cache for Redis**
- **層級**: Basic (最低等級)
- **容量**: 250 MB
- **TLS 版本**: 1.2+
- **功能**: 非 SSL 埠已禁用

### 5. **Azure Key Vault**
- **用途**: 儲存 SSL/TLS 憑證和應用程式密鑰

### 6. **DNS (可選)**
- 可在 Azure 中建立 DNS Zone
- 將 DNS A 記錄指向公有 IP

## 使用步驟

### 步驟 1: 準備

1. 生成或取得 SSH 密鑰對:
```bash
# 如果尚無 SSH 密鑰
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# 查看公鑰路徑（對於 Terraform 配置）
cat ~/.ssh/id_rsa.pub
```

2. 複製並編輯變數檔案:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. 編輯 `terraform.tfvars` 並設置您的值:
```hcl
subscription_id       = "your-subscription-id"
ssh_public_key_path   = "~/.ssh/id_rsa.pub"
domain_name           = "your-domain.com"
dns_record_name       = "your-subdomain"
ssh_source_ip         = "YOUR.IP.ADDRESS/32"  # 更改為您的 IP 以提高安全性
```

### 步驟 2: 初始化 Terraform

```bash
# 初始化 Terraform（下載提供商和模組）
terraform init

# 驗證配置文件
terraform validate

# 預覽將要建立的資源
terraform plan
```

### 步驟 3: 部署基礎設施

```bash
# 應用配置（建立資源）
terraform apply

# 確認提示（輸入 yes）
```

### 步驟 4: 驗證部署

```bash
# 取得輸出值
terraform output

# SSH 連線到 VM
ssh -i ~/.ssh/id_rsa azureuser@<PUBLIC_IP>

# 驗證 Docker
docker --version
docker compose version

# 驗證 Nginx
nginx -v
sudo systemctl status nginx

# 檢查 Redis
ping # 測試連線

redis-cli -h <REDIS_HOSTNAME> -p <SSL_PORT> --tls --insecure ping
```

### 步驟 5: 配置 SSL/TLS 憑證

1. **取得 SSL 憑證**（使用 Let's Encrypt 或其他 CA）:
```bash
# 使用 Certbot 和 Let's Encrypt（在 VM 上）
sudo apt-get install certbot python3-certbot-nginx

# 取得憑證
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com
```

2. **將憑證上傳到 Key Vault**（可選）:
```bash
# 在本地建立 PFX 憑證
openssl pkcs12 -export -in /path/to/cert.pem -inkey /path/to/key.pem -out certificate.pfx

# 上傳到 Key Vault
az keyvault certificate import \
  --vault-name <KEY_VAULT_NAME> \
  --name my-certificate \
  --file certificate.pfx
```

3. **配置 Nginx**:
   - 編輯 `/etc/nginx/sites-available/default`
   - 更新 SSL 憑證路徑
   - 重新啟動 Nginx: `sudo systemctl restart nginx`

### 步驟 6: 部署 MongoDB 集群（可選）

在 VM 上執行:
```bash
# 部署 MongoDB 集群
docker compose -f /opt/app/docker-compose-mongodb.yml up -d

# 等待約 10 秒，然後初始化副本集
/opt/app/init-mongo-replica.sh

# 驗證
docker exec mongo1 mongosh --eval "rs.status()"
```

### 步驟 7: 部署應用程式服務

使用 Docker 部署應用:
```bash
# 建立應用 docker-compose 檔案
cat > /opt/app/docker-compose.yml <<EOF
version: '3.8'
services:
  app:
    image: your-app-image:latest
    ports:
      - "3000:3000"
    environment:
      MONGODB_URI: mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0
      REDIS_URL: redis://:<PASSWORD>@<REDIS_HOST>:<SSL_PORT>
    restart: always
EOF

# 啟動應用
docker compose -f /opt/app/docker-compose.yml up -d
```

## DNS 配置

### 方式 1: 在 Azure 中管理 DNS（推薦 - 使用此 Terraform）

1. 設置 `create_dns_zone = true` 在 `terraform.tfvars`
2. 應用 Terraform: `terraform apply`
3. 取得 Azure nameservers: `terraform output dns_nameservers`
4. 在您的域名註冊商設置 nameservers

### 方式 2: 在現有 DNS 提供商中管理

1. 在您的 DNS 提供商（如 GoDaddy、Namecheap 等）建立 A 記錄
2. 將記錄指向公有 IP: `terraform output public_ip_address`

## 成本估算

| 資源 | 成本/月 (大約) | 說明 |
|------|---------------|------|
| VM (D8s_v3) | $400-500 | 8 vCPU, 32GB RAM |
| 公有 IP | $3-5 | 靜態 IP |
| 虛擬網路 | $0 | 前 50 個連線免費 |
| Redis (Basic) | $20-30 | 250 MB |
| Key Vault | $0.6 | 每個保管庫 |
| **總計** | **~$450** | **大約值** |

## 清理資源

若要刪除所有資源並停止計費:

```bash
# 確認將刪除的資源
terraform plan -destroy

# 刪除所有資源
terraform destroy

# 確認提示（輸入 yes）
```

## 故障排除

### 問題: SSH 連線被拒絕
```bash
# 確認安全群組允許您的 IP
# 更新 ssh_source_ip 或暫時設置為 "*"
terraform apply

# 確認密鑰權限
chmod 600 ~/.ssh/id_rsa
```

### 問題: Nginx 啟動失敗
```bash
# SSH 到 VM
ssh -i ~/.ssh/id_rsa azureuser@<IP>

# 檢查配置
sudo nginx -t

# 查看日誌
sudo journalctl -u nginx -n 50
```

### 問題: Redis 連線超時
```bash
# 確認 Redis 正在運行
terraform output redis_cache_hostname
terraform output redis_cache_ssl_port

# 測試連線
redis-cli -h <HOSTNAME> -p <SSL_PORT> --tls --insecure ping
```

### 問題: Terraform 狀態鎖定
```bash
# 如果 Terraform 被鎖定（罕見）
terraform force-unlock <LOCK_ID>
```

## 監控和維護

### 使用 Azure Portal 監控
1. 登入 [Azure Portal](https://portal.azure.com)
2. 瀏覽至您的資源群組
3. 查看 VM 監控、磁碟使用情況、網路流量

### 使用 Azure CLI 監控
```bash
# 查看 VM 狀態
az vm get-instance-view \
  --resource-group <RG_NAME> \
  --name <VM_NAME> \
  --query instanceView.statuses

# 查看 Redis 指標
az redis show \
  --resource-group <RG_NAME> \
  --name <REDIS_NAME>
```

### 常見維護工作
```bash
# 更新系統
sudo apt-get update && sudo apt-get upgrade -y

# 查看磁碟使用情況
df -h

# 查看記憶體使用情況
free -h

# 查看 Docker 容器狀態
docker ps -a

# 檢查 Nginx 日誌
sudo tail -f /var/log/nginx/access.log
```

## 安全最佳實踐

1. **限制 SSH 訪問**:
   - 將 `ssh_source_ip` 設置為特定 IP，而不是 "*"

2. **使用 Azure 密鑰保管庫**:
   - 儲存應用程式密鑰和憑證
   - 不要在代碼中硬編碼秘密

3. **啟用 Azure 防火牆/DDoS 保護** (可選):
   - 在生產環境中添加額外的安全層

4. **定期備份**:
   ```bash
   # 快照 VM 磁碟
   az snapshot create \
     --resource-group <RG_NAME> \
     --name vm-backup-$(date +%Y%m%d) \
     --source <OS_DISK_ID>
   ```

5. **啟用診斷日誌**:
   - 設置應用見解以監控應用程式
   - 設置 NSG 流程日誌用於網路監控

## 擴展和高級配置

### 添加應用程式網關（ALB）
若要添加 Azure Application Gateway 以進行高級路由和 SSL 終止，編輯 `main.tf` 並添加:

```hcl
resource "azurerm_application_gateway" "main" {
  # ... 配置
}
```

### 添加自動縮放
使用 VMSS（虛擬機器規模集）實現多個 VM 的自動縮放。

### 添加 CDN
使用 Azure CDN 加速靜態內容交付。

## 支援和資源

- [Terraform Azure Provider 文檔](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure 文檔](https://docs.microsoft.com/azure/)
- [Terraform 文檔](https://www.terraform.io/docs)

## 許可證

此配置根據 MIT 許可證提供。

## 作者

Created on November 11, 2025
