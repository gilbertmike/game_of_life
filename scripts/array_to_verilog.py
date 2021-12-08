import glob
import os

SEED_SIZE = 50

def get_header(name):
    return '''`default_nettype none
module {}(input wire[5:0] x_in,
               input wire[5:0] y_in,
               output logic alive_out);
    always_comb begin
        case ({{x_in, y_in}})
'''.format(name)

FOOTER = '''
            default: alive_out = 0;
        endcase
    end
endmodule
`default_nettype wire
'''

SELECTOR_HEADER = '''`default_nettype none
module seed_select(input wire[4:0] seed_idx,
                   input wire[5:0] x_in,
                   input wire[5:0] y_in,
                   output logic alive_out);
'''

SELECTOR_FOOTER = '''    assign alive_out = alive[seed_idx];
endmodule
`default_nettype wire
'''

LOGIC_ALIVE_TEMPLATE = '    logic alive[0:{}];\n'
MODULE_TEMPLATE = \
    '    {0} s{1}(.x_in(x_in), .y_in(y_in), .alive_out(alive[{1}]));\n'

def rle_to_arr(lines):
    nrow = 0
    ncol = 0
    rle = ''
    for l in lines:
        l = str(l).strip('b').strip("'")
        if l[0] == '#':
            continue
        if l[0] == 'x':
            specs = l.split(',')
            for s in specs:
                s = s.split('=')
                if s[0].strip() == 'x':
                    ncol = int(s[1].strip())
                elif s[0].strip() == 'y':
                    nrow = int(s[1].strip())
        else:
            rle += l

    assert nrow <= SEED_SIZE and ncol <= SEED_SIZE, 'Too big for seed!'

    pad_left = (SEED_SIZE - ncol) // 2
    pad_right = SEED_SIZE - ncol - pad_left
    pad_top = (SEED_SIZE - nrow) // 2
    pad_bottom = SEED_SIZE - nrow - pad_top

    array = [[0]*SEED_SIZE]*pad_top
    row = [0]*pad_left
    num = 0
    for c in rle:
        if c.isnumeric():
            num = num*10 + int(c)
        elif c == '$':
            row += [0]*(SEED_SIZE - len(row))
            array.append(row)
            row = [0]*pad_left
            num = 0
        elif c == '!':
            row += [0]*(SEED_SIZE - len(row))
            array.append(row)
            array += [[0]*SEED_SIZE]*(SEED_SIZE-len(array))
            assert SEED_SIZE == len(array) and SEED_SIZE == len(array[0]), 'Parsing error!'
            return array
        elif c == 'b':
            if num == 0:
                row += [0]
            else:
                row += [0]*num
                num = 0
        elif c == 'o':
            if num == 0:
                row += [1]
            else:
                row += [1]*num
                num = 0
        else:
            assert False, 'Parsing error! Unknown char.'

def array_to_verilog(name, arr):
    prog = get_header(name)
    for x in range(SEED_SIZE):
        for y in range(SEED_SIZE):
            if arr[y][x] == 1:
                prog += '            '
                prog += "{6'd" + str(x) + ", 6'd" + str(y) + '}: '
                prog += 'alive_out = 1;\n'
    prog += FOOTER
    return prog

def rle_to_verilog(name, lines):
    return array_to_verilog(name, rle_to_arr(lines))

def rle_file_to_verilog(fname):
    name = fname.split('/')[-1].split('.')[0]
    lines = []
    with open(fname, 'rb') as f:
        l = f.readline()
        while l:
            lines.append(l)
            l = f.readline().strip(b'\n\r')

    return name, rle_to_verilog(name, lines)

def rle_dir_to_verilog(dirname):
    all_modules = ''
    module_names = []
    for fname in glob.iglob(os.path.join(dirname, '*.rle')):
        try:
            name, module = rle_file_to_verilog(fname)
            all_modules += module
            module_names.append(name)
        except Exception as e:
            print(str(e))
            print('Failed to parse ', fname)

    final = all_modules
    final += SELECTOR_HEADER
    final += LOGIC_ALIVE_TEMPLATE.format(len(module_names)-1)
    for i, n in enumerate(module_names):
        final += MODULE_TEMPLATE.format(n, i)
    final += SELECTOR_FOOTER

    return final

if __name__ == '__main__':
    import sys
    dirname = sys.argv[1]
    res_fname = sys.argv[2]
    with open(res_fname, 'w') as f:
        f.write(rle_dir_to_verilog(dirname))

