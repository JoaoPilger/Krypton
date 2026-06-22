import 'package:flutter/material.dart';
import 'register_view.dart';
import '../data/DAO/authController.dart';
import '../main.dart';

// Tela de Login do Krypton
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controlador para pegar o texto que o usuário digita no campo de senha
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Limpa o controlador quando a tela for fechada
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cor roxa do Krypton
    const Color kryptonPurple = Color(0xFF3F3D8A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo do Krypton
              Image.asset(
                'lib/images/logo.png',
                height: 120,
              ),

              const SizedBox(height: 50),

              // Título da tela
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: kryptonPurple,
                ),
              ),

              const SizedBox(height: 16),

              // Texto explicativo
              const Text(
                'Digite sua senha ou impressão digital para fazer login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kryptonPurple,
                ),
              ),

              const SizedBox(height: 32),

              // Campo para digitar a senha (esconde o texto)
              TextFormField(
                controller: _passwordController,
                obscureText: true, // Esconde o que está sendo digitado
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFDBDBE7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão de Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async{
                    bool authentication = await KeystoreService.loginPIN(_passwordController.text);
                    if (authentication) {
                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                      MaterialPageRoute(builder: (context) => const Home()),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kryptonPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Link para ir para a tela de cadastro
              GestureDetector(
                onTap: () {
                  // Abre a tela de cadastro
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterView()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: kryptonPurple, fontSize: 14),
                    children: [
                      TextSpan(text: 'Não tem uma conta? '),
                      TextSpan(
                        text: 'Cadastre-se',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Ícone de biometria
              const Icon(
                Icons.fingerprint,
                size: 100,
                color: kryptonPurple,
              ),

              const SizedBox(height: 30),

              // Rodapé
              const Text(
                'Todos os direitos reservados',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
