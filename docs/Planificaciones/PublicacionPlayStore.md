# Datos para la publicación en Google Play

Referencia rápida con lo que hace falta al completar la ficha de la app y el formulario de "Seguridad de los datos" (Data safety) en Play Console. Se actualiza a medida que se resuelvan pendientes.

## Enlaces a completar en Play Console

- **Política de privacidad** (campo obligatorio, ficha de la app):
  `https://breakpointx13.github.io/PatasAlDiaWeb/privacidad-es.html`
  (también existe en inglés y portugués, con selector de idioma dentro de la misma página — alcanza con enviar la de español, que coincide con el idioma principal de la ficha)

- **Borrado de cuenta** (sección "Account deletion" del formulario de Data safety, exige un enlace que funcione sin tener la app instalada):
  `https://breakpointx13.github.io/PatasAlDiaWeb/eliminar-cuenta-es.html`

- **Correo de contacto/soporte**: `breakpointx.dev@gmail.com`

## Formulario "Seguridad de los datos" (Data safety)

Datos que la app recopila (usuarios registrados) y por qué:

| Dato | ¿Se recopila? | Motivo | ¿Opcional? |
|---|---|---|---|
| Correo electrónico | Sí | Cuenta de usuario | Sí — el modo invitado no lo pide |
| Fotos | Sí | Fotos de mascotas y documentos, y foto del reporte en Mapa | Sí |
| Archivos y documentos | Sí | Carnet de vacunación, exámenes, recetas | Sí |
| Ubicación (aproximada o precisa) | Sí, solo si se publica un reporte de mascota perdida | Mostrar el reporte en el mapa | Sí — es una función opcional |
| Otra información personal | Sí, solo si se publica un reporte | Contacto de emergencia, para que otros puedan avisar | Sí |

- **¿Los datos se comparten con terceros?** No. Se usa Supabase como proveedor de infraestructura (aloja la base de datos y los archivos) — no cuenta como "compartir con terceros" para fines propios, es un procesador de datos, no un tercero que los use por su cuenta.
- **¿Los datos viajan cifrados?** Sí (HTTPS/TLS hacia Supabase).
- **¿Se puede pedir el borrado de los datos?** Sí — desde la app (Ajustes → Eliminar cuenta) o desde la web (enlace de arriba), sin tener la app instalada.
- **¿El borrado es inmediato y completo?** Sí — borra la cuenta de Supabase Auth y, en cascada, todas las mascotas/agenda/documentos asociados del lado del servidor. No borra los datos guardados localmente en cada dispositivo (para eso hay que desinstalar la app en cada uno) — ya aclarado en las páginas de política de privacidad y borrado de cuenta.
- **Publicidad/rastreo de terceros:** ninguno. No hay SDKs de publicidad ni analítica de terceros en la app.

## Resuelto

- **`applicationId` — hecho (2026-08-21).** Era `com.example.patas_al_dia` (placeholder por defecto de Flutter, que Google Play rechaza publicar); se cambió a `dev.breakpointx.patasaldia` en Android, iOS y macOS. Verificado con un reinstall limpio en el dispositivo de prueba: login y sincronización funcionan igual que antes. Los esquemas de deep link (`patasaldia://reset-password`) y las Redirect URLs de Supabase no dependen del `applicationId`, así que no hizo falta tocarlos.

- **Firma de release — hecho (2026-08-21).** El build de release usaba la clave de *debug* (la misma de cualquier proyecto Flutter nuevo, no válida para publicar). Se generó un keystore de subida real (`~/keystores/patas_al_dia/upload-keystore.jks`, alias `patasaldia_upload`, contraseñas aleatorias) y se conectó en `android/app/build.gradle.kts` vía `android/key.properties` (gitignorado, nunca se sube al repo). Es una "clave de subida" para Play App Signing, no la clave final con la que Play distribuye la app — perderla no es catastrófico (Google puede resetearla), pero igual conviene tenerla respaldada en un lugar seguro (fuera de este equipo también, por si se pierde el disco).
  - Verificado generando un App Bundle real (`flutter build appbundle --release`) y comparando el certificado embebido contra el del keystore — coinciden (mismo número de serie). Ese `.aab` (`build/app/outputs/bundle/release/app-release.aab`) es el archivo que se sube a Play Console.
  - **Pendiente de decidir, no bloqueante:** hoy solo existe una copia del keystore, en este equipo. Conviene guardar una copia de respaldo (y de `key.properties`) en otro lugar antes de subir la primera versión — sin el keystore no se puede publicar ninguna actualización futura de la app con esta cuenta de subida.
