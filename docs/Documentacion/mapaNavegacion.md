# Mapa de navegación — Patas al Día

Diagrama de flujo con las ~24 pantallas de `lib/presentation/screens/` y cómo se llega de una a otra (`Navigator.push`, deep links, pestañas). No es un UML de clases — es un mapa de navegación, pensado para ver de un vistazo qué pantalla abre a cuál.

Se arma leyendo directamente los `Navigator.push`/`MaterialPageRoute` de cada pantalla (no es un diseño a priori) — si el código de navegación cambia, este archivo hay que actualizarlo a mano, no se regenera solo.

**Versión interactiva (con zoom real, arrastre y pellizco):** `mapaNavegacion.html`, en esta misma carpeta — ábrelo directo en el navegador. El diagrama de abajo es la versión estática, para verlo sin salir de VS Code/Obsidian/GitHub.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#F3C98F','primaryTextColor':'#7A4A22','primaryBorderColor':'#7A4A22','lineColor':'#7A4A22','fontFamily':'JetBrains Mono, monospace','fontSize':'13px'}, 'flowchart': {'curve':'basis','nodeSpacing':55,'rankSpacing':75}}}%%
flowchart TD
    SesionInicial(["SesionInicialScreen"])
    Login(["LoginScreen"])
    IniciarSesion(["IniciarSesionScreen"])
    Registro(["RegistroScreen"])
    RecuperarContrasena(["RecuperarContrasenaScreen"])
    NuevaContrasena(["NuevaContrasenaScreen"])

    Home(["HomeScreen · pestaña Mascotas"])
    Agenda(["AgendaScreen · pestaña Agenda"])
    Mapa(["MapaScreen · pestaña Mapa"])

    FormularioMascota(["FormularioMascotaScreen"])
    DetalleMascota(["DetalleMascotaScreen"])
    CredencialMascota(["CredencialMascotaScreen"])

    Documentos(["DocumentosScreen"])
    FormularioDocumento(["FormularioDocumentoScreen"])
    DetalleDocumento(["DetalleDocumentoScreen"])
    VisorImagen(["VisorImagenScreen"])

    FormularioAgendaEvento(["FormularioAgendaEventoScreen"])
    DetalleAgendaEvento(["DetalleAgendaEventoScreen"])

    FormularioReporte(["FormularioReporteMascotaExtraviadaScreen"])
    DetalleReporte(["DetalleReporteMascotaExtraviadaScreen"])

    Ajustes(["AjustesScreen"])
    CambiarContrasena(["CambiarContrasenaScreen"])
    ReportarBug(["ReportarBugScreen"])

    SesionInicial -->|"con sesión activa"| Home
    SesionInicial -->|"sin sesión"| Login

    Login -->|"continuar como invitado"| Home
    Login -->|"iniciar sesión"| IniciarSesion

    IniciarSesion --> Home
    IniciarSesion --> RecuperarContrasena
    IniciarSesion --> Registro

    Registro --> Home

    RecuperarContrasena -.->|"enlace por correo<br/>(deep link)"| NuevaContrasena
    NuevaContrasena --> Home

    Home -->|"+ nueva mascota"| FormularioMascota
    Home -->|"tocar mascota"| DetalleMascota
    Home -->|"ver credencial"| CredencialMascota

    DetalleMascota -->|"editar"| FormularioMascota
    DetalleMascota -->|"agenda de esta mascota"| Agenda
    DetalleMascota -->|"documentos"| Documentos
    DetalleMascota -->|"reportar perdida"| FormularioReporte

    Documentos -->|"+ nuevo documento"| FormularioDocumento
    Documentos -->|"tocar documento"| DetalleDocumento
    DetalleDocumento -->|"editar"| FormularioDocumento
    DetalleDocumento -->|"ver imagen"| VisorImagen

    Agenda -->|"+ nuevo evento"| FormularioAgendaEvento
    Agenda -->|"tocar evento"| DetalleAgendaEvento
    DetalleAgendaEvento -->|"editar"| FormularioAgendaEvento
    DetalleAgendaEvento -->|"ver imagen adjunta"| VisorImagen

    Mapa -->|"tocar reporte"| DetalleReporte
    Mapa -->|"+ nuevo reporte"| FormularioReporte

    Home -->|"ícono de usuario"| Ajustes
    Agenda -->|"ícono de usuario"| Ajustes
    Mapa -->|"ícono de usuario"| Ajustes

    Ajustes -->|"cerrar sesión / eliminar cuenta"| Login
    Ajustes -->|"invitado que se registra"| Registro
    Ajustes -->|"cambiar contraseña"| CambiarContrasena
    Ajustes -->|"reportar un bug"| ReportarBug

    classDef sello fill:#E0812F,stroke:#7A4A22,stroke-width:2px,color:#FFF7EC,font-weight:600;
    classDef parada fill:#F3C98F,stroke:#7A4A22,stroke-width:1.4px,color:#7A4A22;
    class SesionInicial,Home,Agenda,Mapa,Ajustes sello;
    class Login,IniciarSesion,Registro,RecuperarContrasena,NuevaContrasena,FormularioMascota,DetalleMascota,CredencialMascota,Documentos,FormularioDocumento,DetalleDocumento,VisorImagen,FormularioAgendaEvento,DetalleAgendaEvento,FormularioReporte,DetalleReporte,CambiarContrasena,ReportarBug parada;
```

## Notas

- **Las 3 pestañas de `NavegacionPrincipalScreen`** (Mascotas/Agenda/Mapa) tienen cada una su propio `Navigator` interno — cambiar de pestaña no reinicia la pila de la pestaña anterior (ver `screens/navegacionPrincipalScreen.md` si existe, o el comentario en el propio archivo).
- **`AjustesScreen`** no es una pestaña — se llega a través de `MenuUsuarioAvatar`, el ícono de usuario que aparece en el `AppBar` de las 3 pestañas.
- **`VisorImagenScreen`** es una pantalla terminal (solo muestra una imagen a pantalla completa) — se llega desde Documentos y desde Agenda (documento adjunto a un evento), pero no navega a ningún lado más.
- **`RecuperarContrasenaScreen` → `NuevaContrasenaScreen`** no es un `Navigator.push` directo — pasa por un correo real con un deep link (`patasaldia://reset-password`), por eso la flecha punteada.
