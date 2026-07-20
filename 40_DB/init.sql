CREATE TABLE RobotTool (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    tcp_x REAL,
    tcp_y REAL,
    tcp_z REAL,
    tcp_rx REAL,
    tcp_ry REAL,
    tcp_rz REAL,
    weight REAL,
    cog_x REAL,
    cog_y REAL,
    cog_z REAL
);

CREATE TABLE CoordSys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    x REAL,
    y REAL,
    z REAL,
    rx REAL,
    ry REAL,
    rz REAL
);

INSERT INTO RobotTool
(name,tcp_x,tcp_y,tcp_z,tcp_rx,tcp_ry,tcp_rz,weight,cog_x,cog_y,cog_z)
VALUES
('Gripper_01',0,0,180,180,0,0,2.35,0,0,90);

INSERT INTO CoordSys
(name,x,y,z,rx,ry,rz)
VALUES
('MachineZero',1500,500,0,0,0,0);
