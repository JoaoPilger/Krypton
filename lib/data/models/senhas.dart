class Senha {
  int? id;
  int? userID;
  String titulo;
  String cipherText;
  String authTag;
  String iv;
  String usuario;
  String tipo;
  String? url;

  Senha({
    this.id,
    this.userID,
    required this.titulo,
    required this.cipherText,
    required this.authTag,
    required this.iv,
    required this.usuario,
    required this.tipo,
    this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':         id,
      'userID':     userID,
      'titulo':     titulo,
      'cipherText': cipherText,
      'authTag':    authTag,
      'IV':         iv,
      'usuario':    usuario,
      'tipo':       tipo,
      'url':        url,
    };
  }

  factory Senha.fromMap(Map<String, dynamic> map) {
    return Senha(
      id:         map['id']         as int?,
      userID:     map['userID']     as int?,
      titulo:     map['titulo']     as String,
      cipherText: map['cipherText'] as String,
      authTag:    map['authTag']    as String,
      iv:         map['IV']         as String,
      usuario:    map['usuario']    as String,
      tipo:       map['tipo']       as String,
      url:        map['url']        as String?,
    );
  }
}