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
    val = os.environ[name] if name in os.environ else default
    if type(default)==int:
        try: val=int(val)
        except: val=default
    return val

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
    if elastic_tab == 1: group_reset = ['heading','whitespace']
    if elastic_tab == 2: group_reset = ['heading']
    if elastic_tab == 3: group_reset = []
    start_group = None
    for i in range(0, len(l)):
        x = l[i]
        if start_group is None and x.t not in group_reset:
            start_group = i
            max_pos = x.pos
        if start_group is not None: # We are in a group
            if x.t == 'code':
                max_pos = max(max_pos, x.pos)
            has_no_next_item = i+1>=len(l)
            if has_no_next_item or l[i+1].t in group_reset:
                set_indent(l, start_group, i+1, max_pos)
                start_group = None #reset start code-block

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
                cprint(c_nc, ' '*l.indent)
                cprint(c_comment, l.line[l.pos:])
            cprint(c_nc, '')
        else:
            print(l.line)


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
comment_align = get_env('_OK_COMMENT_ALIGN', 1)
if comment_align<0 or comment_align>3: comment_align=0
#OPTION FOR IGNORING VERY FAR INDENTED COMMENTS IF IT'S ONLY ONE OR TWO. NO INDENT OR POSSIBLY "HANING INDENT"
#OPTION FOR RIGHT PADDING COMMENTS WITH SPACES, WHEN BACKGROUND COLOR HAS BEEN ADDED (both headings and comments)

#arguments
parser = argparse.ArgumentParser(description='Show the ok-file colorized (or just one line).')
parser.add_argument('--line-only', '-l', action='store_true', default=False, help='Do not show prompt or colors with N')
parser.add_argument('only_line_nr', metavar='N', type=int, nargs='?', help='the line number to show')
args = parser.parse_args()

lines = sys.stdin.readlines()
p_lines = parse_lines(lines)
nr_positions_line_nr = len(str(max([pl.line_nr for pl in p_lines if pl.line_nr])))
format_lines(p_lines, comment_align)

if args.only_line_nr is None:
    for p_line in p_lines:
        print_line(p_line, nr_positions_line_nr, not args.line_only)
else:
    p_line = next(x for x in p_lines if x.t=='code' and x.line_nr==args.only_line_nr)
    print_line(p_line, nr_positions_line_nr, not args.line_only)
    

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