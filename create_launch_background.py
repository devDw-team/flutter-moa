#!/usr/bin/env python3
"""
Create launch background image for iOS
"""

from PIL import Image

def create_launch_background():
    # Create 1x1 pixel image with green color #4CAF50
    img = Image.new('RGB', (1, 1), (76, 175, 80))
    img.save('ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png', 'PNG')
    print("Created LaunchBackground image with #4CAF50 color")

if __name__ == "__main__":
    create_launch_background()