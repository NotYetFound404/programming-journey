import pygame
import time

# Initialize Pygame
pygame.init()

# Display setup
WIDTH, HEIGHT = 800, 800
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Droste-Style Infinite Sierpinski Zoom")

# Parameters
ZOOM_SPEED = 1.02   # Continuous zoom scaling
REGEN_TIME = 5      # Time before regenerating new fractals
MAX_DEPTH = 6       # Fractal recursion depth

# Frame buffer for persistent zoom illusion
frame_buffer = pygame.Surface((WIDTH, HEIGHT))

def get_sierpinski(depth, x1, y1, x2, y2, x3, y3):
    if depth == 0:
        return [(x1, y1), (x2, y2), (x3, y3)]
    
    # Midpoints
    mid1_x, mid1_y = (x1 + x2) / 2, (y1 + y2) / 2
    mid2_x, mid2_y = (x2 + x3) / 2, (y2 + y3) / 2
    mid3_x, mid3_y = (x3 + x1) / 2, (y3 + y1) / 2
    
    return (
        get_sierpinski(depth-1, x1, y1, mid1_x, mid1_y, mid3_x, mid3_y) +
        get_sierpinski(depth-1, mid1_x, mid1_y, x2, y2, mid2_x, mid2_y) +
        get_sierpinski(depth-1, mid3_x, mid3_y, mid2_x, mid2_y, x3, y3)
    )

def draw_sierpinski(surface, points, zoom, color):
    transformed_points = []
    for x, y in points:
        zx = (x - WIDTH // 2) * zoom + WIDTH // 2
        zy = (y - HEIGHT // 2) * zoom + HEIGHT // 2
        transformed_points.append((zx, zy))

    for i in range(0, len(transformed_points), 3):
        if i + 2 < len(transformed_points):
            pygame.draw.polygon(surface, color, 
                               [transformed_points[i], 
                                transformed_points[i+1], 
                                transformed_points[i+2]])

def main():
    clock = pygame.time.Clock()
    running = True
    zoom = 1.0
    last_regen_time = time.time()

    # Initial fractal generation
    sierpinski_points = get_sierpinski(
        MAX_DEPTH, WIDTH // 2, HEIGHT // 4, WIDTH // 4, 3 * HEIGHT // 4, 3 * WIDTH // 4, 3 * HEIGHT // 4
    )

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # Apply a smooth zoom effect
        zoom *= ZOOM_SPEED

        # Reset smoothly by blending old frame
        if time.time() - last_regen_time >= REGEN_TIME:
            last_regen_time = time.time()
            zoom = 1.0  # Reset zoom without abrupt change
            
            # Blend last frame into the new frame for continuity
            frame_buffer.blit(screen, (0, 0))

            # Generate new fractal (clearing unused memory)
            sierpinski_points = get_sierpinski(
                MAX_DEPTH, WIDTH // 2, HEIGHT // 4, WIDTH // 4, 3 * HEIGHT // 4, 3 * WIDTH // 4, 3 * HEIGHT // 4
            )

        # Smooth color cycling
        color = pygame.Color(0)
        color.hsla = ((time.time() * 50) % 360, 100, 50, 100)  

        # Draw the previous frame with fading
        screen.blit(frame_buffer, (0, 0), special_flags=pygame.BLEND_MULT)

        # Draw the fractal on top
        draw_sierpinski(screen, sierpinski_points, zoom, color)

        pygame.display.flip()
        clock.tick(30)  # 30 FPS

    pygame.quit()

if __name__ == "__main__":
    main()
