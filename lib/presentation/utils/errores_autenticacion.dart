import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_al_dia/l10n/app_localizations.dart';

// Traduce los códigos de error más comunes de Supabase Auth (`AuthException`)
// a un mensaje ya traducido — mismo criterio que el resto de la app, nunca
// se le muestra al usuario el texto crudo en inglés que devuelve Supabase.
// Códigos no reconocidos (o errores sin `AuthApiException.code`, ej. sin
// conexión) caen al mensaje genérico. Compartido entre RegistroScreen e
// IniciarSesionScreen — ver sus respectivos .md.
String mensajeErrorAutenticacion(AppLocalizations l10n, AuthException e) {
  final codigo = e is AuthApiException ? e.code : null;
  switch (codigo) {
    case 'invalid_credentials':
      return l10n.errorCredencialesInvalidas;
    case 'email_not_confirmed':
      return l10n.errorEmailNoConfirmado;
    case 'weak_password':
      return l10n.errorContrasenaCorta;
    case 'otp_expired':
      return l10n.errorEnlaceInvalido;
    case 'user_already_exists':
    case 'email_exists':
      return l10n.errorEmailYaRegistrado;
    default:
      return l10n.errorAutenticacionGenerico;
  }
}
