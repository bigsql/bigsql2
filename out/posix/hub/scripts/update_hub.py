from __future__ import print_function, division

####################################################################
########      Copyright (c) 2015-2019 BigSQL           #############
####################################################################

## Include libraries ###############################################
import os
import sys
import sqlite3
import platform

import util

## Set Global variables ############################################
rc = 0

def verify_metadata():
  try:
    c = cL.cursor()
    c.execute("SELECT count(*) FROM sqlite_master WHERE tbl_name = 'settings'")
    data = c.fetchone()
    kount = data[0]
    c.close()
  except Exception as e:
    print("ERROR verify_metadata(): " + str(e.args[0]))
    sys.exit(1)
  if kount == 0:
    update_2_7_0()
    update_3_1_0()
    update_3_1_1()
  return


################ run_sql() #######################################
def run_sql(cmd):
  global rc 
  try:
    c = cL.cursor()
    c.execute(cmd)
    cL.commit()
    c.close()
  except Exception as e:
    if "duplicate column" not in str(e.args[0]):
      print ("")
      print ("ERROR: " + str(e.args[0]))
      print (cmd)
    rc = 1


def update_2_7_0():
  print ("")
  print ("## Updating Metadata to 2.7 ####################")

  run_sql("DROP TABLE IF EXISTS settings")

  run_sql("CREATE TABLE settings ( \n" + \
          "  section            TEXT      NOT NULL, \n" + \
          "  s_key              TEXT      NOT NULL, \n" + \
          "  s_value            TEXT      NOT NULL, \n" + \
          "  PRIMARY KEY (section, s_key) \n" + \
          ")")

  repo = os.getenv('PGC_REPO', 'https://s3.amazonaws.com/pgcentral')
  run_sql("INSERT INTO settings VALUES ('GLOBAL', 'REPO', '" + repo + "')")

  ## default the new PLATFORM variable based on OS 
  ##  (a Linux platform defaults to 'linux64' because platform specific 
  ##   linuxes, like el7-x64, are new as of hub v2.7.0)
  plat_sys = platform.system()
  pf = "linux64"
  if plat_sys == "Darwin":
    pf = "osx64"
  elif plat_sys == "Windows":
    pf = "win64"
  run_sql("INSERT INTO settings VALUES ('GLOBAL', 'PLATFORM', '" + pf + "')")

  return


def update_3_1_0():
  print ("")
  print ("## Updating Metadata to 3.1 ####################")

  run_sql("ALTER TABLE hosts RENAME to hosts_old")

  run_sql("DROP TABLE IF EXISTS hosts")
  run_sql("""CREATE TABLE hosts (
               host_id            INTEGER PRIMARY KEY,
               host               TEXT NOT NULL,
               name               TEXT UNIQUE,
               last_update_utc    DATETIME,
               unique_id          TEXT)""")

  run_sql("""INSERT INTO hosts (host, last_update_utc, unique_id)
             select host,last_update_utc, unique_id from hosts_old limit 1""")

  run_sql("DROP TABLE IF EXISTS hosts_old ")
  return


def update_3_1_1():
  print ("")
  print ("## Updating Metadata to 3.1.1 ##################")
  run_sql("ALTER TABLE components ADD COLUMN svcuser TEXT")
  return


def update_3_3_0():
  print("")
  print("## Updating Metadata to 3.3.0 ##################")
  ## update components table
  run_sql("ALTER TABLE components ADD COLUMN pidfile TEXT")
  return

def mainline():
  ## need from_version & to_version
  if len(sys.argv) == 3:
    p_from_ver = sys.argv[1]
    p_to_ver = sys.argv[2]
  else:
    print ("ERROR: Invalid number of parameters, try: ")
    print ("         python update-hub.py from_version  to_version")
    sys.exit(1)

  print ("")
  print ("Running update-hub from v" + p_from_ver + " to v" + p_to_ver)

  if p_from_ver >= p_to_ver:
    print ("Nothing to do.")
    sys.exit(0)

  if (p_from_ver < "2.7.0") and (p_to_ver >= "2.7.0"):
    update_2_7_0()
  if (p_from_ver < "3.1.0") and (p_to_ver >= "3.1.0"):
    update_3_1_0()
  if (p_from_ver < "3.1.1") and (p_to_ver >= "3.1.1"):
    update_3_1_1()

  if (p_from_ver < "3.2.1") and (p_to_ver >= "3.2.1"):
    PGC_HOME = os.getenv('PGC_HOME', '')
    try:
      import shutil
      src = os.path.join(os.path.dirname(__file__), "pgc.sh")
      dst = os.path.join(PGC_HOME, "pgc")
      if platform.system() == "Windows":
        src = os.path.join(os.path.dirname(__file__), "pgc.bat")
        dst = os.path.join(PGC_HOME, "pgc.bat")
      shutil.copy(src, dst)
    except Exception as e:
      pass

  if (p_from_ver < "3.2.9") and (p_to_ver >= "3.2.9"):
    old_default_repo = "http://s3.amazonaws.com/pgcentral"
    new_default_repo = "https://s3.amazonaws.com/pgcentral"
    current_repo = util.get_value("GLOBAL", "REPO")
    if current_repo == old_default_repo:
      util.set_value("GLOBAL", "REPO", new_default_repo)

  if (p_from_ver < "3.3.0") and (p_to_ver >= "3.3.0"):
    update_3_3_0()

  sys.exit(rc)
  return


###################################################################
#  MAINLINE
###################################################################
PGC_HOME = os.getenv('PGC_HOME', '')
if PGC_HOME == '':
  print ("ERROR: Missing PGC_HOME envionment variable")
  sys.exit(1)

## gotta have a sqlite database to update
db_local = PGC_HOME + os.sep + "conf" + os.sep + "pgc_local.db"
cL = sqlite3.connect(db_local)

if __name__ == '__main__':
   mainline()
