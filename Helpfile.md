
# VS Code + WSL + Docker + PostgreSQL Workflow

This guide explains the complete workflow for:

- Using Docker from WSL
- Building Docker images
- Running and joining containers
- Mounting Windows workspaces
- Connecting VS Code to containers
- Publishing Docker images to Docker Hub
- Running PostgreSQL with Docker
- Managing databases with pgAdmin and SQL


# 1. Start WSL and Docker

## Open WSL Ubuntu 24.04

Start Ubuntu:

```bash
wsl
````

Check Docker:

```bash
docker --version
```

Check running Docker containers:

```bash
docker ps
```

---

# 2. Docker Workflow

## 2.1 Docker Concepts

Docker uses three main objects:

```
Dockerfile
     |
     v
Docker Image
     |
     v
Docker Container
```

Explanation:

| Object     | Description                     |
| ---------- | ------------------------------- |
| Dockerfile | Instructions to create an image |
| Image      | Packaged environment            |
| Container  | Running instance of an image    |

---

# 3. Create a Docker Image

## 3.1 Create Dockerfile

Example:

```dockerfile
FROM ubuntu:24.04

RUN apt update && apt install -y \
    python3 \
    python3-pip \
    sqlite3 \
    bash

WORKDIR /ros2_ws

CMD ["bash"]
```

Folder:

```
project/
|
+-- Dockerfile
```

---

## 3.2 Build Image

Navigate to Dockerfile folder:

```bash
cd project
```

Build:

```bash
docker build -t starrynight:new .
```

Check images:

```bash
docker images
```

Example:

```
REPOSITORY      TAG
starrynight     new
```

---

# 4. Run a Docker Container

## 4.1 Start Container from Image

Basic:

```bash
docker run -d \
  --name mycontainer \
  starrynight:new \
  tail -f /dev/null
```

Explanation:

| Command             | Purpose              |
| ------------------- | -------------------- |
| `-d`                | Run in background    |
| `--name`            | Container name       |
| `tail -f /dev/null` | Keep container alive |

---

## 4.2 Run Container with Workspace Mount

Windows folder:

```
C:\Users\Fabian\Desktop\Masterproject\20_ROS
```

WSL path:

```
/mnt/c/Users/Fabian/Desktop/Masterproject/20_ROS
```

Run:

```bash
docker run -d \
  --name mycontainer \
  -v "/mnt/c/Users/Fabian/Desktop/Masterproject/20_ROS:/ros2_ws" \
  starrynight:new \
  tail -f /dev/null
```

Inside container:

```
/ros2_ws
```

contains the Windows files.

---

# 5. Join a Running Container

## 5.1 Enter Container

```bash
docker exec -it mycontainer bash
```

Now you are inside Docker.

Check:

```bash
pwd
```

Example:

```
/ros2_ws
```

---

## 5.2 Leave Container

```bash
exit
```

The container keeps running.

---

# 6. Check Containers

## Running Containers

```bash
docker ps
```

## All Containers

```bash
docker ps -a
```

## Start Existing Container

```bash
docker start mycontainer
```

## Stop Container

```bash
docker stop mycontainer
```

## Remove Container

```bash
docker rm mycontainer
```

---

# 7. Connect VS Code to Docker Container

Install:

* Remote - WSL
* Dev Containers

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

# 8. Rebuild Docker Image After Changes

After modifying Dockerfile:

```bash
docker build --no-cache \
-t starrynight:new .
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

# 9. Docker Image Versioning and Docker Hub

## 9.1 Login

```bash
docker login
```

---

## 9.2 Tag Image

Example Docker Hub username:

```
fabian
```

Tag:

```bash
docker tag starrynight:new \
fabian/starrynight:v1.0
```

Check:

```bash
docker images
```

---

## 9.3 Push Image to Docker Hub

```bash
docker push fabian/starrynight:v1.0
```

Image is now available:

```
docker.io/fabian/starrynight:v1.0
```

---

## 9.4 Download Image on Another Computer

Login:

```bash
docker login
```

Pull:

```bash
docker pull fabian/starrynight:v1.0
```

Run:

```bash
docker run -d \
--name mycontainer \
fabian/starrynight:v1.0 \
tail -f /dev/null
```

---

# 10. PostgreSQL Workflow

PostgreSQL consists of:

```
postgres_db_container
          |
          |
          +---- Database files
          |
          +---- Port 5432


postgres_db_gui_container
          |
          |
          +---- pgAdmin
          |
          +---- Port 8080
```

---

# 11. PostgreSQL Docker Compose

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

    container_name:
      postgres_db_gui_container

    restart:
      unless-stopped

    environment:
      PGADMIN_DEFAULT_EMAIL:
        user@example.com

      PGADMIN_DEFAULT_PASSWORD:
        1

    ports:
      - "8080:80"
```

---

# 12. Start PostgreSQL

Start:

```bash
docker compose up -d
```

Check:

```bash
docker ps
```

Logs:

```bash
docker logs postgres_db_container
```

---

# 13. PostgreSQL Connection

## Local Connection

```
Host:
localhost

Port:
5432

Database:
robotdata

Username:
admin

Password:
1
```

Connection string:

```
postgresql://admin:1@localhost:5432/robotdata
```

---

# 14. pgAdmin

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

Add server:

```
Servers
 |
 +-- Register
       |
       +-- Server
```

Connection:

```
Host:
db

Port:
5432

Database:
robotdata

User:
admin

Password:
1
```

Important:

Inside Docker:

```
db
```

not:

```
localhost
```

---

# 15. PostgreSQL Command Line

Enter container:

```bash
docker exec -it postgres_db_container bash
```

Open database:

```bash
psql -U admin -d robotdata
```

---

# 16. Important SQL Commands

List databases:

```sql
\l
```

Connect database:

```sql
\c robotdata
```

List tables:

```sql
\dt
```

Describe table:

```sql
\d robots
```

Show data:

```sql
SELECT * FROM robots;
```

Exit:

```sql
\q
```

---

# 17. Database Initialization

Structure:

```
project
|
+-- docker-compose.yml
|
+-- 40_DB
|     |
|     +-- init.sql
|
+-- postgres_data
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

The file:

```
init.sql
```

runs only during first initialization.

---

# 18. Find PostgreSQL Data

Check mounts:

```bash
docker inspect postgres_db_container
```

Example:

```
./postgres_data
        |
        v
/var/lib/postgresql
```

Database files are stored in:

```
postgres_data/
```

---

# 19. PostgreSQL Troubleshooting

## Database already initialized

Message:

```
PostgreSQL Database directory appears to contain a database; Skipping initialization
```

Meaning:

* Existing database is reused
* init.sql will not execute again

Reset:

```bash
docker compose down

rm -rf postgres_data

docker compose up -d
```

Warning:

This deletes the database.

---

## Permission Error

Example:

```
Operation not permitted
```

Fix:

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

# 20. Daily Workflow

## Start Development

```bash
wsl

docker start mycontainer

docker compose up -d
```

Connect VS Code:

```
Dev Containers
        |
        +-- Attach to Running Container
```

Open:

```
/ros2_ws
```

Database:

```
http://localhost:8080
```

---

# 21. Stop Everything

Stop containers:

```bash
docker compose down
```

Keep database:

```
postgres_data/
```

Remove everything:

```bash
docker compose down -v
```

Warning:

Deletes database volumes.

```
```
