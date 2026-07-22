
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

# 2. Git

## 2.1 Git submodules

Repo clone with submodules
```
git clone --recurse-submodules https://github.com/orka375/Masterproject2.git
```


Initialize submodules
```
git submodule init
```

Clone / update all submodules
```
git submodule update --init --recursive
```

Clone repository with all submodules
```
git clone --recursive <repo_url>
```

Add a submodule
```
git submodule add <repo_url> <path>
```

Add a submodule with a specific branch
```
git submodule add -b <branch> <repo_url> <path>
```

Force add/reuse existing submodule directory
```
git submodule add --force <repo_url> <path>
```

List submodules
```
git submodule
```

Enter every submodule and pull latest changes
```
git submodule foreach git pull
```

Remove a submodule
```
git submodule deinit <path>
git rm <path>
rm -rf .git/modules/<path>
```

Change submodule URL
```
git submodule set-url <path> <new_url>
```

Change submodule branch
```
git config -f .gitmodules submodule.<name>.branch <branch>
```
Pull repository and update submodules
```
git pull --recurse-submodules
git submodule update --init --recursive
```

Check submodule differences
```
git diff --submodule
```

Push repository including submodule commits
```
git push --recurse-submodules=on-demand
```


# 3. Docker

Check (running) Docker containers:

```bash
docker ps
docker ps -a
```
```bash
docker start mycontainer
```
---
Docker Concepts


| Object     | Description                     |
| ---------- | ------------------------------- |
| Dockerfile | Instructions to create an image |
| Image      | Packaged environment            |
| Container  | Running instance of an image    |

---

## 3.1 Create/Join a Docker Image/Container

Build:

```bash
docker build -t starrynight:new .
```

Check images:

```bash
docker images
```
---
Run:

```bash
docker run -d \
  --name mycontainer \
  starrynight:new \
  tail -f /dev/null
```

---

Run Container with Workspace Mount


```bash
docker run -d \
  --name mycontainer \
  -v "/mnt/c/Users/Fabian/Desktop/Masterproject/20_ROS:/ros2_ws" \
  starrynight:new \
  tail -f /dev/null
```

---



Join a Running Container

```bash
docker exec -it mycontainer bash
```

---

---
Tag and Publish Image
```
docker tag myImage:V1 orka375/myImage:V1
docker push orka375/myImage:V1

docker login
docker pull orka375/myImage:V1
```

## 3.2. Rebuild Docker Image After Changes

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



# 4. PostgreSQL

Add postgres to compose.yaml

Start:

```bash
docker compose up -d
```

Logs:

```bash
docker logs postgres_db_container
```

---
Local Connection

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

## 4.1 pgAdmin GUI

```
http://localhost:8080
```

Login:

```
fabian.nachbur@eta.ch
1
```

Add server:

```
Host:
db

Port:
5432

Database:
robotdata

User:
admin (oder progres)

Password:
1
```

Important: Inside Docker: db not localhost


---

## 4.2 Workflow

```bash
docker exec -it postgres_db_container bash
```

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
