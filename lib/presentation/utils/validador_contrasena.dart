import 'package:patas_al_dia/l10n/app_localizations.dart';

// Requisitos de contraseña (2026-08-20, decisión del usuario): mínimo 8
// caracteres, una mayúscula y un número — sin símbolo obligatorio, a
// propósito. Se descartó exigir un símbolo porque es la regla que más
// friccional resulta para el usuario a cambio de la menor ganancia real de
// seguridad (el largo mínimo aporta más que la complejidad de caracteres).
// Compartido entre RegistroScreen y NuevaContrasenaScreen — antes cada
// pantalla tenía su propio validador de una sola línea ("mínimo 6
// caracteres"); con tres reglas a la vez ya valía la pena extraerlo en vez
// de duplicar la lógica.
String? validarContrasena(AppLocalizations l10n, String? valor) {
  if (valor == null || valor.isEmpty) {
    return l10n.errorContrasenaObligatoria;
  }
  final cumpleRequisitos =
      valor.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(valor) &&
      RegExp(r'[0-9]').hasMatch(valor);
  if (!cumpleRequisitos) {
    return l10n.errorContrasenaCorta;
  }
  return null;
}
