#!/usr/bin/env bash

called=$_

#basically, get the absolute path of this script (handy for loads of things)
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null;
_OK__PATH_TO_ME=$(pwd)
popd > /dev/null;

# Don't let ok-show.py's shebang control the python version; prefer python3 above python regular (2)
_OK__PATH_TO_PYTHON=$(command -v python3 || command -v python)


ok() {
    function _ok_cmd_usage {
        unset -f _ok_cmd_usage #emulate a "local" function
        if [[ $show_prompt == 1 ]]; then
            local list_default="" list_prompt_default=" Default command."
        else
            local list_default=" Default command." list_prompt_default=""
        fi
        echo -e "Usage: ok [options] <number> [script-arguments..]
       ok command [options]

command (use one):
  <number>            Run the <number>th command from the '.ok' file.
  l, list             Show the list from the '.ok' file.$list_default
  L, list-once        Same as list, but only show when pwd is different from when the list was last shown.
  p, list-prompt      Show the list and wait for input at the ok-prompt (like --list and <number> in one command).$list_prompt_default
  h, help             Show this usage page.
options:
  -c, --comment_align N  Level of comment alignment. See \$_OK_COMMENT_ALIGN
  -v, --verbose       Show more output, mostly errors. Also it shows environment-variables in this screen.
  -q, --quiet         Only show really necessary output, so surpress echoing the command.
  -f, --file <file>   Use a custom file instead of '.ok'; use '-' for stdin
  -a, --alias <name>  When using 'ok' in an alias, <name> is used to keep the history correct when used with 'list-prompt'.
  -V, --version       Show version number and exit
  -h, --help          Show this help screen
script-arguments:
  ...                 These are passed through, when a line is executed (you can enter these too at the ok-prompt)\\n"

        if [[ $verbose -ge 2 ]]; then
            if [ -z ${_OK_COMMENT_ALIGN+x} ];  then local e="unset";  else local e="$_OK_COMMENT_ALIGN"; fi
            if [ -z ${_OK_PROMPT+x} ];         then local p="unset";  else local p="'$_OK_PROMPT'"; fi
            if [ -z ${_OK_VERBOSE+x} ];        then local v="unset";  else local v="$_OK_VERBOSE"; fi
            if [ -z ${_OK_PROMPT_DEFAULT+x} ]; then local l="unset";  else local l="$_OK_PROMPT_DEFAULT"; fi
            echo -e "environment variables (used for colored output; current colors are shown):
  _OK_C_HEADING      ${_OK_C_HEADING}Color-code${c_nc} for lines starting with a comment (heading). Defaults to red.
  _OK_C_NUMBER       ${_OK_C_NUMBER}Color-code${c_nc} for numbering. Defaults to cyan.
  _OK_C_COMMENT      ${_OK_C_COMMENT}Color-code${c_nc} for comments after commands. Defaults to blue.
  _OK_C_COMMAND      ${_OK_C_COMMAND}Color-code${c_nc} for commands. Defaults to color-reset.
  _OK_C_PROMPT       ${_OK_C_PROMPT}Color-code${c_nc} for prompt (both input as command confirmation). Defaults to color for numbering.
environment variables (other configuration):
  _OK_COMMENT_ALIGN  Level ($e) of comment alignment. 0=no alignment, 1=align consecutive lines (Default), 2=including whitespace, 3 align all.
  _OK_PROMPT         String ($p) used as prompt (both input as command confirmation). Defaults to '$ '.
  _OK_PROMPT_DEFAULT Setting ($l) if the prompt is default shown. 1=use command list-prompt when issuing no command, otherwise use list.
  _OK_VERBOSE        Level ($v) of feedback ok provides. 0=quiet, 1=normal, 2=verbose. Defaults to 1. Can be overriden with --verbose or --quiet.
environment variables (for internal use):
  _OK__LAST_PWD      Remember the path ($_OK__LAST_PWD) that was last listed, for use with the list-once command.
  _OK__PATH_TO_ME    The path ($_OK__PATH_TO_ME) to the location of this script.
  _OK__PATH_TO_PYTHON The path ($_OK__PATH_TO_PYTHON) to the used python interpreter.\\n"
        fi
        if [[ -n $1 ]]; then
            echo -e "$1\\n"
            return 1
        fi
    }

    function _ok_cmd_run {
        unset -f _ok_cmd_run
        # save and remove argument. Remaining arguments are passwed to eval automatically
        local line_nr=$1 #LINE_NR is guaranteed to be 1 or more
        shift
        # get the line to be executed
        local line_text
        line_text="$(cat "$ok_file" | "$_OK__PATH_TO_PYTHON" "${_OK__PATH_TO_ME}/ok-show.py" -v "$verbose" -c "$comment_align" -t "$(tput cols)" "$line_nr")"
        local res=$?
        if [[ $res -ne 0 ]]; then
            #because stdout/stderr are swapped by ok-show.py in this case, handle this too
            >&2 echo "$line_text"
            return "$res"
        fi
        eval "$line_text"
    }

    function _ok_cmd_list {
        unset -f _ok_cmd_list

        cat "$ok_file" | "$_OK__PATH_TO_PYTHON" "${_OK__PATH_TO_ME}/ok-show.py" -v "$verbose" -c "$comment_align" -t "$(tput cols)" || return $?
    }

    # export variables because python is a sub-process, and variables might have changed since initialization
    for x in $(set | grep "^_OK_" | awk -F '=' '{print $1}'); do 
        export "$x"="${!x}"
    done

    local -r version="0.8.0"
    # used for colored output (see: https://stackoverflow.com/a/20983251/56)
    # notice: this is partly a duplication from code in ok-show.py
    local -r c_nc=$(tput sgr0)
    if [ -z ${_OK_C_NUMBER+x} ];  then local c_number=$(tput setaf 6);  else local c_number=$_OK_C_NUMBER;   fi #NUMBER defaults to CYAN
    if [ -z ${_OK_C_PROMPT+x} ];  then local c_prompt=$c_number;        else local c_prompt=$_OK_C_PROMPT;   fi #PROMPT defaults to same color as NUMBER
    # other customizations (some environment variables can be overridden by arguments)
    if [ -z ${_OK_PROMPT+x} ];    then local prompt="$ ";               else local prompt=$_OK_PROMPT;       fi
    if [ -z ${_OK_VERBOSE+x} ];   then local verbose=1;                 else local verbose=$_OK_VERBOSE;     fi

    # handle command line arguments now
    local ok_file=".ok"
    local args # Make sure no double space is added
    if [[ -z "$*" ]]; then
        args="ok"
    else
        args="ok $*"
    fi
    local re_is_num='^[1-9][0-9]*$' #numbers starting with "0" would be octal, and nobody knows those (also: sed on Linux complains about line "0")...
    local cmd=list
    local line_nr=0
    local once_check=0
    local show_prompt=${_OK_PROMPT_DEFAULT:-0}
    local comment_align=${_OK_COMMENT_ALIGN:-1}
    local usage_error=
    local loop_args=1 #the Pascal-way to break loops
    while (( $# > 0 && loop_args == 1 )) ; do
        # if the user provided a parameter, $1, which contains a number...
        if [[ $1 =~ $re_is_num ]]; then
            cmd=run
            line_nr=$1
            loop_args=0
        else
            case $1 in
                #commands
                l | list)          cmd=list; show_prompt=0; once_check=0;;
                L | list-once)     cmd=list; show_prompt=0; once_check=1;;
                p | list-prompt)   cmd=list; show_prompt=1; once_check=0;;
                h | help)          cmd=usage;;
                #options
                -V | --version)    cmd=version;;
                -\? | -h | --help) cmd=usage;;
                -v | --verbose)    verbose=2;;
                -q | --quiet)      verbose=0;;
                -c | --comment_align) if [[ $# -ge 2 ]]; then comment_align=$2; shift; else echo "the $1 argument needs a number (0..3) as 2nd argument"; fi;;
                -f | --file)       if [[ $# -gt 1 && -r "$2" || "-" == "$2" ]]; then ok_file="$2"; shift; else _ok_cmd_usage "No file provided, or file is not readable ($2)" || return $?; fi;;
                -a | --alias)      if [[ $# -gt 1 && -n "$2" ]]; then args="$2"; shift; else _ok_cmd_usage "Empty or no alias provided" || return $?; fi;;
                *)                 cmd=usage; usage_error="Unknown command/option '$1'";;
            esac
        fi
        shift
    done

    if [[ $cmd == usage ]]; then
        _ok_cmd_usage "$usage_error" || return $?
    elif [[ $cmd == version ]]; then
        echo "ok-bash $version"
    elif [[ - == "$ok_file" || -r "$ok_file" ]]; then
        if [[ $cmd == run ]]; then
            _ok_cmd_run "$line_nr" "$@" || return $?
        elif [[ $cmd == list ]]; then
            if [[ $once_check == 0 || ($once_check == 1 && $_OK__LAST_PWD != $(pwd)) ]]; then
                _ok_cmd_list
                local list_result=$?
                if [[ $list_result -gt 1 ]]; then
                    return $list_result
                elif [[ $show_prompt == 1 && $list_result == 0 ]]; then #only show prompt, if there where commands printed
                    local prompt_input
                    local re_num_begin='^[1-9][0-9]*($| )' # You can enter arguments at the ok-prompt too, hence different regex
                    # The following read doesn't work in a sub-shell, so list-prompt fails when using it in a script
                    read -rp "${c_prompt}${prompt}${c_nc}" prompt_input
                    if [[ $prompt_input =~ $re_num_begin ]]; then
                        #save command to history first
                        history -s "$args $prompt_input"
                        #execute command
                        eval _ok_cmd_run "$prompt_input" || return $?
                    else
                        if [[ -z $prompt_input || $prompt_input = "0" ]]; then
                            return 0
                        fi
                        if [[ $verbose -ge 2 ]]; then
                            >&2 echo "ERROR: input '$prompt_input' does not start with a number"
                        fi
                        return 1
                    fi
                fi
            fi
            if [[ $verbose -ge 2 && $once_check == 1 && $_OK__LAST_PWD == $(pwd) ]]; then
                echo "The listing for this folder has already been shown"
            fi
        fi
    else
        if [[ $verbose -ge 2 ]]; then
            echo "Nothing to do: this folder doesn't have a readable '$ok_file' file"
        fi
    fi
    export _OK__LAST_PWD=$(pwd)
}

if [[ "$called" == "$0" ]]; then
    if [[ -z "$_OK__PATH_TO_PYTHON" ]]; then
        >&2 echo "ERROR: python is required to run 'ok', but can't be found"
        exit 1
    fi
    if [[ $1 == "t" || $1 == "test" ]]; then
        shift
        ok "$@"
    else
        # tip: "." (i.e. source) this file from your profile (.bashrc), e.g. ". ~/path/to/ok-bash/ok.sh"
        echo -e "tip: \".\" (i.e. source) this file from your ~/.profile, e.g. \". ${_OK__PATH_TO_ME/$HOME/~}/ok.sh <arguments>\"

arguments, if you need to customize (these can also be set via arguments/environment):
  reset            Reset (unset) all environment variables (\$_OK_*) and will undo  'auto_show' if set (can modify \$PROMPT_COMMAND)
  prompt <prompt>  Use the supplied prompt (e.g. prompt '> ')
  prompt_default   Prompt default when issueing running ok without arguments
  auto_show        Perform 'ok list-once' every time the prompt is shown (modifies \$PROMPT_COMMAND)
  comment_align N  Level of comment alignment. See \$_OK_COMMENT_ALIGN
  comment_align N  Level of comment alignment. 0=no alignment, 1=align consecutive lines (Default), 2=including whitespace, 3 align all.
  verbose          Enable verbose mode
  quiet            Enable quiet mode\\n"
    fi
else
    # Process some installation helpers
    re_list_once=$'ok list-once'
    while (( $# > 0 )) ; do
        case $1 in
            reset)          for x in $(set | grep "^_OK_[^_]" | awk -F '=' '{print $1}'); do 
                                unset "$x"
                            done
                            if [[ $PROMPT_COMMAND =~ $re_list_once ]]; then export PROMPT_COMMAND="${PROMPT_COMMAND/$'\n'$re_list_once/}"; fi;;
            prompt)         if [[ $# -ge 2 ]]; then export _OK_PROMPT=$2; shift; else echo "the prompt argument needs the actual prompt as 2nd argument"; fi;;
            prompt_default) export _OK_PROMPT_DEFAULT=1;;
            comment_align)  if [[ $# -ge 2 ]]; then export _OK_COMMENT_ALIGN=$2; shift; else echo "the comment_align argument needs a number (0..3) as 2nd argument"; fi;;
            verbose)        export _OK_VERBOSE=2;;
            quiet)          export _OK_VERBOSE=0;;
            auto_show)      if [[ ! $PROMPT_COMMAND =~ $re_list_once ]]; then export PROMPT_COMMAND="${PROMPT_COMMAND}"$'\n'"${re_list_once}"; fi;;
            *) echo "Ignoring unknown argument '$1'";;
        esac
        shift
    done
    unset re_list_once
    # export variables so `ok` can be used from scripts as well
    for x in $(set | grep "^_OK_" | awk -F '=' '{print $1}'); do 
        export "$x"="${!x}"
    done
    #make ok available for scripts as well
    export -f ok
fi
unset called
