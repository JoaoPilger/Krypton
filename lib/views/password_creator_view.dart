import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CriarSenhaView extends StatefulWidget {
  const CriarSenhaView({super.key});

  @override
  State<CriarSenhaView> createState() => _CriarSenhaViewState();
}

class _CriarSenhaViewState extends State<CriarSenhaView> {
  final TextEditingController _usuarioController = TextEditingController(
    text: 'Lucas@gmail.com',
  );

  final TextEditingController _senhaController = TextEditingController(
    text: 'SenhaForte123!',
  );

  final TextEditingController _urlController = TextEditingController(
    text: 'google.com',
  );

  bool _ocultarSenha = true;
  double _progressoSenha = 0.8;
  String _textoForca = 'Forte';
  Color _corForca = const Color(0xFF689F38);

  @override
  void initState() {
    super.initState();

    _avaliarSenha(_senhaController.text);

    _senhaController.addListener(() {
      _avaliarSenha(_senhaController.text);
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _senhaController.text));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Senha copiada!')));
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
        _corForca = const Color(0xFF689F38);
      }
    });
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF333383);
    const colorLabel = Color(0xFF666666);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: colorPrimary, width: 1.5),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: colorPrimary, size: 30),
          onPressed: () {},
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset('lib/images/logo.png', height: 40),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),

                    const Text('Usuário / Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usuarioController,
                      decoration: InputDecoration(
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {},
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text('Senha'),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _senhaController,
                      obscureText: _ocultarSenha,
                      decoration: InputDecoration(
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _ocultarSenha
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorPrimary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _ocultarSenha = !_ocultarSenha;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_all_outlined),
                              onPressed: _copyToClipboard,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _textoForca,
                            style: TextStyle(color: _corForca),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _progressoSenha,
                            valueColor: AlwaysStoppedAnimation(_corForca),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text('Url'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        suffixIcon: const Icon(Icons.open_in_new),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text('IMAGEM DE CAPA'),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9999A5)),
                      ),
                      child: const Center(child: Icon(Icons.add, size: 40)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimary,
                  ),
                  child: const Text(
                    'Criar senha',
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Todos os direitos reservados',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
