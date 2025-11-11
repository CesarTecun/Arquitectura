import os
import sys
import threading
import subprocess
import shutil
import tkinter as tk

ROOT = os.path.dirname(__file__)
P441 = os.path.join(ROOT, "Ejercicio 4.4.1-Cadencia variable con bucle de retardo")
P442 = os.path.join(ROOT, "Ejercicio 4.4.2-Cadencia variable con temporizador")
P443 = os.path.join(ROOT, "Ejercicio 4.4.3-Escala musical")
B441 = os.path.join(P441, "ex441")
B442 = os.path.join(P442, "ex442")
B443 = os.path.join(P443, "ex443")
SCALE = os.path.join(P443, "scale.wav")

class Runner:
    def __init__(self, cmd, cwd, on_line):
        self.cmd = cmd
        self.cwd = cwd
        self.on_line = on_line
        self.proc = None
        self.thread = None

    def start(self):
        if self.proc is not None:
            return
        self.proc = subprocess.Popen(self.cmd, cwd=self.cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        self.thread = threading.Thread(target=self._pump, daemon=True)
        self.thread.start()

    def _pump(self):
        assert self.proc is not None and self.proc.stdout is not None
        for line in self.proc.stdout:
            self.on_line(line.rstrip())
        self.proc = None

    def stop(self):
        if self.proc is not None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=2)
            except Exception:
                self.proc.kill()
            self.proc = None

class App:
    def __init__(self, root):
        self.root = root
        root.title("GUI - 4.4.x")
        root.geometry("520x320")

        self.led1 = tk.Label(root, text="4.4.1", width=12, height=6, bg="#888", fg="white")
        self.led2 = tk.Label(root, text="4.4.2", width=12, height=6, bg="#888", fg="white")
        self.led1.grid(row=0, column=0, padx=10, pady=10)
        self.led2.grid(row=0, column=1, padx=10, pady=10)

        self.btn1 = tk.Button(root, text="Iniciar 4.4.1", command=self.toggle_441)
        self.btn2 = tk.Button(root, text="Iniciar 4.4.2", command=self.toggle_442)
        self.btn1.grid(row=1, column=0)
        self.btn2.grid(row=1, column=1)

        sep = tk.Frame(root, height=2, bd=1, relief=tk.SUNKEN)
        sep.grid(row=2, column=0, columnspan=3, sticky="we", pady=10, padx=10)

        self.btn_gen = tk.Button(root, text="Generar 4.4.3", command=self.run_443)
        self.btn_play = tk.Button(root, text="Reproducir WAV", command=self.play_wav)
        self.lbl443 = tk.Label(root, text="scale.wav: -")
        self.btn_gen.grid(row=3, column=0, padx=10, pady=4)
        self.btn_play.grid(row=3, column=1, padx=10, pady=4)
        self.lbl443.grid(row=4, column=0, columnspan=3, sticky="w", padx=10)

        self.r1 = Runner([B441], P441, self._line441)
        self.r2 = Runner([B442], P442, self._line442)

    def _line441(self, line):
        self.root.after(0, self._update_led, self.led1, line)

    def _line442(self, line):
        self.root.after(0, self._update_led, self.led2, line)

    def _update_led(self, widget, line):
        widget.config(bg="#FFEB3B" if "ON" in line else "#777")

    def toggle_441(self):
        if self.r1.proc:
            self.r1.stop(); self.led1.config(bg="#888"); self.btn1.config(text="Iniciar 4.4.1")
        else:
            if not os.path.exists(B441):
                self.alert("Falta binario ex441. Ejecuta build_all.sh")
                return
            self.r1.start(); self.btn1.config(text="Detener 4.4.1")

    def toggle_442(self):
        if self.r2.proc:
            self.r2.stop(); self.led2.config(bg="#888"); self.btn2.config(text="Iniciar 4.4.2")
        else:
            if not os.path.exists(B442):
                self.alert("Falta binario ex442. Ejecuta build_all.sh")
                return
            self.r2.start(); self.btn2.config(text="Detener 4.4.2")

    def run_443(self):
        if not os.path.exists(B443):
            self.alert("Falta binario ex443. Ejecuta build_all.sh")
            return
        self.btn_gen.config(state=tk.DISABLED, text="Generando...")
        def work():
            subprocess.run([B443], cwd=P443)
            ok = os.path.exists(SCALE)
            self.root.after(0, lambda: [self.lbl443.config(text=f"scale.wav: {'OK' if ok else 'NO'}"), self.btn_gen.config(state=tk.NORMAL, text="Generar 4.4.3")])
        threading.Thread(target=work, daemon=True).start()

    def play_wav(self):
        aplay = shutil.which("aplay")
        if not os.path.exists(SCALE):
            self.alert("No existe scale.wav. Genera primero.")
            return
        if not aplay:
            self.alert("No se encontró aplay (alsa-utils)")
            return
        threading.Thread(target=lambda: subprocess.run([aplay, SCALE]), daemon=True).start()

    def alert(self, msg):
        tk.messagebox.showinfo("Aviso", msg)

if __name__ == "__main__":
    tk.messagebox = __import__('tkinter').messagebox
    root = tk.Tk()
    App(root)
    root.mainloop()
