class User {
  int?   id;
  String nome;

  User({
    this.id,
    required this.nome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':    id,
      'nome':  nome,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id:    map['id']    as int?,
      nome:  map['nome']  as String,
    );
  }
}