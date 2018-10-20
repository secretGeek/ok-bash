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
        self.indent = 0

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

def set_indent(l, start, stop, max_pos):
    for i in range(start, stop):
        item = l[i]
        if item.t == 'code':
            item.indent = max_pos - item.pos

def format_lines(l, elastic_tab):
    if elastic_tab == 0: return
    if elastic_tab == 1 or elastic_tab == 2:
        first_code_pos = None
        for i in range(0, len(l)):
            x = l[i]
            if first_code_pos is None: #find the first line of a code-block
                if x.t == 'code':
                    first_code_pos = i
                    max_pos = x.pos
            if first_code_pos is not None:
                if x.t == 'code' or (x.t == 'whitespace' and elastic_tab == 2):
                    if x.t == 'code':
                        max_pos = max(max_pos, x.pos)
                    # Test if this is the last line in the block
                    if i+1 >= len(l) or (elastic_tab == 1 and l[i+1].t != 'code') or (elastic_tab == 2 and l[i+1].t != 'code' and l[i+1].t != 'whitespace'):
                        set_indent(l, first_code_pos, i+1, max_pos)
                        first_code_pos = None #reset start code-block
    elif elastic_tab == 3:
        max_pos = max([x.pos for x in l if x.t == 'code'])
        set_indent(l, 0, len(l), max_pos)

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
                #cprint(c_nc, '{}:{}:'.format(l.pos, l.indent))
                cprint(c_command, l.line[:l.pos])
                cprint(c_nc, ' '*l.indent)
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
elastic_tab = get_env('_OK_ELASTIC_TAB', 1) # 0:none, 1: sync consecutive commenst, 2: same, but whitespace also syncs (headline breaks sync) 3: sync all comments
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
format_lines(p_lines, elastic_tab)

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