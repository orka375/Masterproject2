# VS Code + WSL + Docker + PostgreSQL Workflow

This guide explains how to create and manage Docker containers from WSL, mount a Windows workspace into containers, connect VS Code to running containers, rebuild Docker images, and use PostgreSQL with Docker.

---

# 1. Start WSL and Docker

## Open WSL Ubuntu 24.04

Start Ubuntu from Windows:

- Windows Start Menu → **Ubuntu 24.04**
- Or from PowerShell:

```bash
wsl
```

Check Docker:

```bash
docker --version
```

---

# 2. Manage Existing Containers

## List running containers

```bash
docker ps
```

## List all containers

```bash
docker ps -a
```

## Start a stopped container

```bash
docker start mycontainer
```

Check:

```bash
docker ps
```

---

# 3. Create a Docker Container with Windows Workspace Mounted

Example Windows workspace:

```
C:\Users\Fabian\OneDrive - Berner Fachhochschule\Desktop\Masterproject\20_ROS
```

Inside WSL:

```
/mnt/c/Users/Fabian/OneDrive - Berner Fachhochschule/Desktop/Masterproject/20_ROS
```

Create container:

```bash
docker run -d \
  --name mycontainer \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "/mnt/c/Users/Fabian/OneDrive - Berner Fachhochschule/Desktop/Masterproject/20_ROS:/ros2_ws" \
  starrynight:latest \
  tail -f /dev/null
```

Explanation:

| Option | Purpose |
|-|-|
| `--name` | Container name |
| `-v host:path` | Mount Windows folder |
| `-e DISPLAY` | GUI forwarding |
| `tail -f /dev/null` | Keep container running |

---

# 4. Enter a Running Container

```bash
docker exec -it mycontainer bash
```

Check location:

```bash
pwd
```

---

# 5. Verify Workspace Mount

Inside container:

```bash
ls -la /ros2_ws
```

Check mounts:

```bash
docker inspect mycontainer
```

or:

```bash
docker inspect mycontainer \
-f '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
```

Example:

```
/mnt/c/Users/Fabian/.../20_ROS -> /ros2_ws
```

---

# 6. Connect VS Code to Container

Install extensions:

- Remote - WSL
- Dev Containers

Open VS Code:

```
Ctrl + Shift + P
```

Select:

```
Dev Containers: Attach to Running Container
```

Choose:

```
mycontainer
```

Open:

```
/ros2_ws
```

---

# 7. Modify Dockerfile

Example:

```dockerfile
FROM ubuntu:24.04

RUN apt update && apt install -y \
    python3 \
    python3-pip \
    bash

WORKDIR /ros2_ws

CMD ["bash"]
```

---

# 8. Build a New Image

From the Dockerfile folder:

```bash
docker build -t starrynight:new .
```

List images:

```bash
docker images
```

---

# 9. Rebuild After Changes

Force rebuild:

```bash
docker build --no-cache -t starrynight:new .
```

Remove old container:

```bash
docker stop mycontainer
docker rm mycontainer
```

Create new container:

```bash
docker run -d \
  --name mycontainer \
  starrynight:new \
  tail -f /dev/null
```

---

# 10. PostgreSQL with Docker

## PostgreSQL Container Concept

A PostgreSQL setup usually contains:

```
PostgreSQL Container
        |
        |
        +---- Database files (volume)
        |
        +---- Port 5432
        |
        +---- pgAdmin Web Interface
```

Typical setup:

```
postgres_db_container
        |
        | port 5432
        |
        PostgreSQL Database


postgres_db_gui_container
        |
        | port 8080
        |
        pgAdmin Web Interface
```

---

# 11. PostgreSQL Docker Compose Example

Create:

```
docker-compose.yml
```

Example:

```yaml
services:

  db:
    image: postgres:18.4
    container_name: postgres_db_container
    restart: unless-stopped

    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: 1
      POSTGRES_DB: robotdata

    volumes:
      - ./postgres_data:/var/lib/postgresql
      - ./40_DB/init.sql:/docker-entrypoint-initdb.d/init.sql

    ports:
      - "5432:5432"


  db_gui:
    image: dpage/pgadmin4
    container_name: postgres_db_gui_container
    restart: unless-stopped

    environment:
      PGADMIN_DEFAULT_EMAIL: user@example.com
      PGADMIN_DEFAULT_PASSWORD: 1

    ports:
      - "8080:80"
```

Start:

```bash
docker compose up -d
```

Check:

```bash
docker ps
```

---

# 12. Access PostgreSQL

## From terminal inside container

Enter database container:

```bash
docker exec -it postgres_db_container bash
```

Open PostgreSQL:

```bash
psql -U admin -d robotdata
```

---

# 13. Important PostgreSQL Commands

## List databases

Inside psql:

```sql
\l
```

## Connect to database

```sql
\c robotdata
```

## List tables

```sql
\dt
```

## Describe table

```sql
\d table_name
```

Example:

```sql
\d robot
```

## Show data

```sql
SELECT * FROM table_name;
```

Example:

```sql
SELECT * FROM robots;
```

## Exit PostgreSQL

```sql
\q
```

---

# 14. PostgreSQL URLs

## pgAdmin Web Interface

Open browser:

```
http://localhost:8080
```

Login:

```
Email:
user@example.com

Password:
1
```

---

## PostgreSQL Connection

From local computer:

```
Host:
localhost

Port:
5432

Database:
robotdata

User:
admin

Password:
1
```

Example connection URL:

```
postgresql://admin:1@localhost:5432/robotdata
```

---

# 15. Add PostgreSQL Server in pgAdmin

Open:

```
http://localhost:8080
```

Login.

Create:

```
Servers
  |
  +-- Register
          |
          +-- Server
```

General:

```
Name:
robot_database
```

Connection:

```
Host name/address:
db

Port:
5432

Maintenance database:
robotdata

Username:
admin

Password:
1
```

Important:

Inside Docker, use:

```
db
```

not:

```
localhost
```

because containers communicate using service names.

---

# 16. Find PostgreSQL Data Location

## Check Docker volumes

```bash
docker volume ls
```

## Inspect container mounts

```bash
docker inspect postgres_db_container
```

Example:

```
./postgres_data
        |
        |
        /var/lib/postgresql
```

The database files are stored in:

```
./postgres_data
```

relative to your docker-compose.yml file.

---

# 17. Initialize Database with SQL File

Example:

Folder:

```
project/
|
+-- docker-compose.yml
|
+-- 40_DB/
|     |
|     +-- init.sql
|
+-- postgres_data/
```

The SQL file is executed only on the first database initialization:

```yaml
- ./40_DB/init.sql:/docker-entrypoint-initdb.d/init.sql
```

Example:

```sql
CREATE TABLE robots
(
    id SERIAL PRIMARY KEY,
    name TEXT,
    status TEXT
);
```

---

# 18. PostgreSQL Troubleshooting

## Container restarting

Check logs:

```bash
docker logs postgres_db_container
```

---

## Database was already initialized

Message:

```
PostgreSQL Database directory appears to contain a database; Skipping initialization
```

Means:

- init.sql will NOT run again
- Existing database is reused

Solution:

Remove database volume:

```bash
docker compose down

rm -rf postgres_data
```

Then restart:

```bash
docker compose up -d
```

WARNING:

This deletes the database.

---

## PostgreSQL 18 volume error

Error:

```
/var/lib/postgresql/data contains data
```

For PostgreSQL 18 use:

```yaml
volumes:
  - ./postgres_data:/var/lib/postgresql
```

not:

```yaml
- ./postgres_data:/var/lib/postgresql/data
```

---

## Permission error

Example:

```
could not change permissions
Operation not permitted
```

Fix permissions:

Linux/WSL:

```bash
sudo chown -R 999:999 postgres_data
```

or recreate:

```bash
docker compose down

rm -rf postgres_data

docker compose up -d
```

---

# 19. Daily PostgreSQL Workflow

Start:

```bash
docker compose up -d
```

Check:

```bash
docker ps
```

Open pgAdmin:

```
http://localhost:8080
```

Enter database:

```bash
docker exec -it postgres_db_container bash
```

Connect:

```bash
psql -U admin -d robotdata
```

Check tables:

```sql
\dt
```

Query:

```sql
SELECT * FROM robots;
```

---

# 20. Stop Everything

Stop containers:

```bash
docker compose down
```

Keep database data:

```
postgres_data/
```

Delete everything:

```bash
docker compose down -v
```

WARNING:

This removes database volumes.

---

# Typical Daily Workflow

## Start working

```bash
wsl

docker start mycontainer

docker compose up -d
```

Open VS Code:

```
Dev Containers → Attach to Running Container
```

Open:

```
/ros2_ws
```

Open database:

```
http://localhost:8080
```

---

## After Dockerfile changes

```bash
docker build --no-cache -t starrynight:new .

docker stop mycontainer

docker rm mycontainer

docker run -d \
  --name mycontainer \
  starrynight:new \
  tail -f /dev/null
```

---

## After database changes

Restart:

```bash
docker compose restart
```

Reset database:

```bash
docker compose down

rm -rf postgres_data

docker compose up -d
```