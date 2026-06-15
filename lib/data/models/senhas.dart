class Senha{
  int? id;
  String titulo;
  String cipherText;
  String authTag;
  String iv;
  String usuario;

  Senha({
    this.id,
    required this.titulo,
    required this.cipherText,
    required this.authTag,
    required this.iv,
    required this.usuario
  });

  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'titulo': titulo,
      'senha': cipherText,
    };
  }
}