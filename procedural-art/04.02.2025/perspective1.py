import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# Define grid parameters
cols, rows = 10, 15  # Grid size
depth_factor = 0.08  # Perspective scaling
speed = 0.1  # Upward movement speed
frames = 100  # Animation frames

# Initialize 3D grid points
def initialize_grid():
    """Create a 3D-like perspective grid."""
    grid = []
    for row in range(rows):
        for col in range(cols):
            x = (col - cols // 2) * 0.2  # Centered x-coordinates
            y = row * 0.15  # Vertical spacing
            z = 1 / (1 + row * depth_factor)  # Simulate perspective (size variation)
            grid.append([x, y, z])
    return np.array(grid)

grid_points = initialize_grid()

def update(frame):
    """Update point positions to simulate upward displacement."""
    global grid_points

    # Move each point up, pushing others above it
    for i in range(len(grid_points)):
        grid_points[i][1] -= speed * grid_points[i][2]  # Scale by depth
    
    # Reset points that go above threshold
    for i in range(len(grid_points)):
        if grid_points[i][1] < -0.5:  # When a point moves too high, send it to the bottom
            grid_points[i][1] = max(grid_points[:,1]) + 0.15
            grid_points[i][0] += np.random.uniform(-0.05, 0.05)  # Small lateral shift
    
    # Clear previous frame
    ax.clear()
    ax.set_xlim(-1, 1)
    ax.set_ylim(-0.5, 2)
    ax.set_zlim(0, 1)
    ax.axis('off')

    # Extract coordinates
    x, y, z = grid_points[:,0], grid_points[:,1], grid_points[:,2]
    
    # Plot points with size varying by depth
    ax.scatter(x, y, c='black', s=50 * z, alpha=0.8)

# Set up figure
fig = plt.figure(figsize=(6, 6))
ax = fig.add_subplot(111, projection='3d')
ani = animation.FuncAnimation(fig, update, frames=frames, interval=50)

plt.show()
