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
INSERT INTO projects VALUES ('hub',           0, 0,    'hub', 0, '', '');
INSERT INTO projects VALUES ('pg',            1, 5432, 'hub', 1, '', '');
INSERT INTO projects VALUES ('plprofiler',    2, 0,    'hub', 0, '', '');


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

INSERT INTO releases VALUES ('pg11', 'pg', 'PostgreSQL 11',  'PG Server (bigsql)', '', 'http://www.postgresql.org/docs/11/', 'prod');
INSERT INTO releases VALUES ('pg12', 'pg', 'PostgreSQL 12',  'PG Server (bigsql)', '', 'http://www.postgresql.org/docs/12/', 'prod');

INSERT INTO releases VALUES ('plprofiler-pg11', 'plprofiler', 'plProfiler', 'Procedural Language Performance Profiler', '', 'https://github.com/bigsql/plprofiler', 'prod');

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

INSERT INTO versions VALUES ('hub', '5.0.5', '', 1, '20191201', '');
INSERT INTO versions VALUES ('hub', '5.0.4', '', 1, '20191126', '');
INSERT INTO versions VALUES ('hub', '5.0.3', '', 0, '20191114', '');

INSERT INTO versions VALUES ('pg11', '11.6-1',                'linux64', 1, '20191111', '');

INSERT INTO versions VALUES ('pg12', '12.1-1',                'linux64', 1, '20191111', '');

INSERT INTO versions VALUES ('plprofiler-pg11', '4.1-1',      'linux64', 1, '20191111', 'pg11');

