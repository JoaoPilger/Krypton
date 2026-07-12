import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krypton/main.dart';
import 'password_creator_view.dart';

/// Vista responsável pela geração de senhas aleatórias seguras.
/// Permite ao usuário escolher o comprimento da senha e quais tipos de caracteres incluir.
class PasswordGeneratorView extends StatefulWidget {
  const PasswordGeneratorView({super.key});

  @override
  State<PasswordGeneratorView> createState() => _PasswordGeneratorViewState();
}

class _PasswordGeneratorViewState extends State<PasswordGeneratorView> {
  // Variáveis de controle para os switches de inclusão de tipos de caracteres
  bool _includeNumbers = false;
  bool _includeUppercase = false;
  bool _includeLowercase = false;
  bool _includeSpecial = false;
  // Comprimento da senha padrão de 16 caracteres
  double _passwordLength = 16;
  // Senha resultante gerada
  String _generatedPassword = "";

  @override
  void initState() {
    super.initState();
    // Gera uma senha inicial quando a tela é carregada
    _generatePassword();
  }

  void _atualizarLista() {}

  /// Método responsável por gerar uma senha aleatória com base nos critérios selecionados pelo usuário.
  void _generatePassword() {
    // Conjuntos de caracteres disponíveis para cada opção
    const String numbers = "0123456789";
    const String uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const String lowercase = "abcdefghijklmnopqrstuvwxyz";
    const String special = "!@#\$%^&*()_+-=[]{}|;:,.<>?";

    // Constrói a string de caracteres permitidos com base nos switches selecionados
    String allowedChars = "";
    if (_includeNumbers) allowedChars += numbers;
    if (_includeUppercase) allowedChars += uppercase;
    if (_includeLowercase) allowedChars += lowercase;
    if (_includeSpecial) allowedChars += special;

    // Se nenhuma opção estiver marcada, mostra uma mensagem solicitando seleção
    if (allowedChars.isEmpty) {
      setState(() {
        _generatedPassword = "Selecione uma opção";
      });
      return;
    }

    // Random.secure() - gera números aleatórios seguros (ideal pra senhas)
    final Random random = Random.secure();
    // .round() - arredonda o valor decimal do slider para inteiro
    final length = _passwordLength.round();
    // StringBuffer - acumula os caracteres sem desperdiçar memória como string+
    final buffer = StringBuffer();
    
    // Sorteia caracteres a partir da lista permitida até completar o comprimento desejado
    for (int i = 0; i < length; i++) {
      // buffer.write() - adiciona o caractere sorteado no buffer
      // nextInt() - sorteia um índice aleatório dentro da lista de caracteres permitidos
      buffer.write(allowedChars[random.nextInt(allowedChars.length)]);
    }

    // setState() - avisa o Flutter que algo mudou e manda redesenhar a tela
    setState(() {
      // buffer.toString() - converte o buffer acumulado em uma String legivel
      _generatedPassword = buffer.toString();
    });
  }

  /// Copia a senha gerada para a área de transferência do dispositivo.
  void _copyToClipboard() {
    if (_generatedPassword.isEmpty || _generatedPassword == "Selecione uma opção") return;

    // Clipboard.setData + ClipboardData - manda o texto para a área de transferência (ctrl+C)
    Clipboard.setData(ClipboardData(text: _generatedPassword)).then((_) {
      // mounted - verifica se a tela ainda está aberta antes de mexer nela
      if (mounted) {
        // showSnackBar - mostra aquela barrinha de aviso na parte de baixo da tela
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha copiada'), duration: Duration(seconds: 2)),
        );
      }
    });
  }

  /// Leva a senha gerada para a tela de salvamento/criação de registros de senha.
  void _salvarSenha() async {
    if (_generatedPassword.isEmpty || _generatedPassword == "Selecione uma opção") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere uma senha válida antes de salvar')),
      );
      return;
    }

    // Abre a tela de salvar senha, enviando a senha gerada como valor inicial
    // Navigator.push - coloca uma nova tela no topo da pilha, fazendo o usuário avançar para a próxima página
    // MaterialPageRoute - gerencia as animações e transições visuais de troca de tela padrão do sistema operacional
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CriarSenhaView(senhaInicial: _generatedPassword),
      ),
    );

    // Se a senha foi salva com sucesso, redireciona o usuário para a tela Home principal
    if (resultado == true && mounted) {
      // Navigator.pushAndRemoveUntil - Abre a nova tela e limpa todo o histórico de telas anteriores, impedindo o usuário de voltar
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
      // Barra superior da tela
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        elevation: 0,
        // IconThemeData - dita a cor, tamanho e opacidade padrão para os ícones
        iconTheme: const IconThemeData(size: 32),
        actions: [
          Padding(
            // EdgeInsets.only - define espaçamentos apenas nos lados escolhidos
            padding: const EdgeInsets.only(right: 16.0),
            // BoxFit.contain - redimensiona a imagem para caber inteira no espaço disponível
            child: Image.asset('lib/images/logo.png', height: 45, fit: BoxFit.contain),
          ),
        ],
      ),
      // Drawer (menu lateral) de navegação e filtros rápidos
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                // EdgeInsets.zero - define que não haverá nenhum tipo de margem ou espaçamento interno
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    // EdgeInsets.fromLTRB - define espaçamentos personalizados para cada lado
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
                            // ElevatedButton.styleFrom - muda o visual, cores, sombras e tamanhos de botões
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 60, 52, 137),
                              foregroundColor: Colors.white,
                              // RoundedRectangleBorder - Define a forma do botão com cantos arredondados
                              shape: RoundedRectangleBorder(
                                // BorderRadius.circular - Define o raio para arredondar os cantos
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
                      // Navigator.pushReplacement - abre uma nova tela e destrói a tela onde o usuário estava
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
      // Corpo principal
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // EdgeInsets.symmetric - espaçamento igual nos dois lados
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            // DefaultTextStyle.merge - ajusta a cor padrão dos textos abaixo
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

                  // Controle para incluir números na geração
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
                          _generatePassword(); // Regenera a senha com a nova regra
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Controle para incluir letras maiúsculas
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

                  // Controle para incluir letras minúsculas
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

                  // Controle para incluir caracteres especiais
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

                  // Exibição e ajuste do tamanho da senha
                  Row(
                    children: [
                      Text('Número de caracteres', style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                      const Spacer(),
                      Text(_passwordLength.round().toString(), style: const TextStyle(fontFamily: 'Itim', color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Slider para ajustar dinamicamente o tamanho da senha
                  SizedBox(
                    width: double.infinity,
                    child: SliderTheme(
                      // SliderTheme.of(context).copyWith - ajusta a cor do slider
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

                  // Container que exibe a senha gerada com botões rápidos para copiar
                  // ConstrainedBox - define o tamanho máximo que um elemento pode ter
                  ConstrainedBox(
                    // BoxConstraints - define o tamanho máximo que um elemento pode ter
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      // BoxDecoration - define a cor de fundo, bordas e formas decorativas
                      decoration: BoxDecoration(
                        // Border.all - desenha a linha de borda
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
                          // Botão para regenerar a senha atual instantaneamente
                          SizedBox(
                            width: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              onPressed: _generatePassword,
                            ),
                          ),
                          // Botão para copiar a senha para a área de transferência
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

                  // Botão para prosseguir com o salvamento da senha no banco de dados
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _salvarSenha,
                      // ElevatedButton.styleFrom(): Atalho para criar um estilo de botão de forma simples
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        // RoundedRectangleBorder(): Cria bordas arredondadas para formas geométricas
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
                    // EdgeInsets.only(): Espaçamento aplicado apenas no lado inferior
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