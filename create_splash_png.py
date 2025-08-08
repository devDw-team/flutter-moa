#!/usr/bin/env python3
"""
Create splash screen PNG for 모아 Lite app
"""

from PIL import Image, ImageDraw

def create_splash_png():
    # Create main splash logo (512x512)
    width = 512
    height = 512
    
    # Create image with solid color background (middle gradient color)
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw white circle in center
    center_x = width // 2
    center_y = height // 2
    radius = 180
    
    # Draw white circle background with shadow effect
    for i in range(10, 0, -1):
        alpha = int(255 * 0.02 * i)
        shadow_radius = radius + i * 2
        draw.ellipse(
            [(center_x - shadow_radius, center_y - shadow_radius), 
             (center_x + shadow_radius, center_y + shadow_radius)],
            fill=(0, 0, 0, alpha)
        )
    
    # Draw white circle
    draw.ellipse(
        [(center_x - radius, center_y - radius), 
         (center_x + radius, center_y + radius)],
        fill='white'
    )
    
    # Draw chart bars
    bar_width = 40
    bar_colors = [(76, 175, 80), (102, 187, 106), (129, 199, 132)]  # RGB values for green shades
    bar_heights = [80, 120, 100]
    bar_x_positions = [center_x - 80, center_x - 20, center_x + 40]
    
    for x, height_bar, color in zip(bar_x_positions, bar_heights, bar_colors):
        y = center_y + 30 - height_bar // 2
        # Draw rounded rectangle (approximated with rectangle + circles)
        draw.rectangle(
            [(x, y + 5), (x + bar_width, y + height_bar - 5)],
            fill=color
        )
        draw.rectangle(
            [(x + 5, y), (x + bar_width - 5, y + height_bar)],
            fill=color
        )
        # Top rounded corners
        draw.ellipse(
            [(x, y), (x + 10, y + 10)],
            fill=color
        )
        draw.ellipse(
            [(x + bar_width - 10, y), (x + bar_width, y + 10)],
            fill=color
        )
        # Bottom rounded corners
        draw.ellipse(
            [(x, y + height_bar - 10), (x + 10, y + height_bar)],
            fill=color
        )
        draw.ellipse(
            [(x + bar_width - 10, y + height_bar - 10), (x + bar_width, y + height_bar)],
            fill=color
        )
    
    # Draw circular progress
    progress_radius = 60
    progress_center_y = center_y - 70
    
    # Draw progress circle background (light green)
    for angle in range(0, 360, 2):
        x = center_x + progress_radius * Image.math.cos(angle * 3.14159 / 180)
        y = progress_center_y + progress_radius * Image.math.sin(angle * 3.14159 / 180)
        draw.ellipse(
            [(x - 4, y - 4), (x + 4, y + 4)],
            fill=(76, 175, 80, 77)  # 30% opacity
        )
    
    # Draw progress arc (darker green) - approximately 240 degrees
    for angle in range(-90, 150, 2):
        import math
        x = center_x + progress_radius * math.cos(angle * 3.14159 / 180)
        y = progress_center_y + progress_radius * math.sin(angle * 3.14159 / 180)
        draw.ellipse(
            [(x - 4, y - 4), (x + 4, y + 4)],
            fill=(76, 175, 80)
        )
    
    # Draw Won symbol in center of progress circle
    # Create a simple Won symbol with lines
    won_color = (76, 175, 80)
    line_width = 4
    
    # Draw W shape
    points = [
        (center_x - 25, progress_center_y - 20),
        (center_x - 15, progress_center_y + 10),
        (center_x, progress_center_y - 5),
        (center_x + 15, progress_center_y + 10),
        (center_x + 25, progress_center_y - 20)
    ]
    
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=won_color, width=line_width)
    
    # Draw horizontal lines through W
    draw.line(
        [(center_x - 30, progress_center_y - 10), (center_x + 30, progress_center_y - 10)],
        fill=won_color, width=2
    )
    draw.line(
        [(center_x - 30, progress_center_y), (center_x + 30, progress_center_y)],
        fill=won_color, width=2
    )
    
    # Save the splash logo
    img.save('assets/icons/splash_logo.png', 'PNG')
    print("Created splash_logo.png (512x512)")
    
    # Create a larger version for tablets (1024x1024)
    img_large = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    img_large.save('assets/icons/splash_logo_large.png', 'PNG')
    print("Created splash_logo_large.png (1024x1024)")
    
    print("\n✅ Splash screen PNGs created successfully!")

if __name__ == "__main__":
    create_splash_png()