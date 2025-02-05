import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from dataclasses import dataclass
from enum import Enum
from typing import Tuple, Optional
from src.utils.logger import logger  # Use absolute import

class BoundaryType(Enum):
    """Enumeration of possible boundary conditions."""
    WALL = 1
    INLET = 2
    OUTLET = 3
    INTERNAL = 0

@dataclass
class GridConfig:
    """Configuration parameters for the Cartesian grid."""
    nx: int  # Number of cells in x-direction
    ny: int  # Number of cells in y-direction
    lx: float = 1.0  # Domain length in x-direction
    ly: float = 1.0  # Domain length in y-direction
    
    def __post_init__(self):
        """Validate grid configuration parameters."""
        if self.nx < 2 or self.ny < 2:
            raise ValueError("Grid must have at least 2 cells in each direction")
        if self.lx <= 0 or self.ly <= 0:
            raise ValueError("Domain dimensions must be positive")

class CartesianGrid:
    """2D Cartesian grid generator with boundary condition support."""
    
    def __init__(self, config: GridConfig):
        """Initialize the grid with given configuration."""
        self.config = config
        self.dx = config.lx / (config.nx - 1)
        self.dy = config.ly / (config.ny - 1)
        
        # Initialize grid points
        self.x, self.y = np.meshgrid(
            np.linspace(0, config.lx, config.nx),
            np.linspace(0, config.ly, config.ny)
        )
        
        # Initialize boundary conditions
        self.boundaries = np.full((config.ny, config.nx), BoundaryType.INTERNAL)
        self._set_default_boundaries()
        
        logger.info(f"Created {config.nx}x{config.ny} Cartesian grid")
    
    def _set_default_boundaries(self):
        """Set default boundary conditions: walls on all sides."""
        # Set walls on all boundaries
        self.boundaries[0, :] = BoundaryType.WALL  # Bottom wall
        self.boundaries[-1, :] = BoundaryType.WALL  # Top wall
        self.boundaries[:, 0] = BoundaryType.WALL  # Left wall
        self.boundaries[:, -1] = BoundaryType.WALL  # Right wall
    
    def set_boundary_condition(self, side: str, bc_type: BoundaryType):
        """Set boundary condition for a specific side of the domain.
        
        Args:
            side: One of 'left', 'right', 'top', 'bottom'
            bc_type: BoundaryType to apply
        """
        if side == 'left':
            self.boundaries[:, 0] = bc_type
        elif side == 'right':
            self.boundaries[:, -1] = bc_type
        elif side == 'top':
            self.boundaries[-1, :] = bc_type
        elif side == 'bottom':
            self.boundaries[0, :] = bc_type
        else:
            raise ValueError(f"Invalid side: {side}")
        
        logger.info(f"Set {bc_type.name} boundary condition on {side} side")
    
    def get_cell_centers(self) -> Tuple[np.ndarray, np.ndarray]:
        """Calculate and return cell center coordinates."""
        #average of diagonal points
        x_centers = (self.x[:-1, :-1] + self.x[1:, 1:]) / 2
        y_centers = (self.y[:-1, :-1] + self.y[1:, 1:]) / 2
        #average of adjacent horizontal and vertical points
        # x_centers = (self.x[:-1, :] + self.x[1:, :]) / 2
        # y_centers = (self.y[:, :-1] + self.y[:, 1:]) / 2
        return x_centers, y_centers
    
    def plot_grid(self, show_boundaries: bool = True):
        """Visualize the grid with improved boundary condition representation."""
        fig, ax = plt.subplots(figsize=(10, 10))

        # Plot grid structure
        ax.plot(self.x, self.y, 'k-', alpha=0.3)
        ax.plot(self.x.T, self.y.T, 'k-', alpha=0.3)

        if show_boundaries:
            # Define boundary color mapping
            boundary_colors = {
                BoundaryType.WALL: "black",
                BoundaryType.INLET: "blue",
                BoundaryType.OUTLET: "red",
                BoundaryType.INTERNAL: "yellow",
            }

            # Convert boundary matrix to numerical indices for visualization
            boundary_map = np.vectorize(lambda b: b.value)(self.boundaries)

            # Create a custom colormap
            cmap = mcolors.ListedColormap([boundary_colors[b] for b in BoundaryType])
            #bounds = [b.value - 0.5 for b in BoundaryType] + [max(b.value for b in BoundaryType) + 0.5] #error ValueError: bins must be monotonically increasing or decreasing Traceback (most recent call last):
            boundary_values = sorted(b.value for b in BoundaryType)  # Ensure sorted order
            bounds = [v - 0.5 for v in boundary_values] + [boundary_values[-1] + 0.5]

            norm = mcolors.BoundaryNorm(bounds, cmap.N)

            # Overlay boundary conditions
            ax.imshow(boundary_map, cmap=cmap, norm=norm, origin="lower", extent=[0, self.config.lx, 0, self.config.ly], alpha=0.6)

            # Create a legend
            legend_patches = [plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=boundary_colors[b], markersize=10, label=b.name) 
                            for b in BoundaryType if b != BoundaryType.INTERNAL]
            ax.legend(handles=legend_patches, loc="upper right")

        ax.set_xlabel('x')
        ax.set_ylabel('y')
        ax.set_title(f'Cartesian Grid ({self.config.nx}x{self.config.ny})')
        ax.set_aspect('equal')
        plt.show()

def create_grid(nx: int, ny: int, lx: float = 1.0, ly: float = 1.0) -> CartesianGrid:
    """Convenience function to create a grid with default settings."""
    config = GridConfig(nx=nx, ny=ny, lx=lx, ly=ly)
    return CartesianGrid(config)