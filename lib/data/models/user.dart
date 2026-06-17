import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class User {
  int? id;
  String nome;
  String email;
  SecretBox senhaMestre;
  SecretBox senhaRecup;

  User({
    this.id,
    required this.nome,
    required this.email,
    required this.senhaMestre,
    required this.senhaRecup,
  });

  // Serializa um SecretBox para JSON string para persistir no banco
  static String _secretBoxToJson(SecretBox box) {
    return jsonEncode({
      'cipherText': base64Encode(box.cipherText),
      'nonce':      base64Encode(box.nonce),
      'mac':        base64Encode(box.mac.bytes),
    });
  }

  // Desserializa um JSON string de volta para SecretBox
  static SecretBox _secretBoxFromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return SecretBox(
      base64Decode(map['cipherText'] as String),
      nonce: base64Decode(map['nonce']     as String),
      mac:   Mac(base64Decode(map['mac']   as String)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':          id,
      'nome':        nome,
      'email':       email,
      'senhaMestre': _secretBoxToJson(senhaMestre),
      'senhaRecup':  _secretBoxToJson(senhaRecup),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id:           map['id']   as int?,
      nome:         map['nome'] as String,
      email:        map['email'] as String,
      senhaMestre:  _secretBoxFromJson(map['senhaMestre'] as String),
      senhaRecup:   _secretBoxFromJson(map['senhaRecup']  as String),
    );
  }
}