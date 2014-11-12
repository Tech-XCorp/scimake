# - FindTxDagmc: Module to find include directories and
#   libraries for Dagmc.
#
# Module usage:
#   find_package(TxDagmc ...)
#
# This module will define the following variables:
#  HAVE_DAGMC, DAGMC_FOUND = Whether libraries and includes are found
#  Dagmc_INCLUDE_DIRS       = Location of Dagmc includes
#  Dagmc_LIBRARY_DIRS       = Location of Dagmc libraries
#  Dagmc_LIBRARIES          = Required libraries

###########################################################
#
# Find module for Dagmc installation
#
# $Id$
#
# Copyright 2010-2012 Tech-X Corporation.
# All rights reserved.
#
###########################################################

if (DEFINED DAGMC_DIR)
  message(STATUS "[FindDagmc.cmake] - DAGMC_DIR is ${DAGMC_DIR}")
endif ()

# We have a problem in SciFindPackage
# where if the executable has the same name as a directory
# scimake's find_program() will return the DIRECTORY instead
# of the executable on windows (as scimake is a windows program
# and the cygwin soft link just looks like a file).
# So as a temporary hack-fix, we only look for dagmcser
SciFindPackage(
  PACKAGE Dagmc
  PROGRAMS remsim
)

if (DAGMC_FOUND)
  message(STATUS "Found Dagmc")
  set(HAVE_DAGMC 1 CACHE BOOL "Whether have Dagmc")

  get_filename_component(DAGMC_DIR ${Dagmc_PROGRAM_DIRS}/.. REALPATH)
  if (DEBUG_CMAKE)
    message(STATUS "DAGMC_DIR is ${DAGMC_DIR}")
  endif ()

  if (DEBUG_CMAKE)
    message("Trying to run executable ${Dagmc_gpuSpinTrack} to determine Dagmc version.")
  endif ()

# Dagmc_VERSION is required by SciComposerBase.cmake to set the package
# installer name.  It is provided by executing "executable --version",
# and contains version number/revision number.
  include(${TXCMAKE_DIR}/TxEngFindVersion.cmake)
  TxEngFindVersion(${Dagmc_remsim} EXE_VERSION EXE_REVISION)
  set(Dagmc_VERSION ${EXE_VERSION})
  set(DAGMC_VERSION ${EXE_VERSION})
  set(Dagmc_REVISION ${EXE_REVISION})
else ()
  message(STATUS "Dagmc not found. Use -DDAGMC_DIR to specify the installation directory.")
  if (TxDagmc_FIND_REQUIRED)
    message(FATAL_ERROR "Failed.")
  endif ()
  set(Dagmc_VERSION "Dagmc-NOTFOUND")
  set(Dagmc_REVISION "Dagmc-NOTFOUND")
endif ()
