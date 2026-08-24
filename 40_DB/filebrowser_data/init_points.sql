-- =========================================================
-- Robot Point Database
-- Run this script once for every robot-specific point database,
-- for example: ur5_points or ld90_points.
-- =========================================================

DROP TABLE IF EXISTS Point;

CREATE TABLE Point
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    robot_prefix TEXT NOT NULL,
    short_name TEXT NOT NULL,
    pose_kind TEXT NOT NULL,
    frame_id INTEGER NOT NULL,

    x DOUBLE PRECISION NOT NULL,
    y DOUBLE PRECISION NOT NULL,
    z DOUBLE PRECISION,
    rx DOUBLE PRECISION,
    ry DOUBLE PRECISION,
    rz DOUBLE PRECISION,
    theta DOUBLE PRECISION,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_point_prefix_name UNIQUE (robot_prefix, short_name),

    CONSTRAINT chk_point_pose_kind CHECK
    (
        (pose_kind = 'POSE_3D'
            AND z IS NOT NULL
            AND rx IS NOT NULL
            AND ry IS NOT NULL
            AND rz IS NOT NULL
            AND theta IS NULL)
        OR
        (pose_kind = 'POSE_2D'
            AND z IS NULL
            AND rx IS NULL
            AND ry IS NULL
            AND rz IS NULL
            AND theta IS NOT NULL)
    )
);

CREATE INDEX ix_point_short_name ON Point(short_name);

CREATE OR REPLACE FUNCTION update_point_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_point_updated_at
BEFORE UPDATE ON Point
FOR EACH ROW
EXECUTE FUNCTION update_point_timestamp();