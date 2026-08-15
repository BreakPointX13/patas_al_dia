# Nota de Obsidian: `MedicamentoEventoModel`

## 📁 Ubicación en el Proyecto

`lib/data/models/medicamento_evento_model.dart`

## 🎯 Propósito del Archivo

Modelo de mapeo para los medicamentos recetados en un evento de agenda. Traduce filas de `medicamentos_evento` a objetos tipados, mismo patrón manual (sin ORM) que el resto de los modelos del proyecto. Creado el 2026-08-14.

---

## 🗺️ Mapa de Conexión Conceptual

### 🐾 En Nuestro Proyecto "Patas al día"

Un evento de agenda puede tener **varios** medicamentos (por eso es una tabla hija aparte y no un campo de texto en `AgendaEventoModel` — ver la entrada del 2026-08-14 en `decisiones_arquitectura.md`). Cada medicamento tiene tres datos: `tipoPresentacion` (Comprimido/Líquido/Inyectable/Pomada-crema/Gotas/Pipeta/Otro — lista cerrada definida en `FormularioAgendaEventoScreen`, no en este modelo), `nombre` (texto libre) y `observaciones` (texto libre opcional, cubre también el caso "Otro" sin necesitar un campo aparte de "especificar").

---

## ⚙️ Glosario de Funciones y Componentes Complejos

### 1. `agendaEventoId` — Foreign Key obligatoria

A diferencia de `eventoId` en `DocumentoModel` (opcional, `ON DELETE SET NULL`), acá `agendaEventoId` es obligatorio y la relación en SQL usa `ON DELETE CASCADE`: un medicamento no tiene sentido sin su evento, así que si se borra el evento, sus medicamentos se borran con él.

### 2. `fromMap` / `toMap` / `copyWith`

Mismo patrón exacto que `MascotaModel`/`AgendaEventoModel`: `fromMap` deserializa desde SQLite, `toMap` serializa hacia SQLite, `copyWith` genera una copia inmutable reemplazando solo los campos pasados. No hay campos booleanos ni fechas en este modelo, así que no hace falta ninguna de las conversiones especiales (`== 1`, `.toIso8601String()`) que sí aparecen en los otros modelos.
