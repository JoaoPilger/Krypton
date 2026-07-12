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
  // TextEditingController - controla  e lê o que foi digitado no campo
  final _passwordController = TextEditingController();
  // Variável para indicar se o login está carregando
  bool _isLoading = false;

  @override
  void dispose() {
    // Limpa o controlador quando a tela for fechada
    // .dispose() - libera o controlador da memória ao fechar a tela
    _passwordController.dispose();
    super.dispose();
  }

  // Redireciona o usuário para a tela Home principal
  void _goHome() {
    // pushReplacement - vai pra Home e fecha a tela de login (usuário não volta pra cá)
    Navigator.pushReplacement(
      context,
      // MaterialPageRoute - define a animação de transição entre telas
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  // Efetua login usando a senha digitada no campo (PIN)
  Future<void> _loginPIN() async {
    if (_passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
 
    // Verifica a senha através do serviço KeystoreService
    final bool ok = await KeystoreService.loginPIN(_passwordController.text);
 
    setState(() => _isLoading = false);
 
    if (!mounted) return;
 
    if (ok) {
      _goHome(); // Se a senha estiver correta, vai para a Home
    } else {
      // showSnackBar - mostra a barrinha de erro na parte de baixo da tela
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha incorreta. Tente novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Efetua login usando biometria cadastrada no dispositivo
  Future<void> _loginBIO() async {
    setState(() => _isLoading = true);
 
    // Verifica a biometria através do serviço KeystoreService
    final bool ok = await KeystoreService.loginBIO();
 
    setState(() => _isLoading = false);
 
    if (!mounted) return;
 
    if (ok) {
      _goHome(); // Se a autenticação biométrica funcionar, vai para a Home
    } else {
      // showSnackBar - mostra a barrinha de aviso de falha biométrica
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticação biométrica falhou. Use sua senha.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cor roxa principal do aplicativo Krypton
    const Color kryptonPurple = Color(0xFF3F3D8A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Permite rolagem da tela se o teclado abrir
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Exibe o logo do aplicativo
              Image.asset(
                'lib/images/logo.png',
                height: 120,
              ),

              const SizedBox(height: 50),

              // Título de Login
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: kryptonPurple,
                ),
              ),

              const SizedBox(height: 16),

              // Mensagem instrutiva
              const Text(
                'Digite sua senha ou impressão digital para fazer login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kryptonPurple,
                ),
              ),

              const SizedBox(height: 32),

              // Campo de entrada para digitar a senha
              TextFormField(
                controller: _passwordController,
                obscureText: true, // Oculta o texto digitado
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFDBDBE7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  // OutlineInputBorder - borda ao redor do campo de texto
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    // BorderSide.none - remove a linha de borda visível
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão para executar o login por PIN/Senha
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async{
                    _loginPIN();
                  },
                  // FilledButton.styleFrom - estiliza o botão preenchido
                  style: FilledButton.styleFrom(
                    backgroundColor: kryptonPurple,
                    // RoundedRectangleBorder - bordas arredondadas
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

              // Abre a tela de cadastro ao clicar no link
              GestureDetector(
                onTap: () {
                  // Navigator.push - abre a tela de cadastro por cima
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterView()),
                  );
                },
                child: RichText(
                  // TextSpan - permite estilizar trechos diferentes dentro do mesmo texto
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

              // Área clicável para login por biometria (impressão digital)
              GestureDetector(
                onTap: _isLoading ? null : _loginBIO,
                child: Column(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 100,
                      color: _isLoading
                          ? kryptonPurple.withValues()
                          : kryptonPurple,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrar com biometria',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isLoading
                            ? kryptonPurple.withValues()
                            : kryptonPurple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Rodapé simples de direitos autorais
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
