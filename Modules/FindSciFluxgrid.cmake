# - FindSciFluxgrid: Module to find include directories and libraries
#   for Fluxgrid. This module was implemented as there is no stock
#   CMake module for Fluxgrid.
#
# This module can be included in CMake builds in find_package:
#   find_package(SciFluxgrid REQUIRED)
#
# This module will define the following variables:
#  HAVE_FLUXGRID         = Whether have the Fluxgrid library
#  Fluxgrid_INCLUDE_DIRS = Location of Fluxgrid includes
#  Fluxgrid_LIBRARY_DIRS = Location of Fluxgrid libraries
#  Fluxgrid_LIBRARIES    = Required libraries
#  Fluxgrid_STLIBS       = Location of Fluxgrid static library

######################################################################
#
# FindSciFluxgrid: find includes and libraries for FLUXGRID
#
# $Id$
#
# Copyright 2010-2015, Tech-X Corporation, Boulder, CO.
# All rights reserved.
#
#
######################################################################

# Find shared libs
SciFindPackage(PACKAGE "Fluxgrid"
  INSTALL_DIR "fluxgrid"
  PROGRAMS "fluxgrid"
)


