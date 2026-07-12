import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krypton/data/dao/senhaController.dart';
import 'password_generator_view.dart';
import 'package:krypton/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CriarSenhaView extends StatefulWidget {
  final String? senhaInicial;
  const CriarSenhaView({super.key, this.senhaInicial});

  @override
  State<CriarSenhaView> createState() => _CriarSenhaViewState();
}

class _CriarSenhaViewState extends State<CriarSenhaView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _categoriaSelecionada = 'Redes Sociais';
  final List<String> categorias = ['Redes Sociais', 'Bancos', 'Trabalhos', 'Outros'];

  final TextEditingController _tituloController = TextEditingController(text: '');
  final TextEditingController _usuarioController = TextEditingController(text: '');
  final TextEditingController _senhaController = TextEditingController(text: '');
  final TextEditingController _urlController = TextEditingController(text: '');

  bool _ocultarSenha = true;
  double _progressoSenha = 0.0;
  String _textoForca = 'Vazia';
  Color _corForca = Colors.grey;

  File? _imagemCapa;
  int constLogadoUserID = 1;

  @override
  void initState() {
    super.initState();
    if (widget.senhaInicial != null) {
      _senhaController.text = widget.senhaInicial!;
    }
    _avaliarSenha(_senhaController.text);
    _senhaController.addListener(() {
      _avaliarSenha(_senhaController.text);
    });
  }

  void _copiarParaAreaTransferencia(String texto, String campo) {
    if (texto.isEmpty) return;
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$campo copiado com sucesso!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final nomeArquivo = 'capa_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final novoArquivo = await File(picked.path).copy(p.join(dir.path, nomeArquivo));

    setState(() {
      _imagemCapa = novoArquivo;
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
        _corForca = const Color(0xFF689F38);
      }
    });
  }

  Future<void> _submeterSalvar() async {
    if (_tituloController.text.trim().isEmpty || _usuarioController.text.trim().isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o Título, Usuário e a Senha.')),
      );
      return;
    }

    const storage = FlutterSecureStorage();
    final chaveExiste = await storage.read(key: 'db_key');
    if (chaveExiste == null) {
      final chaveMockada = base64Encode(List<int>.generate(32, (i) => i));
      await storage.write(key: 'db_key', value: chaveMockada);
    }

    bool sucesso = await SenhaController.salvar(
      userID: constLogadoUserID,
      titulo: _tituloController.text.trim(),
      usuario: _usuarioController.text.trim(),
      senhaPlain: _senhaController.text,
      tipo: _categoriaSelecionada,
      url: _urlController.text.trim(),
      imagemPath: _imagemCapa?.path,
    );

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha salva com segurança!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar no banco. Verifique seus dados.')),
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF333383);
    const colorBackgroundBox = Color.fromARGB(255, 216, 216, 224);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        elevation: 0,
        iconTheme: const IconThemeData(size: 32),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'lib/images/logo.png',
              height: 45,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        child: Column(
          children: [
            Expanded( // Novo Widget
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
                                MaterialPageRoute(builder: (context) => const PasswordGeneratorView()),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),
                    ConstrainedBox( // Novo Widget
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Título',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tituloController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorBackgroundBox,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Usuário / Email',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usuarioController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorBackgroundBox,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: SizedBox(
                                width: 40,
                                child: IconButton(
                                  icon: const Icon(Icons.copy, size: 20, color: colorPrimary),
                                  onPressed: () {
                                    _copiarParaAreaTransferencia(_usuarioController.text, 'Usuário/Email');
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Senha',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: _ocultarSenha,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorBackgroundBox,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                    onPressed: () {
                                      _copiarParaAreaTransferencia(_senhaController.text, 'Senha');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _textoForca,
                                style: TextStyle(fontSize: 12, color: _corForca, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator( // Novo Widget
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
                            'Categoria',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _categoriaSelecionada,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorBackgroundBox,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: categorias.map((String cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (String? novaCat) {
                              if (novaCat != null) {
                                setState(() {
                                  _categoriaSelecionada = novaCat;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'URL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _urlController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorBackgroundBox,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: const Icon(Icons.open_in_new, color: colorPrimary),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'IMAGEM DE CAPA',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector( // Novo Widget
                            onTap: _selecionarImagem,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E0E6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF9999A5)),
                              ),
                              child: _imagemCapa != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.file(
                                        _imagemCapa!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.add, size: 40, color: colorPrimary),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submeterSalvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Criar senha',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Todos os direitos reservados',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}