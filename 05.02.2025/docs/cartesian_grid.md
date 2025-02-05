# Cartesian Grid for CFD Simulations

## Overview
This module defines a Cartesian grid used for computational fluid dynamics (CFD) simulations.

## Features
- Supports **custom boundary conditions** (`INLET`, `OUTLET`, `WALL`, `INTERNAL`).
- Provides **cell center coordinates** for computations.
- Includes **visualization with color-coded boundaries**.

## Usage
```python
### 1️⃣ Create a Grid
grid = create_grid(nx=32, ny=32)
### 2️⃣ Set Boundary Conditions
grid.set_boundary_condition('left', BoundaryType.INLET)
grid.set_boundary_condition('right', BoundaryType.OUTLET)
### 3️⃣ Visualize the Grid
grid.plot_grid(show_boundaries=True)
```

## Recent Fixes
Fixed: Right boundary (OUTLET) now correctly assigned.
Fixed: Visualization now displays all boundaries properly.

