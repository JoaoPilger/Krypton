import 'package:flutter/material.dart';
import '../data/DAO/userContoller.dart';
import '../main.dart';

// Tela de Cadastro de Usuário (Registro) no Krypton
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controladores de texto para capturar os dados informados no cadastro
  final _nameController            = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variável para armazenar se os termos e condições foram aceitos pelo usuário
  bool _acceptedTerms = false;
  bool _carregando    = false; // bloqueia duplo clique

  @override
  void dispose() {
    // Libera os controladores de texto da memória
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Tenta efetuar o cadastro do usuário com o nome e a senha informados
  Future<void> _cadastrar() async {
    if (_carregando) return;
    setState(() => _carregando = true);

    try {
      // Chama o controlador para salvar o novo usuário mestre no banco
      final ok = await UserController.cadastrar(
        nome:         _nameController.text,
        senhaMestre:  _passwordController.text,
      );

      if (!context.mounted) return;

      if (ok) {
        // Redireciona o usuário para a Home caso o cadastro seja bem-sucedido
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } else {
        // Exibe mensagem em caso de falha de gravação ou banco
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cadastrar. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kryptonPurple = Color(0xFF3F3D8A);

    // Botão ativo só se aceitou termos e não está carregando
    final bool botaoAtivo = _acceptedTerms && !_carregando;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Novo Widget
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset('lib/images/logo.png', height: 120),
              const SizedBox(height: 50),
              const Text(
                'Registro',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: kryptonPurple),
              ),
              const SizedBox(height: 16),
              const Text(
                'Insira seus dados para se cadastrar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: kryptonPurple),
              ),
              const SizedBox(height: 32),
              // Campo para o nome do usuário
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nome',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFDBDBE7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              // Campo para digitar a senha
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFDBDBE7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              // Campo de confirmação de senha
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirme a Senha',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFDBDBE7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              // Opção de Checkbox para concordar com os termos de uso do app
              CheckboxListTile( // Novo Widget
                value: _acceptedTerms,
                onChanged: _carregando
                    ? null
                    : (bool? value) => setState(() => _acceptedTerms = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: kryptonPurple,
                title: const Text(
                  'Concordo com os termos e condições.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 24),
              // Botão para submeter o formulário de cadastro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: botaoAtivo ? _cadastrar : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: kryptonPurple,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Link para navegar de volta ao Login
              GestureDetector( // Novo Widget
                onTap: _carregando ? null : () => Navigator.pop(context),
                child: RichText( // Novo Widget
                  text: const TextSpan(
                    style: TextStyle(color: kryptonPurple, fontSize: 14),
                    children: [
                      TextSpan(text: 'Já tem uma conta? '),
                      TextSpan(text: 'Faça login', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Todos os direitos reservados',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}