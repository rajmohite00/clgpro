import math
from PIL import Image, ImageDraw

def create_logo():
    size = 1024
    scale = 4
    large_size = size * scale
    
    img = Image.new('RGBA', (large_size, large_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors matching the app theme
    color_ink = (5, 10, 15, 255)      # AppTheme.ink
    color_jade = (0, 255, 163, 255)   # AppTheme.jade
    color_transparent = (0, 0, 0, 0)

    # Draw dark background (for launcher icon it looks better with bg)
    # We will draw a subtle radial gradient or just solid ink color
    draw.rectangle([0, 0, large_size, large_size], fill=color_ink)
    
    center = (large_size / 2, large_size / 2)
    radius = large_size * 0.35
    
    # 1. Outer Hexagon
    hex_points = []
    for i in range(6):
        angle = math.radians(i * 60 - 30)
        x = center[0] + radius * math.cos(angle)
        y = center[1] + radius * math.sin(angle)
        hex_points.append((x, y))
    
    # Glow effect behind the hexagon
    for glow_radius in range(int(radius*1.15), int(radius*0.8), -int(10*scale)):
        glow_points = []
        for i in range(6):
            angle = math.radians(i * 60 - 30)
            x = center[0] + glow_radius * math.cos(angle)
            y = center[1] + glow_radius * math.sin(angle)
            glow_points.append((x, y))
        opacity = int(max(0, min(255, (radius*1.15 - glow_radius) / (radius*0.35) * 50)))
        draw.polygon(glow_points, outline=(0, 255, 163, opacity), width=int(10*scale))
    
    # Main Hexagon Stroke
    draw.polygon(hex_points, outline=color_jade, width=int(30 * scale))
    
    # 2. Cyber Eye - Outer Leaf
    eye_width = large_size * 0.45
    eye_height = large_size * 0.3
    
    # Approximate bezier with polygon for drawing (PIL lacks draw.bezier filled)
    def bezier_point(t, p0, p1, p2):
        return (
            (1-t)**2 * p0[0] + 2*(1-t)*t * p1[0] + t**2 * p2[0],
            (1-t)**2 * p0[1] + 2*(1-t)*t * p1[1] + t**2 * p2[1]
        )
    
    p_left = (center[0] - eye_width / 2, center[1])
    p_right = (center[0] + eye_width / 2, center[1])
    p_top = (center[0], center[1] - eye_height)
    p_bottom = (center[0], center[1] + eye_height)
    
    eye_pts = []
    for i in range(101):
        t = i / 100
        eye_pts.append(bezier_point(t, p_left, p_top, p_right))
    for i in range(101):
        t = i / 100
        eye_pts.append(bezier_point(t, p_right, p_bottom, p_left))
    
    draw.line(eye_pts, fill=color_jade, width=int(30 * scale), joint="curve")
    
    # 3. Iris (Stroke Circle)
    iris_r = large_size * 0.12
    draw.ellipse([center[0]-iris_r, center[1]-iris_r, center[0]+iris_r, center[1]+iris_r], outline=color_jade, width=int(30 * scale))
    
    # 4. Pupil (Filled Circle)
    pupil_r = large_size * 0.05
    draw.ellipse([center[0]-pupil_r, center[1]-pupil_r, center[0]+pupil_r, center[1]+pupil_r], fill=color_jade)

    # Resize with antialiasing
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # Save the logo
    img.save('assets/icon.png', 'PNG')
    print("New logo saved successfully.")

if __name__ == '__main__':
    create_logo()
