from src.utils.logger import logger
from src.mesh.cartesian_grid import create_grid, BoundaryType
from src.solvers.time_stepping import TimeStepping
import numpy as np

def test_cartesian_grid():
    #<<<<-------- TESTING THE CARTESIAN GRID -------->>>>#
    # Create a 32x32 grid
    grid = create_grid(nx=32, ny=32)

    # Set custom boundary conditions
    grid.set_boundary_condition('left', BoundaryType.INLET)
    grid.set_boundary_condition('right', BoundaryType.OUTLET)

    # Visualize the grid
    grid.plot_grid(show_boundaries=True)

    # Get cell centers for computations
    x_centers, y_centers = grid.get_cell_centers()
    print(x_centers)
    print(y_centers)
    #<<<<-------- TESTING THE CARTESIAN GRID -------->>>>#


def test_time_stepping():
    """Test the time-stepping methods."""
    logger.info("Testing time-stepping methods...")
    # Example right-hand side function (placeholder for spatial discretization)
    def rhs(u):
        return -u  # Simple ODE: du/dt = -u
    # Initialize time-stepping
    ts = TimeStepping(method="rk4", cfl=0.5)
    # Initial condition
    u = np.array([1.0])
    dt = 0.1  # Example time step
    t_end = 1.0  # End time
    # Time-stepping loop
    t = 0.0
    while t < t_end:
        u = ts.step(u, dt, rhs)
        t += dt
        logger.debug(f"Time={t:.2f}, u={u}")
    logger.info("Time-stepping test complete.")



def main():
    logger.info("Starting CFD Solver...")
    # Placeholder for simulation logic
    #test_cartesian_grid()
    test_time_stepping()
    logger.info("Simulation complete.")

if __name__ == "__main__":
    main()
