# Copyright 2023 The ChromiumOS Authors
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file or at
# https://developers.google.com/open-source/licenses/bsd

#
# bash completion script for lium
#
# return 0(OK) if given argument is already used
__lium_arg_used() { # arg
  local i=0
  while [ $i -lt $COMP_CWORD ]; do
    test x"${COMP_WORDS[i]}" = x"$1" && return 0
    i=$((i+1))
  done
  return 1
}

# return 0 (OK) if one of given arguments is already used
_lium_arg_used() { # arg [arg...]
  while [ "$#" -ne 0 ]; do
    __lium_arg_used $1 && return 0
    shift 1
  done
  return 1
}

# return 0 if carg is included in the rest of args
_lium_arg_included() { # carg [args...]
  local cur=$1
  shift 1
  while [ "$#" -ne 0 ]; do
    test x"${cur}" = x"$1" && return 0
    shift 1
  done
  return 1
}

_lium_current_repo() {
  local i=0
  while [ $i -lt $COMP_CWORD ]; do
    if [ "${COMP_WORDS[i]}" = "--repo" ]; then
      i=$((i+1))
      echo "${COMP_WORDS[i]}"
      return
    fi
    i=$((i+1))
  done
  if [ -d $PWD/.repo -a -d $PWD/chroot ]; then
    echo $PWD
  fi
}

_lium_get_duts() {
  ${COMP_WORDS[0]} dut list --ids 2>/dev/null
}

_lium_get_tests() {
  ${COMP_WORDS[0]} tast list --cached 2>/dev/null | cut -f 1 -d,
}

_lium_get_servos() {
  ${COMP_WORDS[0]} servo list --serials 2>/dev/null | cut -f 1
}

_lium_get_dut_actions() {
  lium dut do --list-actions 2>/dev/null
}

_lium_comp_fs() { # option(-d|-f) current
  local DIR=`compgen ${1} ${2}`
  if [ `echo ${DIR} | wc -w` = 1 -a -d "${DIR}" ]; then
    compgen ${1} "${DIR}/"
  else
    compgen ${1} ${2}
  fi
}

_lium_current_command() {
  local i=0
  while [ $i -lt $COMP_CWORD ]; do
    case "${COMP_WORDS[i]}" in
      -*) i=$COMP_CWORD;;
      *)
        echo "${COMP_WORDS[i]} ";;
    esac
    i=$((i+1))
  done
}

_lium_get_options() { # current
  local cmd=`_lium_current_command`
  local otype=0
  local a b

  ${cmd} --help 2>/dev/null | while read a b ;do
    case ${a} in
      Positional) otype=1;;
      Options:) otype=2;;
      Commands:) otype=3;;
      -*)
        # All options start with '-'.
        if [ ${otype} -eq 2 ]; then
          _lium_arg_used ${a} || echo ${a}
        fi;;
      *)
        # Positional arguments must be converted.
        if [ ${otype} -eq 1 ]; then
          case "${a}" in
          dut|duts)
            _lium_get_duts;;
          actions)
            _lium_get_dut_actions;;
          tests)
            _lium_get_tests;;
          files)
            if [ "${1#-}" == "${1}" ]; then
              _lium_comp_fs -f ${1}
            fi;;
          esac
        # Subcommands must be shown as it is.
        elif [ ${otype} = 3 ]; then
          echo ${a}
        fi
        ;;
    esac
  done
}

_lium() { # command current prev
  local cur=$2
  local prev=$3
  local dir_opts="--repo --dir --dest"
  local todo_opts="--version --board --workon --packages"

  COMPREPLY=
  # If there is --help option, no more options available.
  if _lium_arg_used "--help"; then
    return 0
  fi

  if _lium_arg_included ${prev} ${todo_opts}; then
    # TODO: support completion for each options. currently it is stopped.
    return 0
  elif [ x"$prev" = x"--dut" ]; then
    local DUTS=`_lium_get_duts`
    COMPREPLY=($(compgen -W "${DUTS}" -- $cur))
  elif [ x"$prev" = x"--serial" ]; then
    local DUTS=`_lium_get_servos`
    COMPREPLY=($(compgen -W "${DUTS}" -- $cur))
  elif _lium_arg_included ${prev} ${dir_opts}; then
    COMPREPLY=($(_lium_comp_fs -d ${cur}))
  else
    local OPTS=`_lium_get_options ${cur}`
    COMPREPLY=($(compgen -W "${OPTS}" -- ${cur}))
  fi
}

complete -F _lium lium
