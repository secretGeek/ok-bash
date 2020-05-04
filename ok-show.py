# both python2 and python3
# -*- coding: utf-8 -*-

from __future__ import print_function
import argparse, codecs, os, re, shutil, sys

def ansi_len(s):
    no_ansi_s = rx.ansi_len.sub('', s)
    return len(no_ansi_s)

class ParsedLine:
    INDENT_CHAR=' '
    ITEM_SUFFIX=': '
    def __init__(self, t, line, name=None, pos=None, line_nr=None):
        self.t = t
        self.line = line
        self.pos = pos
        self.name = name
        self.line_nr = line_nr
        self.indent = 0

    def get_line_name_or_number(self):
        return str(self.name if self.name else self.line_nr)
            

    def set_indent(self, max_pos, max_width):
        if self.pos and max_pos:
            self.indent = max_pos - self.pos
            # if indent makes line wrap, indent less
            line_len = ansi_len(self.line)
            line_wraps = line_len > max_width
            indent_wraps = line_len+self.indent > max_width
            if not line_wraps and indent_wraps:
                self.indent = max_width - line_len
        else:
            self.indent = 0

class rx:
    heading    = re.compile('^[ \t]*(#)')
    whitespace = re.compile('^[ \t]*$')
    comment    = re.compile('(^[ \t]+)?(?<!\S)(?=#)(?!#\{)')
    named_line = re.compile('^[ \t]*([A-Za-z_][-A-Za-z0-9_]*)[ \t]*:')
    ansi_len   = re.compile('\x1b\[.*?m')

def get_env(name, default, legal_values=None):
    val = os.environ[name] if name in os.environ else default
    if type(default)==int:
        try: 
            val=int(val)
            if legal_values is not None and val not in legal_values:
                val=default
        except: 
            val=default
    return val

class ok_color:
    #TODO: need to check if colors are supported (so it can be used with `less` and others)?
    #(https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors)
    def __init__(self):
        self.nc      = '\033[0m'
        self.error   = '\033[0;33m‼️  '
        self.heading = get_env('_OK_C_HEADING', '\033[0;31m')
        self.number  = get_env('_OK_C_NUMBER',  '\033[0;36m')
        self.comment = get_env('_OK_C_COMMENT', '\033[0;34m')
        self.command = get_env('_OK_C_COMMAND', self.nc)
        self.prompt  = get_env('_OK_C_PROMPT',  self.number)

def cprint(color, text=''):
    if color: print(color, end='')
    if text:  print(text, end='')

def parse_lines(lines, internal_commands):
    #handle Unicode BOM after being decoded: https://stackoverflow.com/a/28407897/56 and https://stackoverflow.com/a/1068700/56
    if len(lines)>0 and len(lines[0])>0 and ord(lines[0][0]) == 0xFEFF: # BOM_UTF16_BE
        lines[0] = lines[0][1:]
    result = []
    line_nr = 0
    # keep track of unique names; initialize with ok's commands
    named_lines = set(internal_commands.split(','))
    for line in lines:
        line = line.strip('\n')
        heading_match=rx.heading.search(line)
        if heading_match:
            result.append(ParsedLine('heading', line, pos=heading_match.start(1)))
        elif rx.whitespace.search(line):
            result.append(ParsedLine('whitespace', line))
        else:
            line_nr += 1
            match = rx.named_line.search(line)
            if match:
                name = match.group(1)
                if name in named_lines:
                    cprint(ok_color().error, f'Duplicate name or internal commannd "{name}", mapped to line number {line_nr}.\n')
                    name = None
                else:
                    named_lines.add(name)
                    line_nr -= 1 # "roll-back" assignment of number
                line = line[match.end():]
            else:
                name = None
            match = rx.comment.search(line)
            pos = match.start() if match else None
            result.append(ParsedLine('code', line.lstrip(' \t'), name=name, line_nr=line_nr, pos=pos))
    return result

def set_indent(l, start, stop, max_pos, max_width):
    for i in range(start, stop):
        item = l[i]
        if item.t == 'code':
            item.set_indent(max_pos, max_width)

def format_lines(l, elastic_tab, nr_positions_line_nr, max_width):
    if elastic_tab == 0: return
    if elastic_tab == 1: group_reset = ['heading','whitespace']
    if elastic_tab == 2: group_reset = ['heading']
    if elastic_tab == 3: group_reset = []
    start_group = None
    for i in range(0, len(l)):
        x = l[i]
        if start_group is None and x.t not in group_reset:
            start_group = i
            max_pos = ansi_len(x.line)+1 if x.pos is None else x.pos
        if start_group is not None: # We are in a group
            if x.t == 'code':
                max_pos = max(max_pos, 0 if x.pos is None else x.pos)
            has_no_next_item = i+1>=len(l)
            if has_no_next_item or l[i+1].t in group_reset:
                max_command_width = max_width - nr_positions_line_nr - len(ParsedLine.ITEM_SUFFIX)
                # indent only at certain positions
                set_indent(l, start_group, i+1, max_pos, max_command_width)
                start_group = None #reset start code-block

def print_line(l, clr, nr_positions_line_nr, format_line):
    if l.t == 'heading':
        cprint(clr.heading, l.line)
        cprint(clr.nc, '\n')
    elif l.t == 'whitespace':
        cprint(clr.nc, l.line+'\n')
    elif l.t == 'code':
        if format_line:
            cprint(clr.number, l.get_line_name_or_number().rjust(nr_positions_line_nr, ' ') + ParsedLine.ITEM_SUFFIX)
            if l.pos is None:
                cprint(clr.command, l.line)
            else:
                cprint(clr.command, l.line[:l.pos])
                cprint(None, ParsedLine.INDENT_CHAR*l.indent)
                cprint(clr.comment, l.line[l.pos:])
            cprint(clr.nc, '\n')
        else:
            print(l.line, file=sys.stderr)

def main():
    # customizations
    clr = ok_color()

    # handle arguments
    parser = argparse.ArgumentParser(description='Show the ok-file colorized (or just one line).')
    parser.add_argument('--verbose',        '-v', metavar='V',  type=int, default=1, help='0=quiet, 1=normal, 2=verbose. Defaults to 1. ')
    parser.add_argument('--name_align',     '-n', metavar='NA', type=int, default=2, choices= [0,1,2], help='Level of number of name alignment. 0=no alignment, 1=align numbers only (Default), 2=align numbers and names.')
    parser.add_argument('--comment_align',  '-c', metavar='CA', type=int, default=2, choices= [0,1,2,3], help='Level of comment alignment. 0=no alignment, 1=align consecutive lines (Default), 2=including whitespace, 3 align all.')
    parser.add_argument('--terminal_width', '-t', metavar='TW', type=int, default=None, help='number of columns of the terminal (tput cols)')
    parser.add_argument('--internal_commands', '-I', metavar='IC', type=str, default='list,l,list-once,L,list-prompt,p,help,h', help='Internal commands of ok (that cannot be used as named lines)')

    parser.add_argument('only_line_nr',           metavar='N',  type=int, nargs='?', help='the line number to show')
    args = parser.parse_args()

    if args.terminal_width is None:
        if sys.version_info[0] >= 3:
            args.terminal_width =  shutil.get_terminal_size().columns
        else:
            # Python 2 doesn't have `get_terminal_size`
            args.terminal_width = 80

    if args.verbose > 1:
        print('  number_align: %d' % args.name_align)
        print(' comment_align: %d' % args.comment_align)
        print('terminal_width: %d' % args.terminal_width)
        print('python version: '+ sys.version.replace('\n', '\t'))

    # prepare (read stdin parse, transform, and calculate stuff)
    # Unicode: best to ignore other encodings? SO doesn't seem to give good advice
    # See https://stackoverflow.com/q/2737966/56
    try:
        lines = sys.stdin.readlines()
    except UnicodeDecodeError as err:
        print('ERROR: UTF-8 (unicode) should be used as sole encoding for .ok-files', file=sys.stderr)
        if args.verbose > 1:
            print('UnicodeDecodeError exception properties (error on: %s):' % err.object[err.start:err.end], file=sys.stderr)
            print('* encoding: %s' % err.encoding, file=sys.stderr)
            print('* reason__: %s' % err.reason,   file=sys.stderr)
            print('* object__: %s' % err.object,   file=sys.stderr)
            print('* start___: %s' % err.start,    file=sys.stderr)
            print('* end_____: %s' % err.end,      file=sys.stderr)
        exit(1)
    p_lines = parse_lines(lines, args.internal_commands)
    # Calculate max with of numbers (optionally names)
    if args.name_align == 1:
        cmd_lines = [pl.line_nr for pl in p_lines if pl.line_nr]
    elif args.name_align == 2:
        cmd_lines = [pl.get_line_name_or_number() for pl in p_lines]
    else:
        cmd_lines = []
    nr_positions_line_nr = len(str(max(cmd_lines))) if len(cmd_lines)>0 else 0
    format_lines(p_lines, args.comment_align, nr_positions_line_nr, args.terminal_width)

    # execute
    if args.only_line_nr is None:
        for p_line in p_lines:
            print_line(p_line, clr, nr_positions_line_nr, True)
        if len(cmd_lines) == 0:
            sys.exit(1)
    else:
        # swap stdout and stderr (the calling shell-script needs a unformated string, and we need to print something to the display as well)
        (sys.stdout, sys.stderr) = (sys.stderr, sys.stdout)
        try:
            p_line = next(x for x in p_lines if x.t=='code' and x.line_nr==args.only_line_nr)
        except StopIteration:
            if args.verbose >= 2: print("ERROR: entered line number '{}' does not exist".format(args.only_line_nr))
            sys.exit(2)
        # The formated line is printed to stdout, and the actual line from .ok is printed to stderr
        if args.verbose > 0: print_line(p_line, clr, nr_positions_line_nr, True)
        print_line(p_line, clr, nr_positions_line_nr, False)


if __name__ == "__main__":
    main()


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