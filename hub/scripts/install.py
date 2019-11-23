##################################################################
########    Copyright (c) 2015-2019 BigSQL         ###############
##################################################################

import sys, os
APG_VER="6.0.0"
APG_REPO=os.getenv("APG_REPO", "https://bigsql-download.s3.amazonaws.com/REPO")
  
if sys.version_info < (2, 6):
  print("ERROR: BigSQL requires Python 2.6 or greater")
  sys.exit(1)

try:
  # For Python 3.0 and later
  from urllib import request as urllib2
except ImportError:
  # Fall back to Python 2's urllib2
  import urllib2

import tarfile

IS_64BITS = sys.maxsize > 2**32
if not IS_64BITS:
  print("ERROR: This is a 32bit machine and BigSQL packages are 64bit.")
  sys.exit(1)

if os.path.exists("bigsql"):
  print("ERROR: Cannot install over an existing 'bigsql' directory.")
  sys.exit(1)

apg_file="bigsql-apg-" + APG_VER + ".tar.bz2"
f = APG_REPO + "/" + apg_file

if not os.path.exists(apg_file):
  print("\nDownloading BigSQL APG " + APG_VER + " ...")
  try:
    fu = urllib2.urlopen(f)
    local_file = open(apg_file, "wb")
    local_file.write(fu.read())
    local_file.close()
  except Exception as e:
    print("ERROR: Unable to download " + f + "\n" + str(e))
    sys.exit(1)

print("\nUnpacking ...")
try:
  tar = tarfile.open(apg_file)
  tar.extractall(path=".")
  print("\nCleaning up")
  tar.close()
  os.remove(apg_file)
except Exception as e:
  print("ERROR: Unable to unpack \n" + str(e))
  sys.exit(1)

print("\nSetting REPO to " + APG_REPO)
apg_cmd = "bigsql" + os.sep + "apg"
os.system(apg_cmd + " set GLOBAL REPO " + APG_REPO)

print("\nBigSQL APG installed.  Try '" + apg_cmd + " help' to get started.\n")

sys.exit(0)

