# Nota de Obsidian: `MenuUsuarioAvatar`

## 📁 Ubicación en el Proyecto

`lib/presentation/widgets/menu_usuario_avatar.dart`

Primer archivo de la carpeta `widgets/`, hermana de `screens/` — se creó porque este ícono se repite igual en el `AppBar` de las tres pantallas raíz de `NavegacionPrincipalScreen` (`HomeScreen`, `AgendaScreen`, `MapaScreen`), así que conviene un único widget reutilizable en vez de copiar el mismo código tres veces.

## 🎯 Propósito del Archivo

Reemplaza al ícono de engranaje que antes vivía solo en `HomeScreen`. Es un ícono de avatar en el `AppBar` que, al tocarlo, abre un menú desplegable con la opción "Ajustes" (empuja `AjustesScreen` dentro del `Navigator` de la pestaña activa).

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

No muestra una foto real de usuario — `UsuarioModel` todavía no tiene un campo de foto — así que por ahora es un ícono genérico (`Icons.person`) dentro de un `CircleAvatar`. Cuando exista una foto de perfil real, este widget es el único lugar que habría que tocar para mostrarla en las tres pantallas a la vez.

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `PopupMenuButton<void>`

```dart
PopupMenuButton<void>(
  tooltip: 'Cuenta',
  icon: const CircleAvatar(child: Icon(Icons.person)),
  itemBuilder: (context) => [
    PopupMenuItem<void>(
      onTap: () => _irAAjustes(context),
      child: const ListTile(
        leading: Icon(Icons.settings),
        title: Text('Ajustes'),
      ),
    ),
  ],
)
```

Widget nativo de Flutter para menús desplegables — no hace falta ningún paquete nuevo. El tipo genérico (`<void>`) indica que no nos interesa el valor que devuelve el menú al cerrarse (a diferencia de un `PopupMenuButton<String>`, por ejemplo, donde cada opción devolvería un valor distinto); en vez de eso, cada opción dispara su propia acción directamente en su `onTap`.

### Tooltip y etiqueta vía `AppLocalizations` (2026-08-18)

`tooltip: l10n.cuentaTooltip` y `title: Text(l10n.ajustesTitulo)` — ver `sistemaIdiomas.md`. `ajustesTitulo` es la misma clave que usa `AjustesScreen` para el título de su propio `AppBar`, ya que es el mismo texto ("Ajustes") en los dos lugares.
