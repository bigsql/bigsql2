from __future__ import print_function, division
 
####################################################################
######          Copyright (c)  2015-2019 BigSQL           ##########
####################################################################

import os, sys
import util, startup

pgver = "pg9X"

autostart = util.get_column('autostart', pgver)
if autostart != "on":
  sys.exit(0)

dotver = pgver[2] + "." + pgver[3]
APG_HOME = os.getenv('APG_HOME', '')
svcname   = util.get_column('svcname', pgver, 'PostgreSQL ' + dotver + ' Server')

if util.get_platform() == "Windows":
  sc_path = os.getenv("SYSTEMROOT", "") + os.sep + "System32" + os.sep + "sc"
  command = sc_path + ' delete "' + svcname + '"'
  util.system(command, is_admin=True)
elif util.get_platform() == "Linux":
  startup.remove_linux("postgresql" + pgver[2:4], "85", "15")
