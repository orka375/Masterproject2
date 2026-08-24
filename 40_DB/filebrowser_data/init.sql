-- =========================================================
-- Robot Plant Database
-- PostgreSQL Version
-- =========================================================


-- =========================================================
-- CLEAN DATABASE OBJECTS
-- =========================================================

DROP TABLE IF EXISTS RobotTool;
DROP TABLE IF EXISTS CoordSys;
DROP TABLE IF EXISTS Robot;
DROP TABLE IF EXISTS Plant;



-- =========================================================
-- TABLE DEFINITIONS
-- =========================================================


CREATE TABLE Plant
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name TEXT NOT NULL,

    description TEXT,

    -- Array of robot IDs belonging to this plant
    robots JSONB
);



CREATE TABLE Robot
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    name TEXT NOT NULL,

    manufacturer TEXT,

    model TEXT,

    robot_type TEXT,

    axes INTEGER,

    payload DOUBLE PRECISION,

    reach DOUBLE PRECISION,

    controller TEXT,

    ip_address INET
);



CREATE TABLE RobotTool
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    robot_id INTEGER NOT NULL,

    name TEXT NOT NULL,


    -- TCP position

    tcp_x DOUBLE PRECISION,
    tcp_y DOUBLE PRECISION,
    tcp_z DOUBLE PRECISION,


    -- TCP orientation

    tcp_rx DOUBLE PRECISION,
    tcp_ry DOUBLE PRECISION,
    tcp_rz DOUBLE PRECISION,


    weight DOUBLE PRECISION,


    -- Center of gravity

    cog_x DOUBLE PRECISION,
    cog_y DOUBLE PRECISION,
    cog_z DOUBLE PRECISION,


    CONSTRAINT fk_tool_robot
        FOREIGN KEY(robot_id)
        REFERENCES Robot(id)
        ON DELETE CASCADE
);



CREATE TABLE CoordSys
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    plant_id INTEGER NOT NULL,

    name TEXT NOT NULL,


    x DOUBLE PRECISION,
    y DOUBLE PRECISION,
    z DOUBLE PRECISION,


    rx DOUBLE PRECISION,
    ry DOUBLE PRECISION,
    rz DOUBLE PRECISION,


    CONSTRAINT fk_coordsys_plant
        FOREIGN KEY(plant_id)
        REFERENCES Plant(id)
        ON DELETE CASCADE
);



-- =========================================================
-- ROBOTS
-- =========================================================


INSERT INTO Robot
(
name,
manufacturer,
model,
robot_type,
axes,
payload,
reach,
controller,
ip_address
)
VALUES
(
'UR5e_01',
'Universal Robots',
'UR5e',
'Collaborative Robot',
6,
5,
850,
'UR Controller',
'192.168.10.10'
);



INSERT INTO Robot
(
name,
manufacturer,
model,
robot_type,
axes,
payload,
reach,
controller,
ip_address
)
VALUES
(
'ABB_IRB1200_01',
'ABB',
'IRB 1200',
'Industrial Robot',
6,
7,
900,
'IRC5',
'192.168.10.20'
);



INSERT INTO Robot
(
name,
manufacturer,
model,
robot_type,
axes,
payload,
reach,
controller,
ip_address
)
VALUES
(
'KUKA_KR210_01',
'KUKA',
'KR210',
'Industrial Robot',
6,
210,
2700,
'KRC4',
'192.168.10.30'
);



INSERT INTO Robot
(
name,
manufacturer,
model,
robot_type,
axes,
payload,
reach,
controller,
ip_address
)
VALUES
(
'UR5_ETA_01',
'Universal Robots',
'UR5',
'Collaborative Robot',
6,
5,
850,
'UR Controller',
'192.168.20.10'
);



-- =========================================================
-- PLANTS
-- =========================================================


INSERT INTO Plant
(
name,
description,
robots
)
VALUES
(
'BFH Plant',
'Test and development plant with ABB, KUKA and UR robots',
'[1,2,3]'::jsonb
);



INSERT INTO Plant
(
name,
description,
robots
)
VALUES
(
'ETA Plant',
'Test and development plant',
'[4]'::jsonb
);



-- =========================================================
-- ROBOT TOOLS
-- =========================================================


-- UR5e SCHUNK gripper

INSERT INTO RobotTool
(
robot_id,
name,

tcp_x,
tcp_y,
tcp_z,

tcp_rx,
tcp_ry,
tcp_rz,

weight,

cog_x,
cog_y,
cog_z
)
VALUES
(
1,
'SCHUNK_PG160_01',

0,
0,
150,

180,
0,
0,

1.8,

0,
0,
75
);



-- ABB gripper

INSERT INTO RobotTool
VALUES
(
DEFAULT,
2,
'ABB_Gripper_01',

0,
0,
220,

180,
0,
0,

3.2,

0,
0,
110
);



-- KUKA gripper

INSERT INTO RobotTool
VALUES
(
DEFAULT,
3,
'KUKA_Gripper_01',

0,
0,
300,

180,
0,
0,

12.5,

0,
0,
150
);



-- ETA UR5 vacuum tool

INSERT INTO RobotTool
VALUES
(
DEFAULT,
4,
'VacuumTool_01',

0,
0,
120,

180,
0,
0,

1.2,

0,
0,
60
);



-- =========================================================
-- COORDINATE SYSTEMS
-- =========================================================


INSERT INTO CoordSys
(
plant_id,
name,

x,
y,
z,

rx,
ry,
rz
)
VALUES
(
1,
'MachineZero',

1500,
500,
0,

0,
0,
0
);



INSERT INTO CoordSys
(
plant_id,
name,

x,
y,
z,

rx,
ry,
rz
)
VALUES
(
1,
'RobotCell_A',

0,
0,
0,

0,
0,
0
);



INSERT INTO CoordSys
(
plant_id,
name,

x,
y,
z,

rx,
ry,
rz
)
VALUES
(
2,
'ETA_TestBench',

500,
200,
0,

0,
0,
90
);



-- =========================================================
-- TEST QUERIES
-- =========================================================

-- List robots with plant
/*
SELECT
    Plant.name AS plant,
    Robot.name AS robot,
    Robot.manufacturer,
    Robot.model
FROM Plant
JOIN Robot
ON Robot.id = ANY
(
    SELECT jsonb_array_elements_text(Plant.robots)::INTEGER
);
*/


-- =========================================================
-- END
-- =========================================================