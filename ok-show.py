#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function
import argparse, os, re, sys


def get_env(name, default):
    return os.environ[name] if name in os.environ else default

def cprint(color, text=''):
    print(color+text, end='')

def create_comment_pos_list(lines):
    result = []
    for line in lines:
        heading_match=re_heading.search(line)
        if heading_match:
            result.append(heading_match.start(1))
        elif re_whitespace.search(line):
            result.append(-1)
        else:
            comment_match = re_comment.search(line)
            if comment_match:
                result.append(comment_match.start())
            else:
                result.append(-1)
    return result

def print_line(line, comment_pos):
    global line_nr
    if re_heading.search(line):
        if args.only_line_nr is not None: 
            return
        cprint(c_heading, line)
    elif re_whitespace.search(line):
        if args.only_line_nr is not None: 
            return
        cprint(c_nc, line)
    else:
        line_nr+=1
        if args.only_line_nr is not None and args.only_line_nr != line_nr: 
            return
        if args.line_only:
            print(line)
            return
        if args.only_line_nr is None:
            cprint(c_number, '{:{}}. '.format(line_nr, nr_positions_line_nr))
        else:
            cprint(c_prompt, prompt)
        match = re_comment.search(line)
        if match:
            pos = match.start()
            cprint(c_command, line[:pos])
            indent = ' '*(comment_pos-pos)
            cprint(c_comment, indent+line[pos:])
        else:
            cprint(c_command, line)
    cprint(c_nc)
    return

re_heading = re.compile('^[ \t]*#')
re_whitespace = re.compile('^[ \t]*$')
re_comment = re.compile('(^[ \t]+)?(?<!\S)(?=#)(?!#\{)')
# used for colored output
c_nc      = '\033[0m'
c_heading = get_env('_OK_C_HEADING', '\033[0;31m')
c_number  = get_env('_OK_C_NUMBER',  '\033[0;36m')
c_comment = get_env('_OK_C_COMMENT', '\033[0;34m')
c_command = get_env('_OK_C_COMMAND', c_nc)
c_prompt  = get_env('_OK_C_PROMPT',  c_number)
# other customizations
prompt    = get_env('_OK_PROMPT',  '$ ')
verbose   = get_env('_OK_VERBOSE',  1)
#arguments
parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--line-only', action='store_true', default=False, help='Do not show prompt or colors with N')
parser.add_argument('only_line_nr', metavar='N', type=int, nargs='?', help='the line number to show')
args = parser.parse_args()

lines = sys.stdin.readlines()
line_nr = 0
nr_positions_line_nr = len(str(len(lines)))
comment_pos_list = create_comment_pos_list(lines)
for line in lines:
    print_line(line, max(comment_pos_list))

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