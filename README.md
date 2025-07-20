# Proyecto de Comunicación UART con Cálculo de Autocorrelación en FPGA (Basys 3)

Este proyecto se basa principalmente en el archivo DEMO proporcionado por **Digilent** para la tarjeta **Basys 3**, el cual fue adaptado y mejorado para fines académicos y prácticos.

## Descripción General

Se implementó un sistema de comunicación UART entre una FPGA (Basys 3) y una computadora, permitiendo la transmisión de datos digitales. A esto se le integró un módulo de cálculo de función de autocorrelación (ACF) hasta 7 retardos, con la finalidad de procesar señales digitalizadas provenientes del bloque XADC (Convertidor Analógico-Digital interno de la FPGA).

## Mejoras Realizadas

- **Modularidad**: Se reestructuraron los bloques de diseño para asegurar una arquitectura modular, facilitando la comprensión y mantenibilidad del sistema.
- **Compatibilidad entre lenguajes**: Se integraron módulos escritos en Verilog y VHDL, logrando una correcta comunicación entre ellos a nivel de señales y salidas.
- **Adaptación del UART**: El módulo UART fue reutilizado del archivo DEMO original, ya que su implementación es estándar para este tipo de comunicación. No se realizaron modificaciones sustanciales.
- **Selección de pines (Constraints)**: Se modificaron los archivos `.xdc` para adaptar las entradas y salidas del sistema a los recursos físicos disponibles en la placa Basys 3, según nuestras necesidades.

## Estructura del Proyecto

- `/src`: Archivos VHDL y Verilog organizados por módulos funcionales (UART, ACF, leds, display, XADC, etc.).
- `/constraints`: Archivos `.xdc` con la configuración de pines para la FPGA.
- `/python`: Scripts en Python para la recepción de datos y visualización en tiempo real desde la PC.
- `/paper`: Documentación técnica, esquemas y figuras referenciales.

## Requisitos

- **Hardware**:
  - FPGA Digilent Basys 3
  - Conexión USB UART (microUSB)
- **Software**:
  - Vivado 
  - Python 3.13.5
  - PyCharm (como compilador principal para scripts Python)
  - Librerías Python requeridas:
    - `pyserial`
    - `numpy`
    - `matplotlib`

## Autores

Desarrollado y mejorado por:

- Mario Daniel Huayhua
- Jorge Rafael

## Licencia

Este proyecto se distribuye con fines educativos y puede ser reutilizado libremente siempre que se dé el debido crédito a los autores y a Digilent como base original.
