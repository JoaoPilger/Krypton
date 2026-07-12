import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krypton/main.dart';
import 'password_creator_view.dart';


class PasswordGeneratorView extends StatefulWidget {
  const PasswordGeneratorView({super.key});

  @override
  State<PasswordGeneratorView> createState() => _PasswordGeneratorViewState();
}

class _PasswordGeneratorViewState extends State<PasswordGeneratorView> {
  bool _includeNumbers = false;
  bool _includeUppercase = false;
  bool _includeLowercase = false;
  bool _includeSpecial = false;
  double _passwordLength = 16;
  String _generatedPassword = "";

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _atualizarLista() {}

  void _generatePassword() {
    const String numbers = "0123456789";
    const String uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const String lowercase = "abcdefghijklmnopqrstuvwxyz";
    const String special = "!@#\$%^&*()_+-=[]{}|;:,.<>?";

    String allowedChars = "";
    if (_includeNumbers) allowedChars += numbers;
    if (_includeUppercase) allowedChars += uppercase;
    if (_includeLowercase) allowedChars += lowercase;
    if (_includeSpecial) allowedChars += special;

    if (allowedChars.isEmpty) {
      setState(() {
        _generatedPassword = "Selecione uma opção";
      });
      return;
    }

    final Random random = Random.secure();
    final length = _passwordLength.round();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(allowedChars[random.nextInt(allowedChars.length)]);
    }

    setState(() {
      _generatedPassword = buffer.toString();
    });
  }

  void _copyToClipboard() {
    if (_generatedPassword.isEmpty || _generatedPassword == "Selecione uma opção") return;

    Clipboard.setData(ClipboardData(text: _generatedPassword)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha copiada'), duration: Duration(seconds: 2)),
        );
      }
    });
  }

  void _salvarSenha() async {
    if (_generatedPassword.isEmpty || _generatedPassword == "Selecione uma opção") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere uma senha válida antes de salvar')),
      );
      return;
    }

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CriarSenhaView(senhaInicial: _generatedPassword),
      ),
    );

    if (resultado == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Todos')),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3C3489);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        elevation: 0,
        iconTheme: const IconThemeData(size: 32),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('lib/images/logo.png', height: 45, fit: BoxFit.contain),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                    color: const Color.fromARGB(255, 216, 216, 224),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Image.asset(
                            'lib/images/logo.png',
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.lock, size: 50),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => const PasswordGeneratorView())
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 60, 52, 137),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Gerar Senha',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Todos os itens'),
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Todos')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('Favoritos'),
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Favoritos')),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Categorias',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 60, 52, 137),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Redes Sociais'),
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Redes Sociais')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: const Text('Bancos'),
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Bancos')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.work),
                    title: const Text('Trabalhos'),
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Trabalhos')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.other_houses),
                    title: const Text('Outros'),
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Home(filtroInicial: 'Outros')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Color.fromARGB(40, 0, 0, 0), height: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              iconColor: const Color.fromARGB(255, 102, 100, 117),
              textColor: const Color.fromARGB(255, 102, 100, 117),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: 'Itim', fontSize: 16, color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Gerador de senhas',
                    style: const TextStyle(
                      fontFamily: 'Itim',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3489),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Text('Incluir números', style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _includeNumbers,
                        activeThumbColor: Colors.white,
                        activeTrackColor: primaryColor,
                        onChanged: (val) {
                          setState(() => _includeNumbers = val);
                          _generatePassword();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text('Incluir letra maiúscula', style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _includeUppercase,
                        activeThumbColor: Colors.white,
                        activeTrackColor: primaryColor,
                        onChanged: (val) {
                          setState(() => _includeUppercase = val);
                          _generatePassword();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text('Incluir letra minúscula', style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _includeLowercase,
                        activeThumbColor: Colors.white,
                        activeTrackColor: primaryColor,
                        onChanged: (val) {
                          setState(() => _includeLowercase = val);
                          _generatePassword();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text('Incluir caracteres especiais', style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _includeSpecial,
                        activeThumbColor: Colors.white,
                        activeTrackColor: primaryColor,
                        onChanged: (val) {
                          setState(() => _includeSpecial = val);
                          _generatePassword();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Text('Número de caracteres', style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Text(_passwordLength.round().toString(), style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: const Color(0xFFE0E0E0),
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withOpacity(0.2),
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        value: _passwordLength,
                        min: 6,
                        max: 32,
                        onChanged: (val) {
                          setState(() => _passwordLength = val);
                          _generatePassword();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                                child: Text(
                                _generatedPassword,
                                style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Color(0xFF3C3489), letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              onPressed: _generatePassword,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.copy_all_outlined, color: Colors.grey),
                              onPressed: _copyToClipboard,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _salvarSenha,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Salvar senha',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('Todos os direitos reservados', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}