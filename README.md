# mu-vision
Freecam cinematográfico para FiveM (standalone, compatible con qbox/qbcore/esx).


![3918f8458f2822b220de0d433cb4c092](https://github.com/user-attachments/assets/0ed6a043-db07-4be9-b993-f1d471731a7d)


## Características
- Tecla **F9** para activar/desactivar freecam (comando `/muvision` con KeyMapping).
- Moverse con **WASD**, **Espacio** (subir), **CTRL** (bajar/ir lento), **SHIFT** (ir rápido).
- Rotación con el ratón.
- Zoom con **rueda del ratón** (ajusta el FOV).
- Oculta HUD/minimapa solo mientras está activo (sin cambiar tu estado global).
- Solo cliente; sin dependencias.

## Instalación
1. Descarga el `.zip` y extrae la carpeta **mu-vision** en `resources/` de tu servidor.
2. Añade en tu `server.cfg`:
   ```cfg
   ensure mu-vision
   ```
3. (Opcional) Ajusta valores en `config.lua` (velocidades, sensibilidad, FOV, HUD).

## Controles
- **F9**: activar/desactivar.
- **Flechas Izquierda/Derecha**: desplazamiento lateral.
- **Flechas Arriba/Abajo**: avanzar/retroceder la cámara.
- **SHIFT**: rápido.
- **CTRL**: lento (y bajar si lo mantienes).
- **ESPACIO**: subir.
- **Rueda ratón**: zoom (FOV).
- Ratón: rotación.

## Notas
- Funciona en cualquier framework porque es 100% cliente. Probado con QBCore/Qbox.
- Si quieres otro atajo, cambia el último parámetro de `RegisterKeyMapping` o usa bindings del juego.

## Créditos
Creado para alex (@nosovkboserovmp). Disfruta de tus tomas estilo cine ✨
