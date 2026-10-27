# Plan de testeo cerrado — segunda ronda (tras rechazo de Google Play)

## El rechazo, tal cual lo mandó Google Play

> **More testing required to access Google Play production**
> We reviewed your application, and determined that your app requires more testing before you can access production. Possible reasons why your production access could not be granted include:
> - Testers were not engaged with your app during your closed test.
> - You didn't follow testing best practices, which may include gathering and acting on user feedback through updates to your app.
>
> Before applying again, test your app using closed testing for an additional 14 days with real testers.

**Lo que esto NO es:** un rechazo por un bug puntual, por la ficha de la app o por la política de contenido — nada de lo que ya está resuelto en `PublicacionPlayStore.md` tiene que ver con este mensaje.

**Lo que esto SÍ es:** Google mide señales de uso real durante los 14 días del testeo cerrado (aperturas de la app distribuidas en el tiempo, no solo el día 1) y señales de que el desarrollador recogió feedback y publicó al menos una actualización en respuesta. La ronda de testeo ya hecha (ver `decisiones_arquitectura.md`, entrada del 2026-08-25, `versionCode` 6) tuvo feedback real de los 12 testers, pero concentrado en una sola tanda al principio — no alcanzó para que Google viera actividad sostenida durante las dos semanas completas ni una actualización publicada *durante* ese ciclo (los arreglos se subieron todos juntos, al final, no de a poco mientras el ciclo seguía corriendo).

Este documento resuelve eso: una segunda ronda de 14 días, diseñada para que la actividad quede repartida en el tiempo y quede al menos una actualización real de por medio.

---

## 1. Reabrir el opt-in de los 12 testers

Un tester que ya aceptó la invitación la vez pasada sigue contando, pero tiene que volver a abrir la app durante *este* ciclo — una instalación vieja sin actividad reciente no genera señal nueva. Antes de arrancar el día 1:

- Confirmar en Play Console que el link de opt-in del testeo cerrado sigue activo y que los 12 testers siguen en la lista (correos).
- Mandar el link de vuelta a los 12, pidiendo explícitamente que **actualicen la app a la última versión** y la abran — no alcanza con "ya la tengo instalada".
- Si alguno de los 12 original no está disponible para esta ronda, reemplazarlo antes de empezar — el mínimo de 12 tiene que sostenerse durante todo el ciclo, no solo el día 1.

## 2. Cronograma de 14 días

La clave es que haya actividad **distribuida**, no toda junta. Programar recordatorios (calendario, alarma, lo que sea) para estas cinco fechas, que se corresponden con las cinco sesiones de `InstruccionesTesters.md`:

| Día | Sesión | Qué se cubre |
|---|---|---|
| 1 | Sesión 1 | Modo invitado: mascota, credencial |
| 3-4 | Sesión 2 | Agenda, medicamentos, documentos |
| 7-8 | Sesión 3 | Cuenta, recuperar/cambiar contraseña, sincronización |
| 11 | Sesión 4 | Mapa, Ajustes (idioma/tema), reportar un bug |
| 13-14 | Sesión 5 | Repaso general, eliminar cuenta (quien se anime), cierre |

Mandar el recordatorio de cada sesión el mismo día a los 12 testers (mensaje corto: "sesión de hoy: esto y esto, cuéntennos en el grupo").

## 3. Canal de feedback

Hace falta un lugar donde los testers dejen un rastro escrito y con fecha — es lo que Google llama "gathering feedback". Dos opciones razonables para un grupo de 12 amigos/familiares, sin herramientas corporativas:

- **Grupo de WhatsApp/Telegram.** Fricción mínima (todos ya lo usan), pero el historial es menos ordenado para releer después.
- **Un Google Form corto** (1-2 preguntas: "¿qué probaste?" y "¿encontraste algo raro?"), enlazado desde un mensaje fijo del grupo. Más prolijo para releer después, pero un paso extra para cada tester.

Cualquiera de las dos sirve; lo que importa es que haya mensajes/respuestas fechados a lo largo de las cinco sesiones, no todos concentrados en un solo día.

## 4. Publicar al menos una actualización real durante el ciclo

Esto es lo que Google llama explícitamente "acting on user feedback through updates to your app" — y es el punto que más probablemente faltó la vez pasada. Instrucciones:

- Entre la Sesión 2 y la Sesión 4 (días ~5 a ~10), tomar **al menos un** comentario real de los testers —no hace falta que sea grave, puede ser un texto confuso, un ícono poco visible, un detalle visual— y arreglarlo.
- Subir un `versionCode` nuevo al **mismo track de testeo cerrado** (no crear uno nuevo) — `flutter build appbundle --release` como siempre, ver `PublicacionPlayStore.md`.
- Documentar el cambio en dos lugares, como ya es la costumbre del proyecto:
  - una entrada nueva en `decisiones_arquitectura.md` (qué feedback se recibió, qué se cambió, `versionCode`),
  - una línea en la tabla de seguimiento de la sección 6 de este mismo documento.
- Avisar en el canal de feedback que se subió una actualización y por qué ("arreglamos lo que dijiste de tal cosa") — ese aviso es también parte de la señal de "actuaste sobre el feedback".

## 5. Mantener el proyecto de Supabase despierto todo el ciclo

Riesgo real, ya documentado (`decisiones_arquitectura.md`, entrada del 2026-09-27 "Módulo Mapa cargando eternamente"): el proyecto de Supabase gratis se pausa solo por inactividad y hay que reactivarlo a mano desde el dashboard. Si se pausa en medio de los 14 días, el módulo Mapa deja de responder para todos los testers al mismo tiempo — exactamente el tipo de corte que hace que un tester abandone y deje de aparecer como "engaged". Con el timeout de 15 segundos ya agregado, al menos no se queda colgado para siempre, pero sigue siendo un módulo roto si pasa.

Entrar al dashboard de Supabase (`wegffggssmddbcbpdujv.supabase.co`) **al menos una vez cada 5 días** durante el ciclo — coincide aproximadamente con las sesiones de la tabla de arriba, así que conviene revisarlo justo antes de mandar cada recordatorio de sesión.

## 6. Tabla de seguimiento de esta ronda

Completar a medida que avanza el ciclo (reemplaza este placeholder por la fecha real de inicio):

| Fecha | Evento |
|---|---|
| — | Día 1 — reapertura del opt-in, Sesión 1 mandada |
| — | Actualización subida en respuesta a feedback (completar `versionCode` y qué se arregló) |
| — | Día 14 — cierre del ciclo |
| — | Pase a producción vuelto a pedir en Play Console |

## 7. Checklist final antes de volver a pedir el pase a producción

- [ ] Los 12 testers abrieron la app en más de una de las cinco sesiones (no solo el día 1)
- [ ] El canal de feedback tiene mensajes fechados a lo largo de las cinco sesiones, no todos el mismo día
- [ ] Se publicó al menos una actualización real (`versionCode` nuevo) en respuesta a feedback recibido *durante* el ciclo, al mismo track de testeo cerrado
- [ ] Esa actualización y el feedback que la motivó quedaron documentados en `decisiones_arquitectura.md` y en la tabla de la sección 6
- [ ] El proyecto de Supabase se mantuvo activo (sin pausa) durante todo el ciclo
- [ ] Los cinco módulos (Mascotas/Agenda/Documentos/Mapa/Cuenta) quedaron cubiertos entre las cinco sesiones de `InstruccionesTesters.md`
- [ ] Pasaron los 14 días completos desde la reapertura del opt-in

Recién con todo esto marcado, volver a Play Console → pedir el pase a producción.

---

## 8. Instrucciones para los testers

El texto que se comparte con los 12 testers vive aparte, en `InstruccionesTesters.md` — mismo cronograma de cinco sesiones que la sección 2, en inglés, español y portugués, en lenguaje profesional y conciso, listo para copiar y pegar en el canal de feedback (completo o solo la sección del idioma de cada tester).
