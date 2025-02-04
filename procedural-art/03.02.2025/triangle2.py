import pygame
import time
import math

# Initialize Pygame
pygame.init()

# Display setup
WIDTH, HEIGHT = 800, 800
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Enhanced Droste-Style Infinite Sierpinski Zoom")

# Improved parameters
ZOOM_SPEED = 1.015  # Slightly slower for smoother zoom
REGEN_TIME = 3.5    # Shorter regeneration time
MAX_DEPTH = 7       # Increased depth for more detail
FADE_DURATION = 1.0 # Duration of fade transition

# Multiple frame buffers for smoother transitions
frame_buffer1 = pygame.Surface((WIDTH, HEIGHT))
frame_buffer2 = pygame.Surface((WIDTH, HEIGHT))

def get_sierpinski(depth, x1, y1, x2, y2, x3, y3, min_size=3):
    # Check if triangle is too small to subdivide
    size = max(abs(x2-x1), abs(x3-x1), abs(y2-y1), abs(y3-y1))
    if size < min_size or depth == 0:
        return [(x1, y1), (x2, y2), (x3, y3)]
    
    # Midpoints with slight randomness for more organic look
    jitter = size * 0.002
    mid1_x = (x1 + x2) / 2 
    mid1_y = (y1 + y2) / 2 
    mid2_x = (x2 + x3) / 2 
    mid2_y = (y2 + y3) / 2 
    mid3_x = (x3 + x1) / 2 
    mid3_y = (y3 + y1) / 2 
    
    return (
        get_sierpinski(depth-1, x1, y1, mid1_x, mid1_y, mid3_x, mid3_y, min_size) +
        get_sierpinski(depth-1, mid1_x, mid1_y, x2, y2, mid2_x, mid2_y, min_size) +
        get_sierpinski(depth-1, mid3_x, mid3_y, mid2_x, mid2_y, x3, y3, min_size)
    )

def draw_sierpinski(surface, points, zoom, color, center_offset=(0, 0)):
    transformed_points = []
    center_x = WIDTH // 2 + center_offset[0]
    center_y = HEIGHT // 2 + center_offset[1]
    
    for x, y in points:
        # Improved zoom transformation with better centering
        dx = x - center_x
        dy = y - center_y
        zx = dx * zoom + center_x
        zy = dy * zoom + center_y
        transformed_points.append((zx, zy))
    
    # Draw triangles with anti-aliasing
    for i in range(0, len(transformed_points), 3):
        if i + 2 < len(transformed_points):
            pygame.draw.polygon(surface, color, 
                              [transformed_points[i], 
                               transformed_points[i+1], 
                               transformed_points[i+2]], 1)

def get_glow_color(base_color, intensity=0.5):
    # Create a glowing effect by adjusting color brightness
    r, g, b = base_color[:3]
    glow = int(255 * intensity)
    return (min(r + glow, 255), min(g + glow, 255), min(b + glow, 255))

def main():
    clock = pygame.time.Clock()
    running = True
    zoom = 1.0
    last_regen_time = time.time()
    transition_start = 0
    is_transitioning = False
    ZOOM_SPEED = 1.015
    
    # Initial fractal generation
    sierpinski_points = get_sierpinski(
        MAX_DEPTH, WIDTH // 2, HEIGHT // 4, WIDTH // 4, 3 * HEIGHT // 4, 3 * WIDTH // 4, 3 * HEIGHT // 4
    )
    
    # Track frame rate
    frame_count = 0
    fps_timer = time.time()
    
    while running:
        frame_start = time.time()
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        
        # Calculate FPS
        frame_count += 1
        if frame_count == 30:
            fps = frame_count / (time.time() - fps_timer)
            fps_timer = time.time()
            frame_count = 0
            
            # Adjust zoom speed based on FPS
            ZOOM_SPEED = 1.015 * (60 / max(fps, 30))
        
        # Apply zoom effect
        zoom *= ZOOM_SPEED
        
        # Handle regeneration
        current_time = time.time()
        if current_time - last_regen_time >= REGEN_TIME and not is_transitioning:
            transition_start = current_time
            is_transitioning = True
            frame_buffer2.blit(screen, (0, 0))
            
            # Generate new fractal
            sierpinski_points = get_sierpinski(
                MAX_DEPTH, WIDTH // 2, HEIGHT // 4, WIDTH // 4, 3 * HEIGHT // 4, 3 * WIDTH // 4, 3 * HEIGHT // 4
            )
            zoom = 1.0
        
        # Clear screen
        screen.fill((0, 0, 0))
        
        # Calculate transition alpha
        if is_transitioning:
            transition_progress = (current_time - transition_start) / FADE_DURATION
            if transition_progress >= 1:
                is_transitioning = False
                last_regen_time = current_time
                frame_buffer1.blit(frame_buffer2, (0, 0))
            alpha = max(0, min(255, int(255 * (1 - transition_progress))))
        else:
            alpha = 255
        
        # Create dynamic color effect
        hue = (time.time() * 30) % 360
        color = pygame.Color(0)
        color.hsla = (hue, 100, 50, 100)
        
        # Draw previous frame with fade
        if is_transitioning:
            screen.blit(frame_buffer2, (0, 0), special_flags=pygame.BLEND_RGBA_MULT)
        
        # Draw current frame
        glow_color = get_glow_color(color, 0.3)
        draw_sierpinski(screen, sierpinski_points, zoom, glow_color)
        draw_sierpinski(screen, sierpinski_points, zoom * 0.99, color)  # Inner line for glow effect
        
        pygame.display.flip()
        clock.tick(60)  # Increased to 60 FPS
    
    pygame.quit()

if __name__ == "__main__":
    main()