#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function
import os, re, sys

def get_env(name, default):
    return os.environ[name] if name in os.environ else default

def cprint(color, text=''):
    print(color+text, end='')

re_heading = re.compile('^[ \t]*#')
re_whitespace = re.compile('^[ \t]*$')
re_comment = re.compile('(^[ \t]+)?(?<!\S)(?=#)(?!#\{)')
# used for colored output
c_nc      = '\033[0m'
c_heading = get_env('OK_C_HEADING', '\033[0;31m')
c_number  = get_env('OK_C_NUMBER',  '\033[0;36m')
c_comment = get_env('OK_C_COMMENT', '\033[0;34m')
c_command = get_env('OK_C_COMMAND', c_nc)
c_prompt  = get_env('OK_C_PROMPT',  c_number)

lines = sys.stdin.readlines()
line_nr = 0
nr_positions_line_nr = len(str(len(lines)))
for line in lines:
    if re_heading.search(line):
        cprint(c_heading, line)
    elif re_whitespace.search(line):
        cprint(c_nc, line)
    else:
        line_nr+=1
        cprint(c_number, '{:{}}. '.format(line_nr, nr_positions_line_nr))
        match = re_comment.search(line)
        if match:
            pos = match.start()
            cprint(c_command, line[:pos])
            cprint(c_comment, line[pos:])
        else:
            cprint(c_command, line)
    cprint(c_nc)

# http://www.apeth.com/nonblog/stories/textmatebundle.html
# https://github.com/stedolan/jq/wiki/Docs-for-Oniguruma-Regular-Expressions-(RE.txt)
'''
In what parts of a bash-line can a #-sign occur:
    - comment
    - interpolation:
        * $()
        * ``
        * $(())   #but how does this work?
    - variables:
      * $# 
      * ${#xxx}
    - string
      * \#
      * double quoted string: variabele/interpolation
'''