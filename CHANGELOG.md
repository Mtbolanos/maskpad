# Cambios

Versión y build de cada IPA (`version.json`). Los builds intermedios de prueba se compilaron en ramas
aparte y no se listan.

## 0.4.1 (build 16)

- Con una pantalla externa conectada, el menú abierto en el dispositivo ya no hace saltar los FPS a la tasa
  del dispositivo: el juego mantiene la tasa de la pantalla externa, y Native Screen Resolution no aplica.
- El audio se vuelve a abrir solo cuando iOS cambia la salida (tele, audífonos, AirPods). Antes podía
  quedar en silencio al conectar o desconectar en caliente.

## 0.4.0 (build 15)

- **Extend to External Display** (Settings → Graphics, activado por defecto): el juego pasa a pantalla
  completa en la tele o el monitor (USB-C/HDMI o AirPlay), a su resolución real de salida, y el dispositivo
  queda como control. El menú abierto con `•••` aparece en el dispositivo; abierto desde un control, en la
  pantalla externa.
- Los controles táctiles se ocultan solos con un gamepad conectado (el botón de menú se mantiene).
- Los FPS siguen la tasa de la pantalla donde está el juego.
- Corregido el texto del menú que se corrompía al cambiar de pantalla.
- CI: verificación de que los parches de SDL se apliquen sobre código limpio y ya parchado.

## 0.3.1 (build 9)

- En iPadOS 26+, el control (DualSense, Xbox) ya no escribe teclas fantasma (flechas, Return, Escape,
  Pause), y ○/B ya no abre el menú.

## 0.3.0 (build 7)

- Actualizado a **2 Ship 2 Harkinian 5.0.1 "Battler Bravo"** (antes 4.0.2), con el upstream oficial
  fijado por commit y parches revisables.
- ProMotion: la interpolación sigue la tasa real de la pantalla (120 Hz, o 60 en modo de bajo consumo).
- Menús nítidos a la resolución del panel y opción **Native Screen Resolution** para el juego.
- **Lock at 60 FPS**, opcional, para jugar a resolución nativa con 60 estables.
- Scroll táctil en los menús, sin mover sliders por accidente.
- El aviso de caída de FPS compara con el objetivo real.
- Nuevo bundle ID `cl.mtbolanoss.maskpad` y README en español.
