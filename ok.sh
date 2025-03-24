#!/usr/bin/env bash

#basically, get the absolute path of this script (handy for loads of things)
pushd "$(dirname "${BASH_SOURCE[0]:-$0}")" > /dev/null || (>&2 echo "ok-sh: pushd failed")
_OK__PATH_TO_ME=$(pwd)
popd > /dev/null || (>&2 echo "ok-sh: popd failed")

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
        echo -e "Usage: ok [options] <named or numbered command> [script-arguments..]
       ok [options] <internal command> [options]

command (use one):
  <number>            Run an unnamed command (the <number>th unnamed command) from the ok-file.
  <name>              Run an named command from the ok-file (starts with a letter/underscore, followed by same and dash/period/numbers)
  list                Show the list from the ok-file.$list_default
  list-once           Same as list, but only show when pwd is different from when the list was last shown.
  list-prompt         Show the list and wait for input at the ok-prompt (like --list and <number> in one command).$list_prompt_default
  help                Show this usage page.
options:
  -s, --summary       Show all named commands, space seperated
  -c, --comment-align N  Level of comment alignment. See \$_OK_COMMENT_ALIGN
  -v, --verbose       Show more output, mostly errors. Also it shows environment-variables in this screen.
  -q, --quiet         Only show really necessary output, so surpress echoing the command.
  -f, --file <file>   Use a custom file instead of the default '.ok-sh' and '.ok' files; use '-' for stdin
  -a, --alias <name>  When using 'ok' in an alias, <name> is used to keep the history correct when used with 'list-prompt'.
  -p, --parent        If no .ok file found, search upwards in folder tree for an .ok file.   
  -V, --version       Show version number and exit
  -h, --help          Show this help screen"
        if [[ $verbose -ge 2 ]]; then
            echo -e "system options:
  --sys-cmds          Show all commands, space seperated (used for auto-complete)
  --sys-opts          Show all options (long form), space seperated (used for auto-complete)"
        fi
        echo -e "script-arguments:
  ...                 These are passed through, when a line is executed (you can enter these too at the ok-prompt)\\n"

        if [[ $verbose -ge 2 ]]; then
            if [ -z ${_OK_COMMENT_ALIGN+x} ];  then local e="unset";  else local e="$_OK_COMMENT_ALIGN"; fi
            if [ -z ${_OK_PROMPT+x} ];         then local p="unset";  else local p="'$_OK_PROMPT'"; fi
            if [ -z ${_OK_VERBOSE+x} ];        then local v="unset";  else local v="$_OK_VERBOSE"; fi
            if [ -z ${_OK_PROMPT_DEFAULT+x} ]; then local l="unset";  else local l="$_OK_PROMPT_DEFAULT"; fi
            echo -e "environment variables (used for colored output; current colors are shown):
  _OK_C_HEADING      ${_OK_C_HEADING:-}Color-code${c_nc} for lines starting with a comment (heading). Defaults to red.
  _OK_C_NUMBER       ${_OK_C_NUMBER:-}Color-code${c_nc} for numbering, or significant (left) part of the command. Defaults to bright cyan.
  _OK_C_NUMBER2      ${_OK_C_NUMBER2:-}Color-code${c_nc} for non-significant (right) part of the command. Defaults to cyan.
  _OK_C_COMMENT      ${_OK_C_COMMENT:-}Color-code${c_nc} for comments after commands. Defaults to blue.
  _OK_C_COMMAND      ${_OK_C_COMMAND:-}Color-code${c_nc} for commands. Defaults to color-reset.
  _OK_C_PROMPT       ${_OK_C_PROMPT:-}Color-code${c_nc} for prompt (both input as command confirmation). Defaults to color for numbering.
environment variables (other configuration):
  _OK_COMMENT_ALIGN  Level ($e) of comment alignment. 0=no alignment, 1=align consecutive lines (default), 2=including whitespace, 3 align all.
  _OK_PROMPT         String ($p) used as prompt (both input as command confirmation). Defaults to '$ '.
  _OK_PROMPT_DEFAULT Setting ($l) if the prompt is default shown. 1=use command list-prompt when issuing no command, otherwise use list.
  _OK_VERBOSE        Level ($v) of feedback ok provides. 0=quiet, 1=normal, 2=verbose. Defaults to 1. Can be overriden with --verbose or --quiet.
environment variables (for internal use):
  _OK__DATAFILE_SIMILAR When set (${_OK__DATAFILE_SIMILAR:-unset}), data is written to specified path+filename for analytic purpose.
  _OK__LAST_PWD         Remember the path ($_OK__LAST_PWD) that was last listed, for use with the list-once command.
  _OK__PATH_TO_ME       The path ($_OK__PATH_TO_ME) to the location of this script.
  _OK__PATH_TO_PYTHON   The path ($_OK__PATH_TO_PYTHON) to the used python interpreter.\\n"
        fi
        if [[ -n $1 ]]; then
            echo -e "\\a$1\\n"
            return 1
        fi
    }

    function ok_show {
        local twidth
        local input="${1:--}"
        shift
        #Apparently bash-arrays on macOS can't be empty, so initialize it with something that's always needed
        local -a ok_show_args=(--version "$version" --verbose "$verbose" --comment_align "$comment_align")
        if [[ $input = - ]]; then # Prevent shellcheck's "useless cat"-warning
            input="/dev/stdin"
        else
            #pass width, because python2 can't determine this
            #also, `stty size` doesn't work inside a pipe, so that's why it's here...
            twidth="$(stty size|awk '{print $2}')"
            if [[ ${twidth:-} ]]; then
                ok_show_args=("${ok_show_args[@]}" --terminal_width "$twidth")
            fi
        fi
        # Make sure colors are exported, so python can use them
        for x in $(set | grep "^_OK_C_" | awk -F '=' '{print $1}'); do 
            export "${x?}"
        done
        "${_OK__PATH_TO_PYTHON:-$(command -v python3 || command -v python)}" "${_OK__PATH_TO_ME}/ok-show.py" "${ok_show_args[@]}" "$@" < "$input"
    }

    function _ok_cmd_run {
        unset -f _ok_cmd_run
        # save and remove argument. Remaining arguments are passwed to eval automatically
        local external_command="$1" #LINE_NR is guaranteed to be 1 or more
        shift
        # get the line to be executed
        local line_text
        line_text="$(ok_show "$ok_file" "$external_command")"
        local res=$?
        if [[ $res -ne 0 ]]; then
            #because stdout/stderr are swapped by ok-show.py in this case, handle this too
            >&2 echo "$line_text"
            return "$res"
        fi

        # if using ok file from parent, need to account for relative paths
        if [ "$parent" -eq 1 ]; then
            if [ "$(pwd)" != "$(dirname "$line_text")" ]; then #executing from parent
                if [[ $line_text != /* ]]; then #relative path
                    dir_ok_file=$(dirname "$ok_file")
                    line_text=$(echo "$line_text" | \sed "s|\.|$dir_ok_file|")                
                fi
            fi
        fi

        eval "$line_text"
    }

    local -r version="0.9.0dev"
    # used for colored output (see: https://stackoverflow.com/a/20983251/56)
    # notice: this is partly a duplication from code in ok-show.py
    local -r c_nc=$'\033''[0m'
    if [ -z ${_OK_C_NUMBER+x} ];  then local c_number=$'\033''[0;36m';  else local c_number=$_OK_C_NUMBER;   fi #NUMBER defaults to CYAN
    if [ -z ${_OK_C_PROMPT+x} ];  then local c_prompt=$c_number;        else local c_prompt=$_OK_C_PROMPT;   fi #PROMPT defaults to same color as NUMBER
    # other customizations (some environment variables can be overridden by arguments)
    if [ -z ${_OK_PROMPT+x} ];    then local prompt="$ ";               else local prompt=$_OK_PROMPT;       fi
    if [ -z ${_OK_VERBOSE+x} ];   then local verbose=1;                 else local verbose=$_OK_VERBOSE;     fi

    # handle command line arguments now
    local ok_file=""
    local args # Make sure no double space is added
    if [[ -z "$*" ]]; then
        args="ok"
    else
        args="ok $*"
    fi
    local re_begins_with_cmd='^([1-9][0-9]*|[A-Za-z_][-A-Za-z0-9_.]*)' # IMPORTANT: duplicate regex; "definition" in file `ok-show.py`
    local re_is_cmd="${re_begins_with_cmd}\$"
    local cmd=list
    local parent=0
    local external_command=0
    local once_check=0
    local show_prompt=${_OK_PROMPT_DEFAULT:-0}
    local comment_align=${_OK_COMMENT_ALIGN:-2}
    local usage_error=
    local loop_args=1 #the Pascal-way to break loops
    local ok_config_path="${XDG_CONFIG_HOME:-$HOME/.config}/ok-sh"
    local ok_lookup="${ok_config_path}/ok-lookup"
    
    while (( $# > 0 && loop_args == 1 )) ; do
        case $1 in
            #commands (duplicate there in ok-show.py arguments)
            list)          cmd=list; show_prompt=0; once_check=0;;
            list-once)     cmd=list; show_prompt=0; once_check=1;;
            list-prompt)   cmd=list; show_prompt=1; once_check=0;;
            \? | h | help) cmd=usage;;
            #options
            -V | --version)    cmd=version;;
            -\? | -h | --help) cmd=usage;;
            -p | --parent)     parent=1;; 
            -v | --verbose)    verbose=2;;
            -q | --quiet)      verbose=0;;
            -c | --comment_align | --comment-align) # between words seperator: bash=prefer dash; python=prefer underscore 
                               if [[ $# -ge 2 ]]; then comment_align=$2; shift; else _ok_cmd_usage "the '$1' argument needs a number (0..3) as 2nd argument" || return $?; fi;;
            -f | --file)       if [[ $# -gt 1 && -r "$2" || "-" == "$2" ]]; then ok_file="$2"; shift; else _ok_cmd_usage "No file provided, or file is not readable ($2)" || return $?; fi;;
            -a | --alias)      if [[ $# -gt 1 && -n "$2" ]]; then args="$2"; shift; else _ok_cmd_usage "Empty or no alias provided" || return $?; fi;;
            #system options
            -s | --summary)    cmd=".list_named_commands";;
            --sys-cmds)        cmd=".list_commands";;
            --sys-opts)        cmd=noop; echo "--version --help --verbose --quiet --comment-align --file --alias --summary";;
            -*)                cmd=usage; usage_error="Illegal option '$1'";;
            *)                 if [[ $1 =~ $re_is_cmd ]]; then
                                   cmd=run
                                   external_command="$1"
                                   loop_args=0
                               else
                                   cmd=usage; usage_error="Unrecognized command '$1' with illegal characters."
                               fi;;
        esac
        shift
    done
    # When no ok_file supplied, check if a default one is readable
    if [[ -z "$ok_file" ]]; then
        for f in .ok-sh .ok; do
            if [[ -r "$f" ]]; then
                ok_file="$f"
                break # found
            fi
        done
        if [ "$parent" -eq 1 ]; then
            if [[ -z "$ok_file" ]]; then #check up in the folder tree
                dir=$(pwd)

                # While we haven't reached the root directory
                while [ "$dir" != "/" ]; do
                    # Check if the .ok file exists in the current directory
                    if [ -e "$dir/.ok" ]; then
                        ok_file="$dir/.ok"
                        break #found
                    fi
                    # Move up one directory
                    dir=$(dirname "$dir")
                done
            fi
        fi
        # When no ok-file found, and the ok-lookup file exists, check that.
        if [[ -z "$ok_file" && -e "$ok_lookup" ]]; then
          ok_file="$(awk -F : -v PWD="$(pwd)" $'$1 == PWD { print $2; }' "$ok_lookup")"
          # check if it is a relative path
          if [[ $ok_file && ${ok_file:0:1} != '/' ]]; then
            ok_file="$ok_config_path/$ok_file"
          fi
        fi
    fi

    if [[ $cmd == noop ]]; then
        : #do nothing
    elif [[ $cmd == usage ]]; then
        _ok_cmd_usage "$usage_error" || return $?
    elif [[ $cmd == version ]]; then
        echo "ok-sh $version"
    elif [[ - == "$ok_file" || -r "$ok_file" ]]; then
        if [[ $cmd == run ]]; then
            _ok_cmd_run "$external_command" "$@" || return $?
        elif [[ $cmd =~ [.].+ ]]; then
            if [[ $verbose -ge 2 ]]; then
                echo "Running system command '$cmd'"
            fi
            ok_show "$ok_file" "$cmd" || return $?
        elif [[ $cmd == list ]]; then
            if [[ $once_check == 0 || ($once_check == 1 && $_OK__LAST_PWD != $(pwd)) ]]; then
                ok_show "$ok_file" || return $?
                local list_result=$?
                if [[ $list_result -gt 1 ]]; then
                    return $list_result
                elif [[ $show_prompt == 1 && $list_result == 0 ]]; then #only show prompt, if there where commands printed
                    local prompt_input
                    local re_num_begin="${re_begins_with_cmd}($| )" # You can enter arguments at the ok-prompt too, hence different regex
                    # Show a prompt (read -p "XXX" fails in zsh)
                    echo -n "${c_prompt}${prompt}${c_nc}" 
                    # The following read doesn't work in a sub-shell, so list-prompt fails when using it in a script
                    read -r prompt_input
                    if [[ $prompt_input =~ $re_num_begin ]]; then
                        #save command to history first
                        if [ -n "${ZSH_VERSION+x}" ]; then
                            # The Zsh way to do it
                            builtin print -s "$args $prompt_input"
                        else
                            # The Bash way to do it
                            builtin history -s "$args $prompt_input"
                        fi
                        #execute command
                        eval _ok_cmd_run "$prompt_input" || return $?
                    else
                        if [[ -z $prompt_input || $prompt_input = "0" ]]; then
                            return 0
                        fi
                        >&2 echo "Unrecognized command '$prompt_input' with illegal characters."
                        return 1
                    fi
                fi
            fi
            if [[ $verbose -ge 2 && $once_check == 1 && $_OK__LAST_PWD == $(pwd) ]]; then
                echo "The listing for this folder has already been shown"
            fi
            _OK__LAST_PWD=$(pwd)
            export _OK__LAST_PWD
        else
            if [[ $verbose -ge 2 ]]; then
                echo "Unknown command/state: '$cmd'"
            fi
        fi
    else
        if [[ $cmd == list ]]; then
            _OK__LAST_PWD=$(pwd)
            export _OK__LAST_PWD
        fi
        if [[ $verbose -ge 2 ]]; then
            echo "Nothing to do: this folder doesn't have a readable ok-file"
        fi
    fi
}

is_sourced=""
if [ -n "$ZSH_VERSION" ]; then
    # For zsh, check if script name matches $0
    if [[ "${(%):-%N}" == *"ok.sh" ]]; then
        is_sourced="yes_indeed"
    fi
else 
    if [ "$0" = "-bash" ]; then
        is_sourced="yes_indeed"
    fi
fi

if [ -z "$is_sourced" ]; then
    if [[ -z "$_OK__PATH_TO_PYTHON" ]]; then
        >&2 echo "ERROR: python is required to run 'ok', but can't be found"
        exit 1
    fi
    if [[ $1 == "t" || $1 == "test" ]]; then
        shift
        ok "$@"
    else
        # tip: "." (i.e. source) this file from your profile (.bashrc), e.g. ". ~/path/to/ok-sh/ok.sh"
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
    # the only way to distinguish between `. /path/to/ok.bash` and `. /path/to/ok.bash some-argument`
    if [[ ! ($# -eq 1 && $1 = "${BASH_SOURCE[0]}") ]]; then
    while (( $# > 0 )) ; do
        case $1 in
            reset)          for x in $(set | grep "^_OK_[^_]" | awk -F '=' '{print $1}'); do 
                                unset "$x"
                            done
                            if [[ $PROMPT_COMMAND =~ $re_list_once ]]; then export PROMPT_COMMAND="${PROMPT_COMMAND/$'\n'$re_list_once/}"; fi;;
            prompt)         if [[ $# -ge 2 ]]; then export _OK_PROMPT=$2; shift; else >&2 echo "the prompt argument needs the actual prompt as 2nd argument"; fi;;
            prompt_default) export _OK_PROMPT_DEFAULT=1;;
            comment_align)  if [[ $# -ge 2 ]]; then export _OK_COMMENT_ALIGN=$2; shift; else >&2 echo "the comment_align argument needs a number (0..3) as 2nd argument"; fi;;
            verbose)        export _OK_VERBOSE=2;;
            quiet)          export _OK_VERBOSE=0;;
            auto_show)      if [ -n "${ZSH_VERSION+x}" ]; then
                                function _zsh_list_once {
                                    ok list-once
                                }
                                precmd_functions+=( _zsh_list_once )
                            else
                                if [[ ! $PROMPT_COMMAND =~ $re_list_once ]]; then export PROMPT_COMMAND="${PROMPT_COMMAND}"$'\n'"${re_list_once}"; fi
                            fi;;
            *) >&2 echo "Ignoring unknown argument '$1'";;
        esac
        shift
    done
    fi
    unset re_list_once
    # export variables so `ok` can be used from scripts as well. Hereafter, exporting is the responsibility of the user.
    for x in $(set | grep "^_OK_" | awk -F '=' '{print $1}'); do 
        export "${x?}"
    done
    # Initialize auto-complete, when in Bash
    if [ -n "$BASH_VERSION" ]; then
        . "${_OK__PATH_TO_ME}/ok-complete.bash"
    fi
fi
