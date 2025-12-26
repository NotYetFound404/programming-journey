import os
import re

def update_markdown_images(directory):
    """Modifies image links in markdown files within the given directory."""
    for filename in os.listdir(directory):
        if filename.endswith(".md"):
            filepath = os.path.join(directory, filename)
            
            with open(filepath, "r", encoding="utf-8") as file:
                content = file.read()

            # Find image links in the format `![](test%201.png)`
            images = re.findall(r'!\[\]\(([^)]+\.png)\)', content)

            for image in images:
                new_image_path = f"/personal-website/images/{image}"
                content = content.replace(f"![]({image})", f"![]({new_image_path})")

            # Save changes back to the markdown file
            with open(filepath, "w", encoding="utf-8") as file:
                file.write(content)

# Define the directories to process
hugo_base_dir = r"C:\Users\crrvg\w11-codebases\personal-website\content"
directories = ["posts", "areas", "art", "book-reviews", "projects"]

for folder in directories:
    update_markdown_images(os.path.join(hugo_base_dir, folder))

print("✅ Links de imágenes en Markdown modificados para Hugo.")
