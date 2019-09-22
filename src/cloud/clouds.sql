

CREATE TABLE clouds (
  cloud_id      SERIAL  NOT NULL PRIMARY_KEY,
  cloud_name    TEXT    NOT NULL
);
INSERT INTO clouds VALUES
  (1, 'aws');


CREATE TABLE regions
  region_id     SERIAL     NOT NULL PRIMARY KEY,
  cloud_id      INTEGER    NOT NULL REFERENCES(clouds.cloud_id),
  region_name   TEXT       NOT NULL
);
INSERT INTO regions VALUES
  (1, 1, 'us-east-1'), 
  (2, 1, 'us-east-2');
  (3, 1, 'us-west-1');
  (4, 1, 'us-west-2');


CREATE TABLE images
  image_id           SERIAL  NOT NULL PRIMARY KEY,
  region_id          INTEGER NOT NULL REFERENCES(regions.region_id),
  image_description  TEXT  NOT NULL,
  image_name         TEXT  NOT NULL
)
  (1, 4, 'Amazon Linux 2 AMI (HVM) - SSD Volume Type', 'ami-04b762b4289fba92b'),
  (2, 4, 'Ubuntu Server 18.04 LTS (HVM) - SSD Volume Type', 'ami-04b762b4289fba92b');


CREATE TABLE zones
  zone_id            SERIAL   PRIMARY KEY,
  region_id          INTEGER  NOT NULL REFERENCES(regions.region_id),
  zone_name          TEXT     NOT NULL
);
INSERT INTO zones VALUES
  (1, 1, 'us-east-1a'), 
  (2, 1, 'us-east-1b');


CREATE TABLE types (
  type_id           INTEGER PRIMARY KEY,
  cloud_id          INTEGER NOT NULL REFERENCES(clouds.cloud_id),
  type_name         TEXT    NOT NULL,
  v_cpu             INTEGER NOT NULL,
  memory_gib        INTEGER NOT NULL,
  storge_gb         INTEGER NOT NULL,
  instance_storage  TEXT    NOT NULL,
  network           TEXT    NOT NULL
);
INSERT INTO types
  (1, 1, 'm5d.large',     2,   8,   75, '1 x 75  (SSD)', 'up to 10 Gigabit'),
  (2, 1, 'm5d.xlarge',    4,  16,  150, '1 x 150 (SSD)', 'up to 10 Gigabit'),
  (3, 1, 'm5d.2xlarge',   8,  32,  300, '1 x 300 (SSD)', 'up to 10 Gigabit'),
  (4, 1, 'm5d.4xlarge',  16,  64,  600, '2 x 300 (SSD)', 'up to 10 Gigabit'),
  (5, 1, 'm5d.12xlarge', 48, 192, 1800, '2 x 900 (SSD)', '10 Gigabit'),
  (6, 1, 'm5d.24xlarge', 96, 384, 3600, '4 x 900 (SSD)', '20 Gigabit');


CREATE TABLE instances
  instance_id        INTEGER PRIMARY KEY,
  zone_id            INTEGER NOT NULL REFERENCES (zones.zone_id),
  instance_name      TEXT,
  type_id            INTEGER      NOT NULL REFERENCES (instance_types.instance_type_id),
  instance_state     TEXT         NOT NULL,
  launch_time        TIMESTAMP    WITH TIMEZONE NOT NULL,
  status_checks      TEXT,
  alarm_status       TEXT,
  public_dns         TEXT,
  public_ip          TEXT,
  private_dns        TEXT,
  private_ips        TEXT
);


CREATE VIEW v_instances
  SELECT i.instance_id, i.zone_id , i.instance_name , i.type_id
       , t.cloud_id, t.type_name, t.v_cpu, t.memory_gib
       , t.storage_gb, t.instance_storage, t.network
       , z.region_id, z.zone_name
       , r.region_name, r.cloud_id
       , m.image_description, m.image_name
       , c.cloud_name
    FROM instances i, types t, zones z, regions r, clouds c
   WHERE i.type_id   = t.type_id
     AND i.zone_id   = z.zone_id
     AND z.region_id = r.region_id
     AND r.cloud_id  = c.cloud_id
     AND r.region_id = m.region_id;

