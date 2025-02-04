import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# Configuración inicial
fig, ax = plt.subplots()
x = np.linspace(0, 2 * np.pi, 1000)
line, = ax.plot(x, np.sin(x), lw=2)

# Función de animación
def animate(frame):
    line.set_ydata(np.sin(x + frame / 10.0) * np.sin(frame / 50.0))  # Modifica la onda
    line.set_color((np.sin(frame / 20.0) * 0.5 + 0.5,  # Cambia el color
                    np.sin(frame / 30.0) * 0.5 + 0.5,
                    np.sin(frame / 40.0) * 0.5 + 0.5))
    return line,

# Crear la animación
ani = animation.FuncAnimation(fig, animate, frames=200, interval=50, blit=True)

# Guardar como GIF
ani.save('onda.gif', writer='pillow')

plt.show()