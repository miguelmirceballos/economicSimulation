# Simulación Económica con NetLogo y Aprendizaje Automático

Este proyecto corresponde a la asignatura de **Inteligencia Artificial** y recoge una simulación de mercado desarrollada en NetLogo, junto con el análisis de resultados mediante una red neuronal.

---

##  Instalación del Entorno

El proyecto requiere un entorno de Conda llamado **`BAP3`**, definido en el archivo `BAP3.yml`. Para configurar todo, sigue estos pasos:

1. **Crear el entorno**

   ```bash
   conda env create -f BAP3.yml
   ```
2. **Activar el entorno**

   ```bash
   conda activate BAP3
   ```

Además, necesitas configurar la variable de entorno **`NETLOGO_HOME`** apuntando a tu instalación de NetLogo (por ejemplo, NetLogo 6.3.0 o superior):

```bash
export NETLOGO_HOME="/ruta/a/NetLogo_6.3.0"
```

*(En Windows: ************`setx NETLOGO_HOME "C:\Program Files\NetLogo 6.3.0"`************)*

---

##  Estructura del Proyecto

```text
simulacion/
├── red.ipynb                    # Notebook para entrenar y evaluar la red neuronal
├── simulacion.ipynb             # Notebook para ejecutar la simulación de NetLogo
├── simulacionDefinitiva.nlogo   # Modelo de NetLogo definitivo
├── simulacionEconomica.csv      # Datos de salida de la simulación
├── simulacionEconomicaBackUp.csv# Copia de seguridad de los datos exportados
├── BAP3.yml                     # Definición del entorno Conda
└── README.md                    # Documento de instrucciones (este archivo)
```

---

## Descripción de los Notebooks

* **`simulacion.ipynb`**
  Contiene el flujo completo para:

  1. Configurar la conexión con NetLogo mediante `pyNetLogo`.
  2. Cargar y ejecutar el modelo `simulacionDefinitiva.nlogo` durante un número definido de ticks.
  3. Exportar los datos del mundo a `simulacionEconomica.csv`.

* **`red.ipynb`**
  Incluye:

  1. Carga y preprocesamiento de los datos exportados.
  2. Definición, entrenamiento y evaluación de una **red neuronal** para predecir comportamientos económicos.
  3. Visualizaciones de rendimiento y análisis de resultados.

---

##  Equipo de Trabajo

* **Rafael Pineda**
* **Miguel Mir**

---
