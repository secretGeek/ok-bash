#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function
import argparse, os, re, sys


class ParsedLine:
    def __init__(self, t, line, pos=None, line_nr=None):
        self.t = t
        self.line = line
        self.pos = pos
        self.line_nr = line_nr

def get_env(name, default):
    return os.environ[name] if name in os.environ else default

def cprint(color, text=''):
    print(color+text, end='')

def parse_lines(lines):
    result = []
    line_nr = 0
    for line in lines:
        heading_match=re_heading.search(line)
        if heading_match:
            result.append(ParsedLine('heading', line, pos=heading_match.start(1)))
        elif re_whitespace.search(line):
            result.append(ParsedLine('whitespace', line))
        else:
            line_nr += 1
            match = re_comment.search(line)
            if match:
                result.append(ParsedLine('code', line, line_nr=line_nr, pos=match.start()))
            else:
                result.append(ParsedLine('code', line, line_nr=line_nr))
    return result

def print_line(l, nr_positions_line_nr, format_line):
    if l.t == 'heading':
        cprint(c_heading, l.line)
    elif l.t == 'whitespace':
        cprint(c_nc, l.line)
    elif l.t == 'code':
        if format_line:
            cprint(c_number, '{:{}}. '.format(l.line_nr, nr_positions_line_nr))
            if l.pos is None:
                cprint(c_command, line)
            else:
                cprint(c_command, l.line[:l.pos])
                cprint(c_comment, l.line[l.pos:])
        else:
            cprint(c_nc, l.line)

re_heading = re.compile('^[ \t]*(#)')
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
elastic_tab = get_env('_OK_ELASTIC_TAB', 1) # 0:none, 1: sync consecutive commenst, 2: sync all comments
#OPTION FOR IGNORING VERY FAR INDENTED COMMENTS IF IT'S ONLY ONE OR TWO. NO INDENT OR POSSIBLY "HANING INDENT"
#OPTION FOR RIGHT PADDING COMMENTS WITH SPACES, WHEN BACKGROUND COLOR HAS BEEN ADDED (both headings and comments)

#arguments
parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--line-only', '-l', action='store_true', default=False, help='Do not show prompt or colors with N')
parser.add_argument('only_line_nr', metavar='N', type=int, nargs='?', help='the line number to show')
args = parser.parse_args()

lines = sys.stdin.readlines()
p_lines = parse_lines(lines)
nr_positions_line_nr = len(str(max([pl.line_nr for pl in p_lines if pl.line_nr])))

if args.only_line_nr is None:
    for p_line in p_lines:
        print_line(p_line, nr_positions_line_nr, not args.line_only)
else:
    p_line = next(x for x in p_lines if x['t']=='code' and x['nr']==args.only_line_nr)
    print_line(p_line, nr_positions_line_nr, args.line_only)
    

'''
Parsing of comments is not yet perfect. It's also quite complicated. 
See also:
   http://www.apeth.com/nonblog/stories/textmatebundle.html
   https://github.com/stedolan/jq/wiki/Docs-for-Oniguruma-Regular-Expressions-(RE.txt)

Some notes:
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