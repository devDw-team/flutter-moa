#!/usr/bin/env python3
"""
Convert SVG to PNG for splash screen
Requires: pip install cairosvg pillow
"""

import os
try:
    import cairosvg
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Installing required packages...")
    os.system("pip install cairosvg pillow")
    import cairosvg
    from PIL import Image, ImageDraw, ImageFont

def create_splash_png():
    # Create a splash screen PNG
    width = 512
    height = 512
    
    # Create image with gradient background
    img = Image.new('RGB', (width, height), '#66BB6A')
    draw = ImageDraw.Draw(img)
    
    # Create gradient effect
    for i in range(height):
        # Gradient from #4CAF50 to #66BB6A to #81C784
        if i < height // 3:
            r = int(76 + (102 - 76) * (i / (height // 3)))
            g = int(175 + (187 - 175) * (i / (height // 3)))
            b = int(80 + (106 - 80) * (i / (height // 3)))
        elif i < 2 * height // 3:
            r = int(102 + (129 - 102) * ((i - height // 3) / (height // 3)))
            g = int(187 + (199 - 187) * ((i - height // 3) / (height // 3)))
            b = int(106 + (132 - 106) * ((i - height // 3) / (height // 3)))
        else:
            r = 129
            g = 199
            b = 132
        
        draw.rectangle([(0, i), (width, i + 1)], fill=(r, g, b))
    
    # Draw white circle in center
    center_x = width // 2
    center_y = height // 2
    radius = 120
    
    # Draw white circle background
    draw.ellipse(
        [(center_x - radius, center_y - radius), 
         (center_x + radius, center_y + radius)],
        fill='white'
    )
    
    # Draw chart bars
    bar_width = 30
    bar_colors = ['#4CAF50', '#66BB6A', '#81C784']
    bar_heights = [60, 90, 70]
    bar_x_positions = [center_x - 60, center_x - 15, center_x + 30]
    
    for i, (x, height_bar, color) in enumerate(zip(bar_x_positions, bar_heights, bar_colors)):
        y = center_y + 20 - height_bar // 2
        draw.rounded_rectangle(
            [(x, y), (x + bar_width, y + height_bar)],
            radius=5,
            fill=color
        )
    
    # Draw circular progress
    progress_radius = 40
    progress_center_y = center_y - 50
    
    # Draw progress circle background
    draw.ellipse(
        [(center_x - progress_radius, progress_center_y - progress_radius),
         (center_x + progress_radius, progress_center_y + progress_radius)],
        outline='#4CAF50',
        width=6
    )
    
    # Draw Won symbol
    try:
        # Try to use a font that supports Won symbol
        from PIL import ImageFont
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
    except:
        font = ImageFont.load_default()
    
    draw.text((center_x, progress_center_y), "₩", fill='#4CAF50', anchor='mm', font=font)
    
    # Save the splash logo
    img.save('assets/icons/splash_logo.png', 'PNG')
    print("Created splash_logo.png")
    
    # Create a simple version for Android 12
    img_simple = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw_simple = ImageDraw.Draw(img_simple)
    
    # White circle with logo
    draw_simple.ellipse(
        [(256 - 120, 256 - 120), (256 + 120, 256 + 120)],
        fill='white'
    )
    
    # Simplified bars
    for i, (x, height_bar, color) in enumerate(zip(bar_x_positions, bar_heights, bar_colors)):
        y = 256 + 20 - height_bar // 2
        draw_simple.rounded_rectangle(
            [(x, y), (x + bar_width, y + height_bar)],
            radius=5,
            fill=color
        )
    
    img_simple.save('assets/icons/splash_logo_android12.png', 'PNG')
    print("Created splash_logo_android12.png")

if __name__ == "__main__":
    create_splash_png()
    print("\nSplash screen PNGs created successfully!")
    print("Now run: flutter pub run flutter_native_splash:create")