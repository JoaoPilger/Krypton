class User {
  int?   id;
  String nome;
  String email;

  User({
    this.id,
    required this.nome,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':    id,
      'nome':  nome,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id:    map['id']    as int?,
      nome:  map['nome']  as String,
      email: map['email'] as String,
    );
  }
}