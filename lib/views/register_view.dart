import 'package:flutter/material.dart';
import '../data/DAO/userContoller.dart';
import '../main.dart';

// Tela de Cadastro do Krypton
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controladores para pegar o texto que o usuário digita nos campos
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Variável para controlar se o usuário aceitou os termos
  bool _acceptedTerms = false;

  @override
  void dispose() {
    // Limpa os controladores quando a tela for fechada
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                'Registro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: kryptonPurple,
                ),
              ),

              const SizedBox(height: 16),

              // Texto explicativo
              const Text(
                'Insira seus dados para se cadastrar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kryptonPurple,
                ),
              ),

              const SizedBox(height: 32),

              // Campo para digitar o nome
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nome',
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

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              // Campo para confirmar a senha
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true, // Esconde o que está sendo digitado
                decoration: InputDecoration(
                  hintText: 'Confirme a Senha',
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

              const SizedBox(height: 24),

              // Caixa de marcação para aceitar os termos
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (bool? value) {
                  // Atualiza o estado quando o usuário marca/desmarca
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: kryptonPurple,
                title: const Text(
                  'Concordo com os termos e condições.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão de cadastrar (só funciona se aceitar os termos)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  // Se _acceptedTerms é true, o botão funciona. Se false, fica desabilitado
                  onPressed: _acceptedTerms
                      ? () async{
                          bool authentication = await UserController.cadastrar(nome: _nameController.text, senhaMestre: _passwordController.text);
                          if (authentication) {
                            if (!context.mounted) return;
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const Home())
                            );
                          }
                        }
                      : null, // null desabilita o botão
                  style: FilledButton.styleFrom(
                    backgroundColor: kryptonPurple,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Link para voltar ao login
              GestureDetector(
                onTap: () {
                  // Volta para a tela anterior (login)
                  Navigator.pop(context);
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: kryptonPurple, fontSize: 14),
                    children: [
                      TextSpan(text: 'Já tem uma conta? '),
                      TextSpan(
                        text: 'Faça login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

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
