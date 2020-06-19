_ok_complete_bash() 
{
	local f ok_file cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	# determine .ok filename, set to /dev/null when no file found (so we get internal commands at least)
	for f in .ok-sh .ok /dev/null; do
		if [[ -r "$f" ]]; then
			ok_file="$f"
			break # found
		fi
	done
	opts="$("${_OK__PATH_TO_PYTHON:-$(command -v python3 || command -v python)}" "${_OK__PATH_TO_ME}/ok-show.py" ".list_commands" < "$ok_file")"

	if [[ ${cur} != -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
		return 0
	fi
}
complete -F _ok_complete_bash ok
