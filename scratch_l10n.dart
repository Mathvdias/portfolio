import 'dart:io';

void main() {
  final file = File('lib/l10n/app_localizations.dart');
  var content = file.readAsStringSync();

  final newKeys = {
    'en': '''
      "guestbook": "Guestbook",
      "signGuestbook": "Sign the Guestbook",
      "yourName": "Your Name",
      "yourMessage": "Your Message",
      "post": "Post",
      "rating": "Rating: ",
      "noMessages": "No messages yet. Be the first!",
      "messagePosted": "Message posted!",
      "nameMessageEmpty": "Name and message cannot be empty",
      "waitToPost": "Please wait a minute before posting again.",
      "accessDenied": "Access Denied",
      "adminActivated": "Admin mode activated.",
      "adminDeactivated": "Admin mode deactivated.",
      "noNewNotifications": "No new notifications",
      "newGuestbookMessage": "New Guestbook Message",
      "leftReview": "left a review!",
''',
    'pt': '''
      "guestbook": "Livro de Visitas",
      "signGuestbook": "Assine o Livro de Visitas",
      "yourName": "Seu Nome",
      "yourMessage": "Sua Mensagem",
      "post": "Enviar",
      "rating": "Avaliação: ",
      "noMessages": "Nenhuma mensagem ainda. Seja o primeiro!",
      "messagePosted": "Mensagem enviada!",
      "nameMessageEmpty": "Nome e mensagem não podem estar vazios",
      "waitToPost": "Aguarde um minuto antes de postar novamente.",
      "accessDenied": "Acesso Negado",
      "adminActivated": "Modo admin ativado.",
      "adminDeactivated": "Modo admin desativado.",
      "noNewNotifications": "Sem novas notificações",
      "newGuestbookMessage": "Nova Mensagem",
      "leftReview": "deixou uma avaliação!",
''',
  };

  // Replace default fallback for other languages to english
  for (final lang in ['es', 'fr', 'it']) {
    newKeys[lang] = newKeys['en']!;
  }

  for (final lang in newKeys.keys) {
    // Find the end of the language map
    final pattern = '"$lang": {';
    final idx = content.indexOf(pattern);
    if (idx != -1) {
      final insertIdx = content.indexOf('},', idx);
      if (insertIdx != -1) {
        content = content.substring(0, insertIdx) + newKeys[lang]! + content.substring(insertIdx);
      } else {
        // Might be the last one without a comma
        final insertIdxLast = content.indexOf('}', idx);
        content = content.substring(0, insertIdxLast) + newKeys[lang]! + content.substring(insertIdxLast);
      }
    }
  }

  file.writeAsStringSync(content);
  print('Added new localization keys');
}
