from src.utils.logger import logger

class TimeStepping:
    """Implements time-stepping methods for CFD simulations."""

    def __init__(self, cfl=0.5, method="euler"):
        """
        Initialize the time-stepping method.

        Args:
            cfl (float): CFL number for stability (default: 0.5).
            method (str): Time-stepping method ('euler', 'rk2', 'rk4').
        """
        self.cfl = cfl
        self.method = method
        logger.info(f"Initialized TimeStepping with method={method}, CFL={cfl}")

    def compute_time_step(self, dx, u_max):
        """
        Compute the time step based on the CFL condition.

        Args:
            dx (float): Grid spacing.
            u_max (float): Maximum velocity in the domain.

        Returns:
            float: Time step Δt.
        """
        dt = self.cfl * dx / u_max
        logger.debug(f"Computed time step: Δt={dt}")
        return dt

    def forward_euler(self, u, dt, rhs):
        """
        Forward Euler time-stepping method.

        Args:
            u (np.ndarray): Current solution.
            dt (float): Time step.
            rhs (np.ndarray): Right-hand side (spatial discretization).

        Returns:
            np.ndarray: Updated solution.
        """
        return u + dt * rhs

    def runge_kutta_2(self, u, dt, rhs):
        """
        Runge-Kutta 2nd order (Heun's method).

        Args:
            u (np.ndarray): Current solution.
            dt (float): Time step.
            rhs (function): Function to compute the right-hand side.

        Returns:
            np.ndarray: Updated solution.
        """
        k1 = rhs(u)
        k2 = rhs(u + dt * k1)
        return u + (dt / 2) * (k1 + k2)

    def runge_kutta_4(self, u, dt, rhs):
        """
        Runge-Kutta 4th order method.

        Args:
            u (np.ndarray): Current solution.
            dt (float): Time step.
            rhs (function): Function to compute the right-hand side.

        Returns:
            np.ndarray: Updated solution.
        """
        k1 = rhs(u)
        k2 = rhs(u + (dt / 2) * k1)
        k3 = rhs(u + (dt / 2) * k2)
        k4 = rhs(u + dt * k3)
        return u + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4)

    def step(self, u, dt, rhs):
        """
        Perform a single time step using the selected method.

        Args:
            u (np.ndarray): Current solution.
            dt (float): Time step.
            rhs (function): Function to compute the right-hand side.

        Returns:
            np.ndarray: Updated solution.
        """
        if self.method == "euler":
            return self.forward_euler(u, dt, rhs)
        elif self.method == "rk2":
            return self.runge_kutta_2(u, dt, rhs)
        elif self.method == "rk4":
            return self.runge_kutta_4(u, dt, rhs)
        else:
            raise ValueError(f"Unknown time-stepping method: {self.method}")