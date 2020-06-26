: <<'TEST_COMMENTS'

- `ok [TAB][TAB]`: show all internal and named commands
- `ok -[TAB]`: expands to `ok --[BEL]`
- `ok --[TAB][TAB]`: show all long form options (same as options in `ok -h`)
- `ok --a[TAB]`: expands to `ok --alias `
- `ok --alias [TAB]`: doesn't expand; `[BEL]`, because after `--alias` a `<name>` is expected which can't be auto-completed.
- `ok --comment-align [TAB][TAB]`: shows a slider you can adjust with your trackpad; ehm.... sorry, doesn't expand; `[BEL]` ;-)
- `ok -c 2[TAB][TAB]`: doesn't expand; same reason
- `ok -c 2 [TAB][TAB]`: show all internal and named commands
- `ok --file [TAB][TAB]`: shows all files in current folder
- `ok --file test/[TAB][TAB]`: shows all files in the folder `test`
- `ok --file test/.ok-[TAB]`: extands to `ok --file test/.ok-sh`
- `ok li[TAB]`: extands to `ok list[BEL]`
- `ok list -[TAB]`: doesn't expand (options after command are passed through.
    + no support for options after internal commands for now

TEST_COMMENTS

_ok_complete_bash() 
{
	local double_options i prev_opts cur opts
	COMPREPLY=()
	# options that need an additional argument 
	double_options="^(-c|--comment-align|-f|--file|-a|--alias)$"
	((i=1)) # first word is always "ok", so start at 1
	while [[ $i -lt ${COMP_CWORD} ]]; do
		# Previous arguments need to be options (prefixed with a dash)
		if [[ "${COMP_WORDS[$i]}" != -* ]]; then
			# Unless it's an argument that need an 2nd argument as value
			if [[ ! "${COMP_WORDS[$i-1]}" =~ $double_options ]]; then
				return 0 # Nothing to complete
			fi
		fi
		((i+=1))
	done
	cur="${COMP_WORDS[$COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	if [[ $prev =~ $double_options ]]; then
		if [[ $prev == "--file" || $prev == "-f" ]]; then
			COMPREPLY=( $(compgen -f "${cur}") )
		fi
	else
		if [[ $cur == -* ]]; then
			opts="$(ok --sys-opts)" #only show options, when a dash is entered
		else
			opts="$(ok --sys-cmds)" #only show commands, no options, when no dash is entered
		fi
		COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
	fi
}
complete -F _ok_complete_bash ok
