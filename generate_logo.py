import os
from PIL import Image, ImageDraw

def create_logo():
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # We will create a high-resolution transparent gradient logo.
    # To get anti-aliasing, we can draw at 4x size and resize.
    scale = 4
    large_size = size * scale
    mask = Image.new('L', (large_size, large_size), 0)
    draw = ImageDraw.Draw(mask)
    
    # Let's draw a nice document shape
    # Document outline: a rounded rectangle
    margin = 150 * scale
    radius = 80 * scale
    
    rect_box = [margin, margin, large_size - margin, large_size - margin]
    draw.rounded_rectangle(rect_box, radius, fill=255)
    
    # Cut out a spyglass / magnifier shape from the document
    # Or just cut out some lines for text
    line_x1 = margin + 120 * scale
    line_x2 = large_size - margin - 120 * scale
    
    # Line 1
    draw.rounded_rectangle([line_x1, margin + 180 * scale, line_x2, margin + 240 * scale], 30*scale, fill=0)
    # Line 2
    draw.rounded_rectangle([line_x1, margin + 340 * scale, line_x2, margin + 400 * scale], 30*scale, fill=0)
    # Line 3 (shorter)
    draw.rounded_rectangle([line_x1, margin + 500 * scale, line_x1 + 300 * scale, margin + 560 * scale], 30*scale, fill=0)
    
    # Magnifying glass circle on bottom right overlapping
    mag_margin_x = large_size - margin - 250*scale
    mag_margin_y = large_size - margin - 250*scale
    
    draw.ellipse([mag_margin_x, mag_margin_y, mag_margin_x + 400*scale, mag_margin_y + 400*scale], fill=0)
    draw.ellipse([mag_margin_x + 60*scale, mag_margin_y + 60*scale, mag_margin_x + 340*scale, mag_margin_y + 340*scale], fill=255)
    
    # Mag handle
    draw.line([mag_margin_x + 300*scale, mag_margin_y + 300*scale, mag_margin_x + 550*scale, mag_margin_y + 550*scale], fill=255, width=80*scale)
    
    # Resize mask with anti-aliasing
    mask = mask.resize((size, size), Image.Resampling.LANCZOS)
    
    # Create the gradient
    gradient = Image.new('RGBA', (size, size), (0,0,0,0))
    grad_pixels = gradient.load()
    
    # Blue: (21, 101, 192) to Purple: (142, 45, 226)
    c1 = (43, 88, 118)
    c2 = (142, 45, 226)
    
    # actually, blue to purple:
    c1 = (0, 150, 255)   # bright blue
    c2 = (160, 32, 240)  # purple
    
    for y in range(size):
        for x in range(size):
            factor = (x + y) / (2 * size)
            r = int(c1[0] + (c2[0] - c1[0]) * factor)
            g = int(c1[1] + (c2[1] - c1[1]) * factor)
            b = int(c1[2] + (c2[2] - c1[2]) * factor)
            grad_pixels[x, y] = (r, g, b, 255)
            
    # Apply the mask to the gradient
    img = Image.composite(gradient, img, mask)
    
    # Save the logo
    img.save('assets/icon.png', 'PNG')
    print("Logo saved successfully.")

if __name__ == '__main__':
    create_logo()
