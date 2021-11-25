import sys
from PIL import Image

coe_hdr = '''memory_initialization_radix=2;
memory_initialization_vector=
'''

def pix_to_bin(pix):
    if pix == 0:
        return '0'
    else:
        return '1'

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: {0} <image to convert> <coe path>'.format(sys.argv[0]))
    else:
        fname = sys.argv[1]
        coe_fname = sys.argv[2]
        img = Image.open(fname)
        cimg = img.convert('1')  # convert to black and white

        (w, h) = cimg.size
        with open(coe_fname, 'w') as f:
            f.write(coe_hdr)
            for y in range(h):
                for x in range(w):
                    f.write(pix_to_bin(cimg.getpixel((x, y))) + ',\n')

