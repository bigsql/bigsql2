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

  if (p_from_ver < "3.2.1") and (p_to_ver >= "3.2.1"):
    APG_HOME = os.getenv('APG_HOME', '')
    try:
      import shutil
      src = os.path.join(os.path.dirname(__file__), "apg.sh")
      dst = os.path.join(APG_HOME, "apg")
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
APG_HOME = os.getenv('APG_HOME', '')
if APG_HOME == '':
  print ("ERROR: Missing APG_HOME envionment variable")
  sys.exit(1)

## gotta have a sqlite database to update
db_local = APG_HOME + os.sep + "conf" + os.sep + "apg_local.db"
cL = sqlite3.connect(db_local)

if __name__ == '__main__':
   mainline()
