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

```bash
time docker compose up -d
[+] Running 5/5
 ✔ Network n8n_network         Created                                                                                                                                                    0.1s 
 ✔ Volume "n8n_data"           Created                                                                                                                                                    0.0s 
 ✔ Volume "n8n_postgres_data"  Created                                                                                                                                                    0.0s 
 ✔ Container n8n-db-1          Healthy                                                                                                                                                    5.7s 
 ✔ Container n8n-n8n-1         Started                                                                                                                                                    5.9s 

real    0m6.134s
user    0m0.075s
sys     0m0.062s
```
```bash
docker compose ps
NAME        IMAGE         COMMAND                  SERVICE   CREATED          STATUS                             PORTS
n8n-db-1    postgres:17   "docker-entrypoint.s…"   db        46 seconds ago   Up 46 seconds (healthy)            5432/tcp
n8n-n8n-1   n8nio/n8n     "tini -- /docker-ent…"   n8n       46 seconds ago   Up 40 seconds (health: starting)   0.0.0.0:5678->5678/tcp, :::5678->5678/tcp
```

## 2. Verify Setup

1. Check container logs

```
docker compose logs n8n
docker compose logs db
```

2. Check container health status
```
# View running containers and health status
docker compose ps

# Check n8n health
docker inspect n8n-n8n-1 --format "{{.State.Health.Status}}"

# Check PostgreSQL health
docker inspect n8n-db-1 --format "{{.State.Health.Status}}"
```

3. Test database connectivity
```
# Connect to PostgreSQL and check version
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SELECT version();"

# Check PostgreSQL connections
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "\conninfo"

# List PostgreSQL databases
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -c "\l"
```

```bash
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SELECT version();"
                                                       version                                                       
---------------------------------------------------------------------------------------------------------------------
 PostgreSQL 17.0 (Debian 17.0-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
(1 row)


docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "\conninfo"
You are connected to database "n8n" as user "n8n" via socket in "/var/run/postgresql" at port "5432".

docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -c "\l"
                                                 List of databases
   Name    | Owner | Encoding | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules | Access privileges 
-----------+-------+----------+-----------------+------------+------------+--------+-----------+-------------------
 n8n       | n8n   | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | 
 postgres  | n8n   | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | 
 template0 | n8n   | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/n8n           +
           |       |          |                 |            |            |        |           | n8n=CTc/n8n
 template1 | n8n   | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/n8n           +
           |       |          |                 |            |            |        |           | n8n=CTc/n8n
(4 rows)
```

4. Test n8n API health
```
# Using curl from host
curl -I http://localhost:5678/healthz
```
```
# Using wget inside n8n container
docker exec n8n-n8n-1 wget --spider -q http://localhost:5678/healthz
```

```bash
curl -I http://localhost:5678/healthz
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 15
ETag: W/"f-VaSQ4oDUiZblZNAEkkN+sX+q3Sg"
Date: Sun, 03 Nov 2024 03:49:24 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```
```bash
docker inspect n8n-n8n-1 --format "{{.State.Health.Status}}"
healthy
```

5. Check network connectivity

```
# List networks
docker network ls | grep n8n
```
```bash
docker network ls | grep n8n
dfc9a550c481   n8n_network       bridge    local
```
```
# Inspect n8n network
docker network inspect n8n_network
```
6. Check resource usage
```
docker stats n8n-n8n-1 n8n-db-1 --no-stream
```
```bash
docker stats n8n-n8n-1 n8n-db-1 --no-stream
CONTAINER ID   NAME        CPU %     MEM USAGE / LIMIT   MEM %     NET I/O           BLOCK I/O        PIDS
f58284967ac5   n8n-n8n-1   0.38%     106MiB / 3.48GiB    2.98%     24.7kB / 24.3kB   4.1kB / 0B       13
8ab178b53693   n8n-db-1    6.96%     53.62MiB / 2GiB     2.62%     759kB / 605kB     823kB / 61.2MB   7
```

7. Verify volumes
```
docker volume ls | grep n8n
docker volume inspect n8n_data
docker volume inspect n8n_postgres_data
```

8. Check PostgreSQL configuration
```
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SHOW max_connections;"
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SHOW shared_buffers;"
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SHOW effective_cache_size;"
```
```bash
docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SHOW max_connections;"
 max_connections 
-----------------
 100
(1 row)

docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SHOW shared_buffers;"
 shared_buffers 
----------------
 512MB
(1 row)

docker exec n8n-db-1 psql -U ${DB_POSTGRESDB_USER} -d ${DB_POSTGRESDB_DATABASE} -c "SHOW effective_cache_size;"
 effective_cache_size 
----------------------
 1536MB
(1 row)
```

## 3. Troubleshoot n8n service container

Check n8n logs for error messages

```bash
docker compose logs n8n
```

Check if n8n process is running inside container

```bash
docker exec n8n-n8n-1 ps aux | grep n8n
```

Check network binding inside container

```bash
docker exec n8n-n8n-1 netstat -tlpn
```

Check if n8n can connect to database

```bash
docker exec n8n-n8n-1 nc -zv db 5432
```

View detailed container health check history

```bash
docker inspect -f '{{json .State.Health}}' n8n-n8n-1 | jq .
```

Check environment variables

```bash
docker exec n8n-n8n-1 env | grep N8N_
```

Check listening ports

```bash
docker exec n8n-n8n-1 ss -tlpn
```