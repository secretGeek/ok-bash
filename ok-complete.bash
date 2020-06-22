_ok_complete_bash() 
{
	local f cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	opts="$(ok --sys-cmds)" #commands

	if [[ ${cur} != -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
		return 0
	fi
}
complete -F _ok_complete_bash ok
echo "ok-bash autocomplete initialized"
