# Nota de Obsidian: `LogoBarraSuperior`

## 📁 Ubicación en el Proyecto

`lib/presentation/widgets/logo_barra_superior.dart`

Usado como `leading` del `AppBar` en las tres pantallas raíz del navbar: `HomeScreen`, `AgendaScreen`, `MapaScreen`. Creado el 2026-08-16.

## 🎯 Propósito del Archivo

Muestra el logo de la app (`assets/images/logo_patas_al_dia.png`) pegado a la izquierda de la barra superior, antes del título de cada pantalla.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

**Por qué solo estas tres pantallas y no todas:** en el resto de las pantallas de la app (detalle, formularios, ajustes...), el `leading` del `AppBar` ya lo ocupa automáticamente la flecha de "atrás" que Flutter agrega solo cuando una pantalla se abre con `Navigator.push`. Poner el logo ahí la taparía. Las tres pantallas del navbar son las únicas sin flecha de atrás (son la raíz de su propia pestaña, no se llega empujándolas), así que ahí el logo no compite con nada — decisión explícita del usuario tras plantearle esta restricción.

Se extrajo a un widget compartido (mismo criterio que `MenuUsuarioAvatar`) porque el mismo código se repetía igual en las tres pantallas.
