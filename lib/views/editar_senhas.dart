import 'package:flutter/material.dart';

class EditarSenhaView extends StatefulWidget {
  const EditarSenhaView({super.key});

  @override
  State<EditarSenhaView> createState() => _EditarSenhaViewState();
}

class _EditarSenhaViewState extends State<EditarSenhaView> {
  final TextEditingController _usuarioController = TextEditingController(text: 'lucas@gmail.com');
  final TextEditingController _senhaController = TextEditingController(text: '123456');
  final TextEditingController _urlController = TextEditingController(text: 'https://google.com');
  
  bool _ocultarSenha = true;
  bool _esFavorito = false;

  double _progressoSenha = 0.3;
  String _textoForca = 'Fraca';
  Color _corForca = Colors.red;

  @override
  void initState() {
    super.initState();
    _avaliarSenha(_senhaController.text);
    _senhaController.addListener(() {
      _avaliarSenha(_senhaController.text);
    });
  }

  void _avaliarSenha(String senha) {
    if (senha.isEmpty) {
      setState(() {
        _progressoSenha = 0.0;
        _textoForca = 'Vazia';
        _corForca = Colors.grey;
      });
      return;
    }

    double pontos = 0.0;

    if (senha.length >= 6) pontos += 0.25;
    if (senha.length >= 10) pontos += 0.25;
    if (senha.contains(RegExp(r'[A-Z]'))) pontos += 0.25;
    if (senha.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) pontos += 0.25;

    setState(() {
      _progressoSenha = pontos == 0.0 ? 0.2 : pontos;
      
      if (_progressoSenha <= 0.3) {
        _textoForca = 'Fraca';
        _corForca = Colors.red;
      } else if (_progressoSenha <= 0.6) {
        _textoForca = 'Média';
        _corForca = Colors.orange;
      } else {
        _textoForca = 'Forte';
        _corForca = Colors.green;
      }
    });
  }

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        iconTheme: const IconThemeData(
          size: 32,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'lib/images/logo.png',
              height: 45,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: const Color.fromARGB(255, 240, 240, 245),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                              'lib/images/logo_google.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded( // Novo widget
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Google',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Atualizado em 3 dias',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: Icon(
                                _esFavorito ? Icons.star : Icons.star_border,
                                color: _esFavorito ? Colors.amber : const Color(0xFF666475),
                              ),
                              onPressed: () {
                                setState(() {
                                  _esFavorito = !_esFavorito;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF666475)),
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox( // Novo widget
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usuário / Email',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C3489)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usuarioController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 216, 216, 224),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: SizedBox(
                              width: 40,
                              child: IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Color(0xFF3C3489)),
                                onPressed: () {},
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Senha',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C3489)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _ocultarSenha,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 216, 216, 224),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _ocultarSenha ? Icons.visibility : Icons.visibility_off,
                                      size: 20,
                                      color: const Color(0xFF666475),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _ocultarSenha = !_ocultarSenha;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20, color: Color(0xFF3C3489)),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row( // Novo widget
                          children: [
                            Text(
                              _textoForca,
                              style: TextStyle(fontSize: 12, color: _corForca, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded( // Novo widget
                              child: LinearProgressIndicator( // Novo widget
                                value: _progressoSenha,
                                backgroundColor: Colors.grey[300],
                                color: _corForca,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'URL',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C3489)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 216, 216, 224),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 60, 52, 137),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Salvar mudança',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "Todos os direitos reservados",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}