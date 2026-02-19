from PIL import Image
import os

def remove_background(file_path, output_path):
    print(f"Processing {file_path}...")
    img = Image.open(file_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    # Loop through each pixel and 
    # if it's white (above a certain threshold), make it transparent
    for item in datas:
        # Check if it's near white (RGB above 240)
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Saved to {output_path}")

# Ensure the output directory exists
output_dir = "assets/logo/files/transparent"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

files = ["main_logo.jpg", "Splash_dark.png", "splash_light.png"]
for f in files:
    input_f = os.path.join("assets/logo/files", f)
    output_f = os.path.join(output_dir, f.replace(".jpg", ".png").replace(".png", "_transparent.png"))
    if os.path.exists(input_f):
        remove_background(input_f, output_f)
    else:
        print(f"Warning: {input_f} not found.")
