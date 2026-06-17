import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:url_launcher/url_launcher.dart';

// funcao para derivar chaves
Future<List<int>> derivate(String input, List<int> salt) async{
  final argon2 = Argon2id(
    hashLength: 32,
    memory: 64 * 1024,
    parallelism: 1,
    iterations: 3
  );

  final SecretKey secretKey = await argon2.deriveKey(
    secretKey: SecretKey(utf8.encode(input)),
    nonce: salt
  );

  return await secretKey.extractBytes();
}

// funcao para enviar email para si mesmo
void sendEmail(String dbKeyRecup, String email){
  final Uri emailLauncher = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject': 'Senha de recuperação Krypton',
      'body': dbKeyRecup
    }
  );

  launchUrl(emailLauncher);
}