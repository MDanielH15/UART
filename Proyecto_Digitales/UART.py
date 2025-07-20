import serial
import struct
import numpy as np
import matplotlib.pyplot as plt
import time

# --- CONFIGURACIÓN ---
# ADMINISTRADOR DE DISPOSITIVOS
# VERIFICCAR EN EL COM 9
SERIAL_PORT = 'COM9'
BAUD_RATE = 9600
NUM_LAGS = 8
BYTES_PER_LAG = 4
PACKET_SIZE = NUM_LAGS * BYTES_PER_LAG

def main():
    print(f"Intentando conectar al puerto {SERIAL_PORT} a {BAUD_RATE} baudios...")

    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print("¡Conexión exitosa!")

        # Esperar hasta que haya suficientes datos
        while ser.in_waiting < PACKET_SIZE:
            time.sleep(0.01)

        raw_data = ser.read(PACKET_SIZE)

        if len(raw_data) == PACKET_SIZE:
            acf_values = []
            for i in range(NUM_LAGS):
                byte_chunk = raw_data[i * BYTES_PER_LAG: (i + 1) * BYTES_PER_LAG]
                value = struct.unpack('<i', byte_chunk)[0]
                acf_values.append(value)

            print(f"Valores ACF recibidos: {acf_values}")

            # --- Mostrar gráfica única ---
            lags = np.arange(NUM_LAGS)
            fig, ax = plt.subplots()
            markerline, stemlines, baseline = ax.stem(lags, acf_values)
            plt.setp(stemlines, 'linewidth', 2)
            plt.setp(markerline, 'markersize', 8)

            ax.set_title("Función de Autocorrelación (ACF)")
            ax.set_xlabel("Retardo (Lag)")
            ax.set_ylabel("Magnitud ACF")
            ax.set_xticks(lags)
            ax.grid(True)

            margen = 10000
            ymin = min(acf_values) - margen
            ymax = max(acf_values) + margen
            ax.set_ylim(ymin, ymax)

            plt.show()  # Mantiene la ventana abierta hasta que el usuario la cierre

        else:
            print("Error: No se recibieron los 32 bytes esperados.")

    except serial.SerialException as e:
        print(f"Error: No se pudo abrir el puerto {SERIAL_PORT}.")
        print(f"Detalle: {e}")
    except KeyboardInterrupt:
        print("\nPrograma terminado por el usuario.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Puerto serie cerrado.")


if __name__ == '__main__':
    main()

