import os
import re

# Rutas
hugo_blog_dir = r"C:\Users\crrvg\w11-codebases\personal-website\content\posts"

# 🔹 Modificar los enlaces a imágenes en los Markdown
for filename in os.listdir(hugo_blog_dir):
    if filename.endswith(".md"):
        filepath = os.path.join(hugo_blog_dir, filename)

        with open(filepath, "r", encoding="utf-8") as file:
            content = file.read()

        # Encontrar imágenes en el formato `![](test%201.png)`
        images = re.findall(r'!\[\]\(([^)]+\.png)\)', content)

        for image in images:
            new_image_path = f"/personal-website/images/{image}"
            content = content.replace(f"![]({image})", f"![]({new_image_path})")

        # Guardar cambios en el archivo Markdown
        with open(filepath, "w", encoding="utf-8") as file:
            file.write(content)

print("✅ Links de imágenes en Markdown modificados para Hugo.")
