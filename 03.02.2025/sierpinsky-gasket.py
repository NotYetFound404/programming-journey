import pygame
import random
import math

# Pygame Initialization
pygame.init()

# Window Settings
WIDTH, HEIGHT = 800, 800
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Sierpinski Gasket - Infinite Particles")

# Colors
WHITE = (255, 255, 255)

# Fractal Settings
MAX_DEPTH = 6  # Controls the level of recursion
PARTICLE_DENSITY = 3  # Number of particles per unit area
zoom_factor = 1.0
zoom_speed = 1.05  # Increase 5% per frame
reset_threshold = 10  # When to reset

# Particle Storage
particles = []


def sierpinski(x1, y1, x2, y2, x3, y3, depth):
    """Recursive function to generate Sierpinski Gasket as particles."""
    if depth == 0:
        # Generate particles instead of drawing triangles
        for _ in range(PARTICLE_DENSITY):
            # Pick a random point inside the triangle
            r1, r2 = random.random(), random.random()
            px = (1 - math.sqrt(r1)) * x1 + (math.sqrt(r1) * (1 - r2)) * x2 + (math.sqrt(r1) * r2) * x3
            py = (1 - math.sqrt(r1)) * y1 + (math.sqrt(r1) * (1 - r2)) * y2 + (math.sqrt(r1) * r2) * y3

            # Store particle with zoom transformation
            particles.append((px, py, WHITE))

    else:
        # Calculate midpoints
        mid1_x, mid1_y = (x1 + x2) / 2, (y1 + y2) / 2
        mid2_x, mid2_y = (x2 + x3) / 2, (y2 + y3) / 2
        mid3_x, mid3_y = (x3 + x1) / 2, (y3 + y1) / 2

        # Recurse for sub-triangles
        sierpinski(x1, y1, mid1_x, mid1_y, mid3_x, mid3_y, depth - 1)
        sierpinski(mid1_x, mid1_y, x2, y2, mid2_x, mid2_y, depth - 1)
        sierpinski(mid3_x, mid3_y, mid2_x, mid2_y, x3, y3, depth - 1)


def generate_fractal():
    """Regenerates the fractal and clears old data."""
    global particles
    particles = []  # Clear old particles
    # Define the base triangle
    sierpinski(WIDTH // 2, 50, 50, HEIGHT - 50, WIDTH - 50, HEIGHT - 50, MAX_DEPTH)


# Initialize first fractal generation
generate_fractal()

# Main Loop
clock = pygame.time.Clock()
running = True

while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Clear screen
    screen.fill((0, 0, 0))

    # Apply zoom
    zoom_factor *= zoom_speed

    # Reset if zoom is too large
    if zoom_factor > reset_threshold:
        zoom_factor = 1.0
        generate_fractal()

    # Draw particles
    for px, py, color in particles:
        zx = WIDTH / 2 + (px - WIDTH / 2) * zoom_factor
        zy = HEIGHT / 2 + (py - HEIGHT / 2) * zoom_factor
        screen.set_at((int(zx), int(zy)), color)

    pygame.display.flip()
    clock.tick(30)  # Maintain FPS

pygame.quit()
