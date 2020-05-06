#!/usr/bin/env python3

class ParsedLine:
    INDENT_CHAR=' '
    ITEM_SUFFIX=': '
    def __init__(self, t, line, name=None, pos=None, line_nr=None):
        self.t = t
        self.line = line
        self.pos = pos
        self.name = name
        self.line_nr = line_nr if name is None else 0
        self.indent = 0

    def match_command(self, command):
        #print('> {}-{}-{}-{}-'.format(self.t, self.name, self.line_nr, self.line))
        if self.t != 'code': return False
        if str(self.line_nr) == command: return True
        if self.name and self.name[:len(command)] == command: return True
        return False

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


def ding(x):
    return x.name

p_lines = []
#p_lines.append(ParsedLine('whitespace', '', name=None, line_nr=0, pos=None))
p_lines.append(ParsedLine('code', 'echo "Install"', name='install', line_nr=0, pos=None))
p_lines.append(ParsedLine('code', 'echo "HEY!!! (inst)"', name='inst', line_nr=0, pos=None))
p_lines.append(ParsedLine('code', 'echo "HEY! (in)"', name='in', line_nr=0, pos=None))


all_names = [p_line.name for p_line in p_lines if p_line.name]

for p in [p_line for p_line in p_lines if p_line.name]:
    shortest = ''
    for ch in p.name:
        shortest += ch
        alternatives = [n for n in all_names if n[:len(shortest)]==shortest]
        if len(alternatives)==1: 
            break
    p.shortest = shortest


print('All names')
for p in p_lines:
    print('- {}'.format(p.shortest), end='')
    if len(p.shortest)<len(p.name):
        print('[{}]'.format(p.name[len(p.shortest):]), end='')
    print(': {}'.format(p.line))
