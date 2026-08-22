# Datos para la publicación en Google Play

Referencia rápida con lo que hace falta al completar la ficha de la app y el formulario de "Seguridad de los datos" (Data safety) en Play Console. Se actualiza a medida que se resuelvan pendientes.

## Enlaces a completar en Play Console

- **Política de privacidad** (campo obligatorio, ficha de la app):
  `https://breakpointx13.github.io/PatasAlDiaWeb/privacidad-es.html`
  (también existe en inglés y portugués, con selector de idioma dentro de la misma página — alcanza con enviar la de español, que coincide con el idioma principal de la ficha)

- **Borrado de cuenta** (sección "Account deletion" del formulario de Data safety, exige un enlace que funcione sin tener la app instalada):
  `https://breakpointx13.github.io/PatasAlDiaWeb/eliminar-cuenta-es.html`

- **Correo de contacto/soporte**: `breakpointx.dev@gmail.com`

## Ficha de la app — texto (español)

**Título** (27/30 caracteres):
```
Patas al Día: Salud Mascota
```

**Descripción corta** (74/80 caracteres):
```
Agenda veterinaria, documentos y mascotas perdidas, todo en un solo lugar.
```

**Descripción larga** (1643/4000 caracteres):
```
Patas al Día es la app para organizar todo lo importante sobre la salud y los cuidados de tu mascota, en un solo lugar y sin complicaciones.

🐾 MASCOTAS
Registra a cada una de tus mascotas con sus datos: especie, raza, peso, número de chip, esterilización y una foto. Toda la información queda ordenada y a mano cuando la necesites.

📅 AGENDA VETERINARIA
Lleva el control de vacunas, controles, desparasitaciones y cualquier evento veterinario. Agrega los medicamentos recetados en cada consulta y activa recordatorios para no olvidar la próxima dosis o el próximo control.

📄 DOCUMENTOS
Guarda el carnet de vacunación, exámenes, recetas y certificados directamente en la app, junto con la fecha de vencimiento cuando corresponda. Nunca más buscar un papel en el último momento.

🗺️ MASCOTAS PERDIDAS
Si tu mascota se pierde, publica un reporte con foto y ubicación para que la comunidad te ayude a encontrarla. También puedes revisar el mapa para ver si hay reportes cerca de ti.

SIN REGISTRO OBLIGATORIO
Puedes usar Patas al Día como invitado, sin crear ninguna cuenta: todos tus datos quedan guardados únicamente en tu dispositivo. Si más adelante quieres respaldarlos y verlos desde otro teléfono, puedes crear una cuenta cuando quieras, sin perder nada de lo que ya cargaste.

PRIVACIDAD PRIMERO
No hay publicidad ni rastreo de terceros. Tus datos son tuyos: puedes eliminarlos por completo cuando quieras, desde la app o desde la web.

Disponible en español, inglés y portugués.

Patas al Día es gratuita. Si te resulta útil y quieres apoyar el desarrollo, hay una opción de aportes voluntarios dentro de la app — nunca es obligatorio.
```

*(Pendiente: la misma ficha en inglés y portugués, si se quiere publicar en esos idiomas también — Play Console permite una ficha por idioma.)*

## Testing cerrado obligatorio (cuenta nueva)

Las cuentas de desarrollador **personales** creadas después de noviembre de 2023 (aplica a esta cuenta, al ser nueva) no pueden publicar directo a producción — Google exige primero un test cerrado con **al menos 12 testers**, opt-in continuo durante **14 días seguidos**, antes de habilitar el pase a producción. No aplica a cuentas de organización ni a cuentas personales más viejas. Conviene ir consiguiendo los 12 testers (amigos, familia) apenas esté creada la cuenta, para no perder tiempo al final — ver [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

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
