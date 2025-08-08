#!/usr/bin/env python3
"""
Create splash background image with gradient
"""

from PIL import Image, ImageDraw

def create_splash_background():
    # Create gradient background image
    width = 1242  # iPhone Pro Max width
    height = 2688  # iPhone Pro Max height
    
    img = Image.new('RGB', (width, height), '#4CAF50')
    draw = ImageDraw.Draw(img)
    
    # Create gradient from #4CAF50 to #81C784
    for i in range(height):
        # Calculate gradient color
        ratio = i / height
        r = int(76 + (129 - 76) * ratio)  # From 76 to 129
        g = int(175 + (199 - 175) * ratio)  # From 175 to 199
        b = int(80 + (132 - 80) * ratio)  # From 80 to 132
        
        draw.rectangle([(0, i), (width, i + 1)], fill=(r, g, b))
    
    # Save the background image
    img.save('assets/icons/splash_background.png', 'PNG')
    print("Created splash_background.png with gradient")

if __name__ == "__main__":
    create_splash_background()