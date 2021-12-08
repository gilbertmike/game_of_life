COE_HEADER = '''memory_initialization_radix=2;
memory_initialization_vector=
'''

def wav_to_coe(fname):
    coe = COE_HEADER
    with open(fname, 'rb') as f:
        bytes = f.read()
    for byte in bytes:
        byte = bin(byte).strip('0b')
        byte = (8-len(byte))*'0' + byte
        coe += byte + ',\n'
    return coe

if __name__ == '__main__':
    import sys
    fname = sys.argv[1]
    coe_fname = sys.argv[2]
    with open(coe_fname, 'w') as f:
        f.write(wav_to_coe(fname))
