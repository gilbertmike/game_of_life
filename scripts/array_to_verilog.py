SEED_SIZE = 50

HEADER = '''
`default_nettype none
module pattern(input wire[5:0] x_in,
               input wire[5:0] y_in,
               output logic alive_out);
    always_comb begin
        case ({x_in, y_in})
'''

FOOTER = '''
            default: alive_out = 0;
        endcase
    end
endmodule
`default_nettype wire
'''

def pattern_plaintext_to_arr(text, nrow, ncol):
    left_pad = (SEED_SIZE - ncol) // 2
    right_pad = SEED_SIZE - left_pad - ncol
    top_pad = (SEED_SIZE - nrow) // 2
    bottom_pad = SEED_SIZE - top_pad - nrow

    def convert(c):
        if c == 'O':
            return 1
        else:
            return 0

    arr = [[0]*SEED_SIZE]*top_pad
    text_idx = 0
    for r in range(nrow):
        col = [0]*left_pad
        for c in text[text_idx:text_idx+ncol]:
            col.append(convert(c))
        col += [0]*right_pad
        arr.append(col)
        text_idx += ncol
    arr += [[0]*SEED_SIZE]*bottom_pad
    return arr

def array_to_verilog(arr):
    print(len(arr))
    prog = HEADER
    for x in range(SEED_SIZE):
        for y in range(SEED_SIZE):
            if arr[y][x] == 1:
                prog += '            '
                prog += "{6'd" + str(x) + ", 6'd" + str(y) + '}: '
                prog += 'alive_out = 1;\n'
    prog += FOOTER
    return prog

def plaintext_to_verilog(text, nrow, ncol):
    print(array_to_verilog(pattern_plaintext_to_arr(text, nrow, ncol)))

pattern = '''..OOO...OOO

O....O.O....O
O....O.O....O
O....O.O....O
..OOO...OOO

..OOO...OOO
O....O.O....O
O....O.O....O
O....O.O....O

..OOO...OOO'''

plaintext_to_verilog(pattern, 12, 6)

