# Arquitectura – Ejercicios 4.4.x

Este proyecto contiene tres ejercicios en ensamblador AArch64 (.s) y una interfaz gráfica en Python que permite ejecutarlos y visualizar resultados en Raspberry Pi OS (64‑bit).

## Contenido

- Ejercicio 4.4.1-Cadencia variable con bucle de retardo
  - `ex441.s`
- Ejercicio 4.4.2-Cadencia variable con temporizador
  - `ex442.s`
- Ejercicio 4.4.3-Escala musical
  - `ex443.s`
- Raíz
  - `build_all.sh` – Script para compilar y linkear los .s en Raspberry Pi
  - `gui.py` – GUI (Tkinter) para controlar los tres ejercicios

## Requisitos (Raspberry Pi OS 64‑bit)

```
sudo apt-get update
sudo apt-get install -y build-essential binutils python3 python3-tk alsa-utils
```

## Compilación

Desde la carpeta del proyecto:

```
chmod +x build_all.sh
./build_all.sh
```

Se generan los binarios `ex441`, `ex442` y `ex443` dentro de sus carpetas.

## Ejecución con GUI

```
python3 gui.py
```

- 4.4.1 y 4.4.2: la GUI lanza los binarios y muestra un “LED” virtual que cambia con la salida (ON/OFF).
- 4.4.3: la GUI ejecuta `ex443` para generar `scale.wav` y lo reproduce con `aplay`.

---

## Descripción de los .s

### 4.4.1 – ex441.s (Cadencia variable con bucle de retardo)

- Imprime por stdout las cadenas `LED ON` y `LED OFF` alternadamente.
- Controla el ritmo usando `nanosleep` (syscall 101) con un retardo de medio período por estado.
- La cadencia comienza en 1000 ms y se reduce 50 ms por ciclo hasta llegar a 250 ms; al alcanzar 250 ms, se reinicia a 1000 ms y repite.
- System calls usadas: `write` (64) y `nanosleep` (101).

#### Estructura por bloques

- **Datos (.data)**
  - `msg_on`, `msg_off` y sus longitudes `len_on`, `len_off` se usan como buffers para `write`.
- **BSS (.bss)**
  - `tspec`: dos `quad` para `timespec { tv_sec, tv_nsec }` que consume `nanosleep`.
- **Macros**
  - `PRINT buf,len`: prepara x0=1 (stdout), x1=puntero, x2=longitud, x8=64 y ejecuta `svc #0`.
  - `SLEEP_MS ms`: arma `timespec` con `tv_sec=0`, `tv_nsec=ms*1_000_000` y ejecuta `nanosleep` (x8=101).
- **_start**
  - `x20` almacena la cadencia en ms (inicial 1000).
  - Bucle `loop`:
    - ON: `PRINT`, medio período `SLEEP_MS (x20 >> 1)`.
    - OFF: `PRINT`, medio período `SLEEP_MS (x20 >> 1)`.
    - Actualización de cadencia: `x20 = x20 - 50`; si `x20 >= 250` continúa; si no, reinicia `x20 = 1000`.

### 4.4.2 – ex442.s (Cadencia variable con temporizador)

- Igual que 4.4.1 imprime `LED ON`/`LED OFF` con pausas de medio período usando `nanosleep`.
- Cada 200 ms “de tiempo acumulado” ajusta la cadencia en pasos de 15 ms, realizando una rampa:
  - Baja de 1000 ms a 250 ms.
  - Luego sube de 250 ms a 1000 ms.
  - Repite indefinidamente.
- Variables de control: `x20` cadencia, `x21` delta, `x22` periodo de control (200 ms), `x23` dirección (bajar/subir), `x24` acumulador.
- System calls usadas: `write` (64) y `nanosleep` (101).

#### Estructura por bloques

- **Datos/BSS/Macros**
  - Misma organización que 4.4.1: mensajes, `tspec`, `PRINT`, `SLEEP_MS`.
- **_start (estado inicial)**
  - `x20=1000` (cadencia), `x21=15` (delta), `x22=200` (periodo de control), `x23=0` (bajar), `x24=0` (acumulador ms).
- **Bucle principal**
  - ON y OFF con `SLEEP_MS (x20 >> 1)` y suma al acumulador: `x24 += (x20>>1) + (x20>>1) = x20` por ciclo completo.
  - Cuando `x24 >= x22` (200 ms): `x24 -= x22` y se ajusta `x20` según `x23`.
- **Lógica de rampa**
  - Si `x23==0` (bajar): `x20 -= x21` hasta 250; saturación a 250 y cambio `x23=1`.
  - Si `x23==1` (subir): `x20 += x21` hasta 1000; saturación a 1000 y cambio `x23=0`.

### 4.4.3 – ex443.s (Escala musical WAV)

- Genera un archivo `scale.wav` PCM 8‑bit, mono, SR=8000 Hz.
- Escribe una onda cuadrada para tres notas: Do (523 Hz), Mi (659 Hz), Sol (784 Hz), 3 s cada una (total ~9 s).
- Flujo:
  1) Calcula el tamaño de datos y construye el encabezado WAV en memoria.
  2) Abre `scale.wav` con `openat`.
  3) Llama a `write_tone` por cada frecuencia, que genera buffers de 4096 bytes con onda cuadrada y los envía con `write`.
  4) Cierra el archivo y sale.
- System calls usadas: `openat` (56), `write` (64), `close` (57), `exit` (93).

#### Estructura por bloques

- **Constantes**
  - Parámetros de audio: `SR=8000`, `CH=1`, `BITS=8`, `DUR_MS=3000`, frecuencias `F_DO/F_MI/F_SOL`.
  - Syscalls y flags de archivo (`openat`, `O_CREAT|O_TRUNC|O_WRONLY`).
- **Secciones de datos**
  - `fname`: "scale.wav".
  - `hdr`: reserva de 44 bytes para encabezado WAV.
  - `buf`: buffer intermedio de 4096 bytes para streaming de PCM.
- **Subrutina write_tone(fd=x19, freq=x1, dur_ms=x2)**
  - `samples_total = SR * dur_ms / 1000` (x3).
  - `half_period_samples = SR / (2*freq)` (x6) para generar onda cuadrada 0x00/0xFF.
  - Bucle `gen_loop` llena `buf` alternando cada `x6` muestras y hace `write(fd, buf, len)` en bloques `min(4096, restantes)` hasta agotar `samples_total`.
- **Subrutina build_wav_header(ptr=x0, data_bytes=x1)**
  - Escribe: "RIFF", `ChunkSize=36+data_bytes`, "WAVE", "fmt ", tamaño 16, formato 1 (PCM), canales 1, SR 8000, ByteRate 8000, BlockAlign 1, BPS 8, "data", `Subchunk2Size=data_bytes`.
- **_start**
  - `openat` para crear `scale.wav` y guardar fd en `x19`.
  - Calcula `data_bytes = 3 * (SR * DUR_MS / 1000)` (tres notas).
  - Llama `build_wav_header` y lo escribe con `write(fd, hdr, 44)`.
  - Llama `write_tone` para `F_DO`, `F_MI`, `F_SOL`.
  - `close` y `exit`.

---

## Notas

- Los .s no tienen comentarios embebidos; esta documentación describe su comportamiento.
- `gui.py` requiere entorno gráfico (Tk) para ejecutarse.
- `aplay` se usa para reproducir `scale.wav` en 4.4.3.
