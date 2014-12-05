######################################################################
#
# SciFuncsMacros: Various functions and macros used by Tech-X scimake
#
# $Id$
#
# Copyright 2010-2014, Tech-X Corporation, Boulder, CO.
# See LICENSE file (EclipseLicense.txt) for conditions of use.
#
#
######################################################################

#
# SciPrintString: print a string in a status message as well as to
#   ${CONFIG_SUMMARY}
# Args:
#   str the string
#
macro(SciPrintString str)
  message(STATUS "${str}")
  if (DEFINED CONFIG_SUMMARY)
    file(APPEND "${CONFIG_SUMMARY}" "${str}\n")
  else ()
    message(WARNING "Variable CONFIG_SUMMARY is not defined, SciPrintString is unable to write to the summary file.")
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
  if ( NOT RPLFLGS_RMVFLG )
    if ( WIN32 )
      if  ( BUILD_WITH_SHARED_RUNTIME OR BUILD_SHARED_LIBS )
        set(RPLFLGS_RMVFLG "/MT")
      else ()
        set(RPLFLGS_RMVFLG "/MD")
      endif () 
    endif ()
  endif ()
  if ( NOT RPLFLGS_ADDFLG )
    if ( WIN32 )
      if  ( BUILD_WITH_SHARED_RUNTIME OR BUILD_SHARED_LIBS )
        set(RPLFLGS_ADDFLG "/MD")
      else ()
        set(RPLFLGS_ADDFLG "/MT")
      endif ()
    endif ()
  endif ()

  if (NOT (RPLFLGS_RMVFLG EQUAL RPLFLGS_ADDFLG))  
    # Assemble the variable name and copy the associated value
    set(thisvar "CMAKE_${cmptype}_FLAGS_${bldtype}")
    set(thisval "${${thisvar}}")
    # check if the remove flag is in the current variable
    string(FIND "${thisval}" "${RPLFLGS_RMVFLG}" md_found)
    if (md_found EQUAL -1) # if not just append the desired one
      set(thisval "${thisval} ${RPLFLGS_ADDFLG}")
    else () # otherwise replace the unwantedflag with the wanted flag
      string(REPLACE "${RPLFLGS_RMVFLG}" "${RPLFLGS_ADDFLG}" thisval "${thisval}")
      # removed any dagling d that might have been left behind by for example
      # replacing "/MD" with " " when it was actually "/MDd" leaves behind " d"
      string(REPLACE " d" " " thisval "${thisval}")
    endif ()
    # append /bigobj to the current compiler arguments
    set(thisval "${thisval} /bigobj")
    # force the compiler argument to be recached
    set(${thisvar} "${thisval}" CACHE STRING "Flags used by the ${cmptype} compiler during ${bldtype} builds" FORCE)
  endif ()
endmacro()
