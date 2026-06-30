class SenhaModel {
  int? id;
  int? userID;
  String titulo;
  String cipherText;
  String authTag;
  String iv;
  String usuario;
  String tipo;
  String? url;
  bool favorito;
  String? imagemPath;

  SenhaModel({
    this.id,
    this.userID,
    required this.titulo,
    required this.cipherText,
    required this.authTag,
    required this.iv,
    required this.usuario,
    required this.tipo,
    this.url,
    required this.favorito,
    this.imagemPath,
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
      'favorito':   favorito ? 1 : 0,
      'imagemPath': imagemPath,
    };
  }

  factory SenhaModel.fromMap(Map<String, dynamic> map) {
    return SenhaModel(
      id:         map['id']         as int?,
      userID:     map['userID']     as int?,
      titulo:     map['titulo']     as String,
      cipherText: map['cipherText'] as String,
      authTag:    map['authTag']    as String,
      iv:         map['IV']         as String,
      usuario:    map['usuario']    as String,
      tipo:       map['tipo']       as String,
      url:        map['url']        as String?,
      favorito:   (map['favorito']  as int? ?? 0) != 0,
      imagemPath: map['imagemPath'] as String?,
    );
  }
}