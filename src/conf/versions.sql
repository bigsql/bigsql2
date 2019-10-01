DROP TABLE IF EXISTS versions;
DROP TABLE IF EXISTS releases;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS stages;

CREATE TABLE stages (
  stage       TEXT    NOT NULL PRIMARY KEY
);
INSERT INTO stages VALUES ('prod');
INSERT INTO stages VALUES ('test');


CREATE TABLE categories (
  category    INTEGER NOT NULL PRIMARY KEY,
  description TEXT    NOT NULL
);
INSERT INTO categories VALUES (0, 'Hidden');
INSERT INTO categories VALUES (1, 'PostgreSQL');
INSERT INTO categories VALUES (2, 'Extensions');
INSERT INTO categories VALUES (3, 'Servers');
INSERT INTO categories VALUES (4, 'Applications');


CREATE TABLE projects (
  project   	 TEXT    NOT NULL PRIMARY KEY,
  category  	 INTEGER NOT NULL,
  port      	 INTEGER NOT NULL,
  depends   	 TEXT    NOT NULL,
  start_order    INTEGER NOT NULL,
  homepage_url   TEXT    NOT NULL,
  short_desc     TEXT    NOT NULL,
  FOREIGN KEY (category) REFERENCES categories(category)
);
INSERT INTO projects VALUES ('hub', 0, 0, 'hub', 0, 'http://bigsql.org', 'API for PG (APG)');

INSERT INTO projects VALUES ('pg', 1, 5432, 'hub', 1, 'http://postgresql.org', 'Advanced RDBMS');

INSERT INTO projects VALUES ('plprofiler', 2, 0, 'hub', 0, 'https://github.com/bigsql/plprofiler', 'PLpg/SQL Profiler');
INSERT INTO projects VALUES ('cassandra_fdw', 2, 0, 'hub', 0, 'http://cassandrafdw.org', 'Cassandra Foreign Data Wrapper');
INSERT INTO projects VALUES ('athena_fdw', 2, 0, 'hub', 0, 'https://github.com/bigsql/athena_fdw', 'Hive/Athena Foreign Data Wrapper');
INSERT INTO projects VALUES ('timescaledb', 2, 0, 'hub', 0, 'https://github.com/bigsql/apache_timescaledb', 'Timeseries Extension');
INSERT INTO projects VALUES ('pglogical', 2, 0, 'hub', 0, 'https://github.com/2ndQuadrant/pglogical', 'Logical Replication');
INSERT INTO projects VALUES ('pgspock', 2, 0, 'hub', 0, 'https://github.com/bigsql/pgspock', 'Logical Bi-Directional Replication');
INSERT INTO projects VALUES ('pgtsql', 2, 0, 'hub', 0, '', '');

INSERT INTO projects VALUES ('pip',  4,    0, 'hub', 0, '',                                  '');
INSERT INTO projects VALUES ('salt', 3, 4505, 'hub', 0, 'https://github.com/saltstack/salt', 'Cluster Mgmt in the Cloud');


CREATE TABLE releases (
  component  TEXT    NOT NULL PRIMARY KEY,
  project    TEXT    NOT NULL,
  disp_name  TEXT    NOT NULL,
  short_desc TEXT    NOT NULL,
  sup_plat   TEXT    NOT NULL,
  doc_url    TEXT    NOT NULL,
  stage      TEXT    NOT NULL,
  FOREIGN KEY (project) REFERENCES projects(project),
  FOREIGN KEY (stage)   REFERENCES stages(stage)
);
INSERT INTO releases VALUES ('hub', 'hub', 'Hidden', 'Hidden', '',  '', 'prod');

INSERT INTO releases VALUES ('pg10', 'pg', 'PostgreSQL 10',  'PG Server (bigsql)', '', 'http://www.postgresql.org/docs/10/', 'prod');
INSERT INTO releases VALUES ('pg11', 'pg', 'PostgreSQL 11',  'PG Server (bigsql)', '', 'http://www.postgresql.org/docs/11/', 'prod');
INSERT INTO releases VALUES ('pg12', 'pg', 'PostgreSQL 12',  'PG Server (bigsql)', '', 'http://www.postgresql.org/docs/12/', 'prod');

INSERT INTO releases VALUES ('pgtsql-pg10', 'pgtsql', 'pgTSQL', 'Transact SQL like', '', '', 'prod');

INSERT INTO releases VALUES ('pgspock-pg10', 'pgspock', 'pgSpock', 'Logical Bi-Directional Replication', '', '', 'prod');
INSERT INTO releases VALUES ('pgspock-pg11', 'pgspock', 'pgSpock', 'Logical Bi-Directional Replication', '', '', 'prod');

INSERT INTO releases VALUES ('pglogical-pg10', 'pglogical', 'pgLogical', 'Logical Replication', '', '', 'prod');
INSERT INTO releases VALUES ('pglogical-pg11', 'pglogical', 'pgLogical', 'Logical Replication', '', '', 'prod');

INSERT INTO releases VALUES ('plprofiler-pg11', 'plprofiler', 'plProfiler', 'Procedural Language Performance Profiler', '', 'https://github.com/bigsql/plprofiler', 'prod');

INSERT INTO releases VALUES ('timescaledb-pg10', 'timescaledb', 'TimescaleDB', '', '', '', 'prod');
INSERT INTO releases VALUES ('timescaledb-pg11', 'timescaledb', 'TimescaleDB', '', '', '', 'prod');

INSERT INTO releases VALUES ('cassandra_fdw-pg11', 'cassandra_fdw', 'CassandraFDW', 'C* Interoperability', '', '', 'prod');

INSERT INTO releases VALUES ('athena_fdw-pg11', 'athena_fdw', 'AthenaFDW', 'Hive Queries', '', '', 'prod');

INSERT INTO releases VALUES ('pip',  'pip',   '', '', '', '', 'test');
INSERT INTO releases VALUES ('salt', 'salt',  '', '', '', '', 'test');


CREATE TABLE versions (
  component     TEXT    NOT NULL,
  version       TEXT    NOT NULL,
  platform      TEXT    NOT NULL,
  is_current    INTEGER NOT NULL,
  release_date  DATE    NOT NULL,
  parent        TEXT    NOT NULL,
  PRIMARY KEY (component, version),
  FOREIGN KEY (component) REFERENCES releases(component)
);

INSERT INTO versions VALUES ('hub', '5.0.0', '', 1, '20191003', '');

INSERT INTO versions VALUES ('pg10', '10.10-1', 'linux64', 1, '20190926', '');

INSERT INTO versions VALUES ('pg11', '11.5-1', 'linux64', 1, '20190808', '');

INSERT INTO versions VALUES ('pg12', '12.0-1', 'linux64', 1, '20191003', '');

INSERT INTO versions VALUES ('pgtsql-pg10', '2.0.2-1',  'linux64', 1, '20191003', 'pg10');

INSERT INTO versions VALUES ('pgspock-pg10', '2.3.1-1',  'linux64', 1, '20191003', 'pg10');
INSERT INTO versions VALUES ('pgspock-pg11', '2.3.1-1',  'linux64', 1, '20191003', 'pg11');

INSERT INTO versions VALUES ('pglogical-pg10', '2.2.2-1',  'linux64', 1, '20191003', 'pg10');
INSERT INTO versions VALUES ('pglogical-pg11', '2.2.2-1',  'linux64', 1, '20191003', 'pg11');

INSERT INTO versions VALUES ('plprofiler-pg11', '4.1-1', 'linux64', 1, '20191003', 'pg11');

INSERT INTO versions VALUES ('timescaledb-pg10', '1.4.2-1', 'linux64', 1, '20191003', 'pg10');
INSERT INTO versions VALUES ('timescaledb-pg11', '1.4.2-1', 'linux64', 1, '20191003', 'pg11');

INSERT INTO versions VALUES ('cassandra_fdw-pg11', '3.1.4-1', 'linux64', 0, '20190808', 'pg11');

INSERT INTO versions VALUES ('athena_fdw-pg11', '3.1-2', 'linux64', 0, '20190708', 'pg11');

INSERT INTO versions VALUES ('salt', '2019pp', 'linux64', 0, '20190912', '');

INSERT INTO versions VALUES ('pip', '19pp', 'linux64', 0, '20190912', '');

