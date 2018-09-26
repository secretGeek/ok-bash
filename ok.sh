#!/usr/bin/env bash

called=$_

#basically, get the absolute path of this script (handy for loads of things)
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null;
_OK__PATH_TO_ME=$(pwd)
popd > /dev/null;


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
  -v, --verbose       Show more output, most of the time to stderr.
  -q, --quiet         Only show really necessary output.
  -f, --file <file>   Use a custom file instead of '.ok'.
  -a, --alias <name>  When using 'ok' in an alias, <name> is used to keep the history correct when used with 'list-prompt'.
script-arguments:
  ...                 These are passed through, when a line is executed (you can enter these too at the ok-prompt)\\n"

        if [[ $verbose -ge 2 ]]; then
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
  _OK_PROMPT         String ($p) used as prompt (both input as command confirmation). Defaults to '$ '.
  _OK_PROMPT_DEFAULT Setting ($l) if the prompt is default shown. 1=use command list-prompt when issuing no command, otherwise use list.
  _OK_VERBOSE        Level ($v) of feedback ok provides. 0=quiet, 1=normal, 2=verbose. Defaults to 1. Can be overriden with --verbose or --quiet.
environment variables (for internal use):
  _OK__LAST_PWD      Remember the path ($_OK__LAST_PWD) that was last listed, for use with the list-once command.
  _OK__PATH_TO_ME    The path ($_OK__PATH_TO_ME) to the location of this script.\\n"
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
        local line_text=$(grep -vE "^(#|$)" < "$ok_file" | sed "${line_nr}"'!d' )
        if [[ -n $line_text ]]; then
            if [[ $verbose -ge 1 ]]; then
                # output the command first
                echo -e "${c_prompt}${prompt}${c_command}${line_text}${c_nc}" | sed -E "s/(#.*)\$/${c_comment}\\1/1"
            fi
            # finally execute the line
            eval "$line_text"
        else
            if [[ $verbose -ge 2 ]]; then
                >&2 echo "ERROR: entered line number '$line_nr' does not exist"
            fi
            return 1
        fi
    }

    function _ok_cmd_list {
        unset -f _ok_cmd_list
        # determine number of command lines
        nr_lines=$(grep -Ec "^[^#]" < "$ok_file")

        # list the content of the file, with a number (1-based) before each line, except lines starting with a
        # (optionally indented) "#", those are printed red without a number) as headers. Empty lines are headers too.
        awk -v h="$c_heading" -v n="$c_number" -v c="$c_comment" -v m="$c_command" -v x="$c_nc" -v P="${#nr_lines}" $'
            NR == 1 {
                #handle UTF-8 BOMs: https://stackoverflow.com/a/1068700/56
                sub(/^\\xEF\\xBB\\xBF/,"")
            }
            $0 ~ /^[ \\t]*(#|$)/ {
                #print the (sub-)headings and/or empty lines
                print x h $0 x;
            }
            $0 ~ /^[ \\t]*[^# \\t]/ {
                #print the commands
                sub(/#/,c "#");
                NR = sprintf("%" P "d.", ++i);
                print x n NR m " " $0 x;
            }' < "$ok_file"
    }

    # used for colored output (see: https://stackoverflow.com/a/20983251/56)
    local c_nc=$(tput sgr 0)
    if [ -z ${_OK_C_HEADING+x} ]; then local c_heading=$(tput setaf 1); else local c_heading=$_OK_C_HEADING; fi #HEADING defaults to RED
    if [ -z ${_OK_C_NUMBER+x} ];  then local c_number=$(tput setaf 6);  else local c_number=$_OK_C_NUMBER;   fi #NUMBER defaults to CYAN
    if [ -z ${_OK_C_COMMENT+x} ]; then local c_comment=$(tput setaf 4); else local c_comment=$_OK_C_COMMENT; fi #COMMENT defaults to BLUE
    if [ -z ${_OK_C_COMMAND+x} ]; then local c_command=$c_nc;           else local c_command=$_OK_C_COMMAND; fi #COMMAND defaults to NO COLOR
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
    local show_prompt=${_OK_PROMPT_DEFAULT}
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
                -\? | -h | --help) cmd=usage;;
                -v | --verbose)    verbose=2;;
                -q | --quiet)      verbose=0;;
                -f | --file)       if [[ $# -gt 1 && -r "$2" ]]; then ok_file="$2"; shift; else _ok_cmd_usage "No file provided, or file is not readable ($2)" || return $?; fi;;
                -a | --alias)      if [[ $# -gt 1 && -n "$2" ]]; then args="$2"; shift; else _ok_cmd_usage "Empty or no alias provided" || return $?; fi;;
                *)                 cmd=usage; usage_error="Unknown command/option '$1'";;
            esac
        fi
        shift
    done

    if [[ $cmd == usage ]]; then
        _ok_cmd_usage "$usage_error" || return $?
    elif [ -r "$ok_file" ]; then
        if [[ $cmd == run ]]; then
            _ok_cmd_run "$line_nr" "$@" || return $?
        elif [[ $cmd == list ]]; then
            if [[ $once_check == 0 || ($once_check == 1 && $_OK__LAST_PWD != $(pwd)) ]]; then
                _ok_cmd_list || return $?
                if [[ $show_prompt == 1 ]]; then
                    local prompt_input
                    local re_num_begin='^[1-9][0-9]*($| )' # You can enter arguments at the ok-prompt too, hence different regex
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
    # tip: "." (i.e. source) this file from your profile (.bashrc), e.g. ". ~/path/to/ok-bash/ok.sh"
    echo 'tip: "." (i.e. source) this file from your profile (.bashrc), e.g. ". '"${_OK__PATH_TO_ME}"'/ok.sh"'
    echo
    echo "arguments, if you need to customize (these can also be set via arguments/environment):"
    echo "  prompt <prompt> Use the supplied prompt (e.g. prompt '> ')"
    echo "  prompt_default  Prompt default when issueing running ok without arguments"
    echo "  auto_show       Perform 'ok list-once' every time the prompt is shown (modifies \$PROMPT_COMMAND)"
    echo "  verbose         Enable verbose mode"
    echo "  quiet           Enable quiet mode"
    echo
else
    # Reset all used environment variables
    unset _OK_C_HEADING; unset _OK_C_NUMBER; unset _OK_C_COMMENT; unset _OK_C_COMMAND; unset _OK_C_PROMPT
    unset _OK_PROMPT; unset _OK_PROMPT_DEFAULT; unset _OK_VERBOSE; unset _OK__LAST_PWD
    # Process some installation helpers
    re_list_once=$'ok list-once'
    while (( $# > 0 )) ; do
        case $1 in
            prompt) if [[ $# -ge 2 ]]; then export _OK_PROMPT=$2; shift; else echo "the prompt argument needs the actual prompt as 2nd argument"; fi;;
            prompt_default) export _OK_PROMPT_DEFAULT=1;;
            verbose)        export _OK_VERBOSE=2;;
            quiet)          export _OK_VERBOSE=0;;
            auto_show)      if [[ ! $PROMPT_COMMAND =~ $re_list_once ]]; then export PROMPT_COMMAND="$PROMPT_COMMAND
$re_list_once"; fi;;
            *) echo "Ignoring unknown argument '$1'";;
        esac
        shift
    done
    unset re_list_once
fi
unset called
