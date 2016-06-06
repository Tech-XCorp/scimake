######################################################################
#
# @file    SciFuncsMacros.cmake
#
# @brief   Various functions and macros used by Tech-X scimake
#
# @version $Id$
#
# Copyright 2012-2016, Tech-X Corporation, Boulder, CO.
# See LICENSE file (EclipseLicense.txt) for conditions of use.
#
######################################################################

#
# SciPrintString: print a string in a status message as well as to
#   ${CONFIG_SUMMARY}
# Args:
#   str the string
#
macro(SciPrintString str)
# Double the \ to get through
  # string(REPLACE "\\" "\\\\" str "${str}")
  message(STATUS "${str}")
  if (DEFINED CONFIG_SUMMARY)
    file(APPEND "${CONFIG_SUMMARY}" "${str}\n")
  else ()
    message(STATUS "NOTE: [SciFuncsMacros] Variable CONFIG_SUMMARY is not defined, SciPrintString is unable to write to the summary file.")
  endif ()
endmacro()

#
# SciPrintVar: print a variable with standard formatting
# Args:
#   var the name of the variable
#
macro(SciPrintVar var)
  string(LENGTH "${var}" lens)
  math(EXPR lenb "35 - ${lens}")
  if (lenb GREATER 0)
    string(RANDOM LENGTH ${lenb} ALPHABET " " blstr)
  else ()
    set(blstr "")
  endif ()
  SciPrintString("  ${var}${blstr}= ${${var}}")
endmacro()

#
# Print all cmake variables generated by SciFindPackage
# Args:
#   pkg: the name of the package
#
macro(SciPrintCMakeResults pkg)
  # message("--------- RESULTS FOR ${pkg} ---------")
  SciPrintString("")
  SciPrintString("RESULTS FOR ${pkg}:")
  set(sfxs ROOT_DIR CONFIG_CMAKE CONFIG_VERSION_CMAKE PROGRAMS FILES INCLUDE_DIRS MODULE_DIRS LIBFLAGS LIBRARY_DIRS LIBRARY_NAMES LIBRARIES PLUGINS STLIBS)
  if (WIN32)
    set(sfxs ${sfxs} DLLS)
  elseif (APPLE)
    set(sfxs ${sfxs} FRAMEWORK_DIRS FRAMEWORK_NAMES FRAMEWORKS)
  endif ()
  set(sfxs ${sfxs} DEFINITIONS)
  foreach (varsfx ${sfxs})
    SciPrintVar(${pkg}_${varsfx})
  endforeach ()
endmacro()

#
# Print all autotools variables generated by SciFindPackage
# Args:
#   pkg: the name of the package
#
macro(SciPrintAutotoolsResults pkg)
  # message("--------- RESULTS FOR ${pkg} ---------")
  SciPrintString("")
  SciPrintString("RESULTS FOR ${pkg}:")
  foreach (varsfx ROOT_DIR DIR INCDIRS MODDIRS LIBS ALIBS)
    SciPrintVar(${pkg}_${varsfx})
  endforeach ()
  if (WIN32)
    SciPrintVar(${pkg}_DLLS)
  endif ()
endmacro()

#
# Install an executable in its own subdir
#
# EXECNAME: the name of the executable and also its installation subdir
# LIBSSFX: ${EXECNAME}_${LIBSSFX} holds the libraries that need to be installed
#
macro(SciInstallExecutable)
  set(oneValArgs EXECNAME LIBSSFX)
  cmake_parse_arguments(TIE_
    "${opts}" "${oneValArgs}" "${multiValArgs}" ${ARGN}
)
  install(TARGETS ${TIE_EXECNAME}
    RUNTIME DESTINATION ${TIE_EXECNAME}/bin
    LIBRARY DESTINATION ${TIE_EXECNAME}/lib
    ARCHIVE DESTINATION ${TIE_EXECNAME}/lib
    PERMISSIONS OWNER_READ OWNER_WRITE
                GROUP_READ ${SCI_GROUP_WRITE}
                ${SCI_WORLD_FILE_PERMS}
    COMPONENT ${TIE_EXECNAME}
)
  if (BUILD_SHARED_LIBS)
# Install libraries into each executable installation
    install(TARGETS txustd ${${TIE_EXECNAME}_${TIE_LIBSSFX}}
      RUNTIME DESTINATION ${TIE_EXECNAME}/bin
      LIBRARY DESTINATION ${TIE_EXECNAME}/lib
      ARCHIVE DESTINATION ${TIE_EXECNAME}/lib
      PERMISSIONS OWNER_READ OWNER_WRITE
                  GROUP_READ ${SCI_GROUP_WRITE}
                  ${SCI_WORLD_FILE_PERMS}
      COMPONENT ${TIE_EXECNAME}
)
  endif ()
endmacro()

#
# Replace compiler flags in specified flags variable
#
# Required arguments:
# CMPTYPE: compiler type
# BLDTYPE: build type
#
# Optional arguments:
# RMVFLG: the flag to be removed
# ADDFLG: the flag to be added
#
macro(SciRplCompilerFlags CMPTYPE BLDTYPE)
# parse the path argument
  set(oneValArgs RMVFLG ADDFLG)
# parse the input argument
  cmake_parse_arguments(RPLFLGS "${opts}" "${oneValArgs}" "${multiValArgs}" ${ARGN})

  # Determine default values if none specified
  if (NOT RPLFLGS_RMVFLG)
    if (WIN32)
      if (BUILD_WITH_SHARED_RUNTIME OR BUILD_SHARED_LIBS)
        set(RPLFLGS_RMVFLG "/MT")
      else ()
        set(RPLFLGS_RMVFLG "/MD")
      endif ()
    endif ()
  endif ()
  if (NOT RPLFLGS_ADDFLG)
    if (WIN32)
      if (BUILD_WITH_SHARED_RUNTIME OR BUILD_SHARED_LIBS)
        set(RPLFLGS_ADDFLG "/MD")
      else ()
        set(RPLFLGS_ADDFLG "/MT")
      endif ()
    endif ()
  endif ()

  if (NOT (RPLFLGS_RMVFLG EQUAL RPLFLGS_ADDFLG))
# Assemble the variable name and copy the associated value
    set(thisvar "CMAKE_${CMPTYPE}_FLAGS_${BLDTYPE}")
    set(thisval "${${thisvar}}")
# check if the remove flag is in the current variable
    string(FIND "${thisval}" "${RPLFLGS_RMVFLG}" md_found)
    if (md_found EQUAL -1) # if not just append the desired one
      string(FIND "${thisval}" "${RPLFLGS_ADDFLG}" des_found)
      if (des_found EQUAL -1) # only add desired one if not there
        set(thisval "${thisval} ${RPLFLGS_ADDFLG}")
      endif ()
    else () # otherwise replace the unwantedflag with the wanted flag
      string(REPLACE "${RPLFLGS_RMVFLG}" "${RPLFLGS_ADDFLG}" thisval "${thisval}")
    endif ()
  endif ()

# append /bigobj to the current compiler arguments
# ...but only if it's not already there
  string(FIND "${thisval}" "/bigobj" bigobj_found)
  if (bigobj_found EQUAL -1)
    set(thisval "${thisval} /bigobj")
  endif ()
# force the compiler argument to be recached
  set(${thisvar} "${thisval}" CACHE STRING "Flags used by the ${CMPTYPE} compiler during ${BLDTYPE} builds" FORCE)

endmacro()

#
# Add generation of doxygen documentation, generated in doxdir
# Args:
#   doxdir: the subdirectory where the documentation is made
#
macro(SciAddDox doxdir)
  if (ENABLE_DEVELDOCS)
    find_package(SciDoxygen)
    if (DOXYGEN_FOUND)
      find_package(SciGraphviz)
    else ()
      message(FATAL_ERROR "ENABLE_DEVELDOCS set, but Doxygen not found.")
    endif ()
    if (Graphviz_dot)
      set(HAVE_GRAPHVIZ_DOT YES)
    else ()
      set(HAVE_GRAPHVIZ_DOT NO)
    endif ()
    message(STATUS "Adding ${doxdir} subdir.")
    add_subdirectory(${doxdir})
  else ()
    message(STATUS "ENABLE_DEVELDOCS not set. Not adding ${doxdir} subdir.")
  endif ()
endmacro()

#
# Add static analysis, when build matches bld
# Args:
#   bld: the build that must be matched for cppcheck to be run
#
macro(SciAddCppCheck bld)
  find_package(SciCppCheck)
  find_package(SciPcre)  # Needed for location of shared libs
  if (PCRE_FOUND)
    SciAddSharedLibDirs(ADDPATH ${Pcre_LIBRARY_DIRS})
    if (CPPCHECK_FOUND)
      SciCppCheckSource(${bld})
    endif ()
  endif ()
endmacro()

#
# Generate an export header that has a general define for the
# export header created by cmake
# basedef The define that will lead to the directory definition
# incincfile The name of the file to be generated
# dirdef The definition created when basedef is not defined
# dirincfile The file to be included
#
macro(SciGenExportHeaderContainer basedef incincfile dirdef dirincfile)
  get_filename_component(def ${incincfile} NAME)
  string(TOUPPER "${def}" def)
  string(REGEX REPLACE "[\\.-]" "_" def "${def}")
  set(declinc
"
/**
 * Generated header, do not edit
 */
#ifndef ${def}
#define ${def}

#if !defined(${basedef}) || defined(__CUDA_ARCH__)
#define ${dirdef}
#endif
#include <${dirincfile}>

#endif // ${def}

"
  )
  file(WRITE ${incincfile} "${declinc}")
endmacro()

# A macro for using hdf5
#
# libvar the library variable to add hdf5 to
# Validated for cori-gcc-ser, cori-intel-ser, cori-gcc-par, cori-intel-par
macro (addHdf5MpiZDlLibs libvar)
  link_directories(${Hdf5_LIBRARY_DIRS})
  if (ENABLE_PARALLEL AND NOT SCI_HAVE_MPICXX_COMPILER_WRAPPER)
    link_directories(${MPI_LIBRARY_DIRS})
  endif ()

  if (USE_STATIC_SYSLIBS)
    set(${libvar} ${${libvar}} ${Hdf5_STLIBS})
  else ()
    set(${libvar} ${${libvar}} ${Hdf5_LIBRARY_NAMES})
  endif ()
  if (ENABLE_PARALLEL AND NOT SCI_HAVE_MPICXX_COMPILER_WRAPPER)
    set(${libvar} ${${libvar}} ${MPI_LIBRARIES})
  endif ()
  set(${libvar} ${${libvar}} ${Z_LIBRARY_NAMES})
  if (LINUX)
    set(${libvar} ${${libvar}} dl)
  endif ()
endmacro ()

