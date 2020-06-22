_ok_complete_bash() 
{
	local double_options i prev_opts cur opts
	COMPREPLY=()
	double_options="^(-c|--comment-align|-f|--file|-a|--alias)$" # options that need an additional argument 
	prev_opts=1 #1 if all previous words are options (start with a dash)
	((i=1)) # first word is always "ok"
	while [[ $i -lt ${COMP_CWORD} ]]; do
		if [[ "${COMP_WORDS[$i]}" != -* ]]; then
			prev_opts=0
			break
		fi
		((i+=1))
	done
	if [[ $prev_opts == 1 ]]; then
		cur="${COMP_WORDS[$COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD-1]}"
		if [[ ! $prev =~ $double_options ]]; then
			opts="$(ok --sys-opts) $(ok --sys-cmds)" #all options and commands, space seperated
			COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
			return 0
		fi
	fi
}
complete -F _ok_complete_bash ok
