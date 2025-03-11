# "Syncing areas..."  
robocopy "C:\ALMACENAMIENTO\acer\personal-website\areas" "C:\Users\crrvg\w11-codebases\personal-website\content\areas" /MIR /Z /W:5 /R:3  

# "Syncing art..."  
robocopy "C:\ALMACENAMIENTO\acer\personal-website\art" "C:\Users\crrvg\w11-codebases\personal-website\content\art" /MIR /Z /W:5 /R:3  

# "Syncing projects..."  
robocopy "C:\ALMACENAMIENTO\acer\personal-website\projects" "C:\Users\crrvg\w11-codebases\personal-website\content\projects" /MIR /Z /W:5 /R:3  

#Sync book reviews
robocopy "C:\ALMACENAMIENTO\acer\personal-website\book-reviews" "C:\Users\crrvg\w11-codebases\personal-website\content\book-reviews" /MIR /Z /W:5 /R:3  

# Copiar los posts de Obsidian a Hugo
robocopy "C:\ALMACENAMIENTO\acer\personal-website\posts" "C:\Users\crrvg\w11-codebases\personal-website\content\posts" /MIR /Z /W:5 /R:3

# Copiar imágenes de Obsidian a Hugo
robocopy "C:\ALMACENAMIENTO\acer\personal-website\images" "C:\Users\crrvg\w11-codebases\personal-website\static\images" /MIR /Z /W:5 /R:3