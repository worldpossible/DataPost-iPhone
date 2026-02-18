from PIL import Image
import os

screenshots_dir = r"C:\Users\Jeremy\Documents\GitHub\DataPost-iPhone\screenshots"

# App Store requires 2048x2732 for 13" iPad
target_size = (2048, 2732)

files = ["screenshot_1.png", "screenshot_2.png", "screenshot_3.png", "screenshot_4.png"]

for filename in files:
    input_path = os.path.join(screenshots_dir, filename)
    output_path = os.path.join(screenshots_dir, f"ipad_{filename}")
    
    try:
        img = Image.open(input_path)
        print(f"Original {filename}: {img.size}")
        
        # Resize to fit within target while maintaining aspect ratio, then pad
        img_ratio = img.width / img.height
        target_ratio = target_size[0] / target_size[1]
        
        if img_ratio > target_ratio:
            # Image is wider, fit by width
            new_width = target_size[0]
            new_height = int(new_width / img_ratio)
        else:
            # Image is taller, fit by height
            new_height = target_size[1]
            new_width = int(new_height * img_ratio)
        
        img_resized = img.resize((new_width, new_height), Image.LANCZOS)
        
        # Create new image with target size and paste resized image centered
        new_img = Image.new('RGB', target_size, (30, 136, 229))  # Blue background
        paste_x = (target_size[0] - new_width) // 2
        paste_y = (target_size[1] - new_height) // 2
        
        # Handle transparency
        if img_resized.mode == 'RGBA':
            new_img.paste(img_resized, (paste_x, paste_y), img_resized)
        else:
            new_img.paste(img_resized, (paste_x, paste_y))
        
        new_img.save(output_path, 'PNG')
        print(f"Saved: {output_path} ({target_size[0]}x{target_size[1]})")
    except Exception as e:
        print(f"Error processing {filename}: {e}")

print("\nDone! iPad screenshots saved to:", screenshots_dir)
