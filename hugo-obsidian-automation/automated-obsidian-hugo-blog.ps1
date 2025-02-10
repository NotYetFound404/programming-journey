# Definir rutas de los scripts
$robocopyScript = "C:/Users/crrvg/w11-codebases/programming-journey/hugo-obsidian-automation/robocopy-posts-and-images.ps1"
$pythonExecutable = "C:/Users/crrvg/w11-codebases/programming-journey/.venv/Scripts/python.exe"
$pythonScript = "C:/Users/crrvg/w11-codebases/programming-journey/hugo-obsidian-automation/hugo-obsidian-image-copier.py"

# Ejecutar el script de robocopy
Write-Output "🚀 Ejecutando copia de posts e imagenes..."
& $robocopyScript

# Ejecutar el script de Python
Write-Output "🐍 Ejecutando script de conversion de imágenes..."
& $pythonExecutable $pythonScript

Write-Output "✅ Links de imagenes en Markdown modificados para Hugo."
