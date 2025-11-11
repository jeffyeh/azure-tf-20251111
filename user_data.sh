#!/bin/bash
# User data script to initialize the VM with Docker, Nginx, and other services

set -e

echo "=== Starting VM initialization ==="

# Update system packages
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install Docker Compose (standalone)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install Nginx
apt-get install -y nginx

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

# Install Node.js (optional, for application services)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install git
apt-get install -y git

# Install htop and other useful tools
apt-get install -y htop curl wget nano vim

# Create application directory
mkdir -p /opt/app

# Create nginx configuration directory for SSL
mkdir -p /etc/nginx/ssl

# Create nginx reverse proxy config template
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    # SSL certificates (replace with your certificate paths)
    ssl_certificate /etc/nginx/ssl/certificate.pem;
    ssl_certificate_key /etc/nginx/ssl/private-key.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Reverse proxy to backend services
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check endpoint
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test nginx configuration
nginx -t

# Create docker-compose template for MongoDB cluster
cat > /opt/app/docker-compose-mongodb.yml <<'EOF'
version: '3.8'

services:
  mongo1:
    image: mongo:7.0
    container_name: mongo1
    command: mongod --replSet rs0 --bind_ip 0.0.0.0
    ports:
      - "27017:27017"
    networks:
      - mongo-network
    volumes:
      - mongo1-data:/data/db

  mongo2:
    image: mongo:7.0
    container_name: mongo2
    command: mongod --replSet rs0 --bind_ip 0.0.0.0
    ports:
      - "27018:27017"
    networks:
      - mongo-network
    volumes:
      - mongo2-data:/data/db
    depends_on:
      - mongo1

  mongo3:
    image: mongo:7.0
    container_name: mongo3
    command: mongod --replSet rs0 --bind_ip 0.0.0.0
    ports:
      - "27019:27017"
    networks:
      - mongo-network
    volumes:
      - mongo3-data:/data/db
    depends_on:
      - mongo1

networks:
  mongo-network:
    driver: bridge

volumes:
  mongo1-data:
  mongo2-data:
  mongo3-data:
EOF

# Initialize MongoDB replica set (run after MongoDB containers are up)
cat > /opt/app/init-mongo-replica.sh <<'EOF'
#!/bin/bash
docker exec mongo1 mongosh --eval "
rs.initiate({
  _id: 'rs0',
  members: [
    {_id: 0, host: 'mongo1:27017'},
    {_id: 1, host: 'mongo2:27017'},
    {_id: 2, host: 'mongo3:27017'}
  ]
})"
EOF

chmod +x /opt/app/init-mongo-replica.sh

echo "=== VM initialization completed ==="
echo "Docker, Docker Compose, Nginx, and Node.js have been installed"
echo "MongoDB docker-compose template is ready at /opt/app/docker-compose-mongodb.yml"
echo ""
echo "Next steps:"
echo "1. Upload your SSL certificates to /etc/nginx/ssl/"
echo "2. Update nginx configuration with your domain and backend service port"
echo "3. Deploy MongoDB cluster: docker compose -f /opt/app/docker-compose-mongodb.yml up -d"
echo "4. Initialize replica set: /opt/app/init-mongo-replica.sh"
echo "5. Deploy your application using Docker containers"
