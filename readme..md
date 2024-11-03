* https://docs.n8n.io/hosting/installation/server-setups/docker-compose/

## 1. System Preparation

### Update System
```bash
sudo dnf update -y
sudo dnf upgrade -y
```

### Install Required Packages
```bash
# Install basic requirements
sudo dnf install -y dnf-utils yum-utils
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y git curl wget nano python3 python3-pip

# Install Docker dependencies
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
    "dns": ["172.18.0.1", "1.1.1.1", "8.8.8.8"],
    "dns-opts": ["ndots:1"],
    "dns-search": ["k6-support"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker --no-pager -l
```