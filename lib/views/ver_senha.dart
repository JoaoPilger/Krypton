import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krypton/data/dao/senhaController.dart';
import 'password_generator_view.dart';
import 'editar_senha.dart';
import 'package:krypton/main.dart';

// Tela de exibição detalhada de uma senha cadastrada
class VisualizarSenhaView extends StatefulWidget {
  final int id;
  final String usuario;
  final String senha;
  final String url;
  final String titulo;
  final int favorito;
  final String tipo;
  final String? imagemPath;

  const VisualizarSenhaView({
    super.key,
    required this.id,
    required this.usuario,
    required this.senha,
    required this.url,
    this.titulo = 'Google',
    required this.favorito,
    required this.tipo,
    this.imagemPath,
  });

  @override
  State<VisualizarSenhaView> createState() => _VisualizarSenhaViewState();
}

class _VisualizarSenhaViewState extends State<VisualizarSenhaView> {
  // Controladores somente leitura para exibir as informações nos campos correspondentes
  late final TextEditingController _usuarioController;
  late final TextEditingController _senhaController;
  late final TextEditingController _urlController;
  
  // Controles de visibilidade, favorito e imagem de capa do item
  bool _ocultarSenha = true;
  int _esFavorito = 1;
  String? _imagemPath;

  // Variáveis para indicação visual da força da senha exibida
  double _progressoSenha = 0.3;
  String _textoForca = 'Fraca';
  Color _corForca = Colors.red;

  @override
  void initState() {
    super.initState();
    // Inicializa as informações com os dados passados por parâmetro
    _esFavorito = widget.favorito;
    _imagemPath = widget.imagemPath;
    _usuarioController = TextEditingController(text: widget.usuario);
    _senhaController = TextEditingController(text: widget.senha);
    _urlController = TextEditingController(text: widget.url);

    _avaliarSenha(_senhaController.text);
    // Registra uma função que fica escutando em tempo real e reage a cada alteração no campo de senha
    _senhaController.addListener(() {
      _avaliarSenha(_senhaController.text);
    });

    // Busca o status atualizado de favorito no banco
    // mounted: Propriedade de segurança que avisa se a tela ainda está ativa no app naquele exato segundo
    SenhaController.buscarFavorito(widget.id).then((val) {
      if (mounted) setState(() => _esFavorito = val);
    });
  }

  void _atualizarLista() {}

  // Avalia a força da senha
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
    if (senha.contains(RegExp(r'[!@#$%^&*(),.?":{}<>]'))) pontos += 0.25;

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

  // Abre caixa de diálogo de confirmação antes de excluir a senha
  void _confirmarExclusao() {
    // Exibe uma modal de alerta
    showDialog( // Novo widget
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir esta senha?'),
          actions: [
            TextButton(
              // Fecha a tela/diálogo atual e faz o usuário voltar para a tela anterior
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(true); 
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _copiarParaAreaTransferencia(String texto, String campo) {
    if (texto.isEmpty) return;
    // Envia um texto direto para a área de transferência do celular
    // ClipboardData(): O objeto que envelopa e carrega o texto que você quer enviar para o Clipboard
    Clipboard.setData(ClipboardData(text: texto));
    // Faz brotar aquela pequena barra de aviso rápida na parte de baixo da tela
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$campo copiado com sucesso!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    // Destrói o controlador de texto para evitar desperdício e vazamento de memória
    _usuarioController.dispose();
    _senhaController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nomeImagem = widget.titulo.toLowerCase().replaceAll(' ', '_');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        iconTheme: const IconThemeData(size: 32),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
                          // Exibe a imagem de capa customizada ou o ícone/logo padrão correspondente
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: (_imagemPath != null && File(_imagemPath!).existsSync())
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                  // Estica a imagem para cobrir completamente o espaço do avatar, aceitando cortar bordas
                                  child: Image.file(File(_imagemPath!), fit: BoxFit.cover),
                                  )
                                : Image.asset(
                                    'lib/images/logo_$nomeImagem.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.vpn_key,
                                      color: Color(0xFF3C3489),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text(
                                  'Salvo no Krypton',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Botão de Favorito para alternar o status
                          IconButton(
                            icon: Icon(
                              _esFavorito == 1 ? Icons.star : Icons.star_border,
                              color: _esFavorito == 1 ? Colors.amber : const Color(0xFF666475),     
                            ),
                            onPressed: () async{
                              final novoEstado = _esFavorito == 1 ? 0 : 1;
                              final ok = await SenhaController.favoritar(widget.id, favorito: novoEstado == 1);
                              if (ok) setState(() => _esFavorito = novoEstado);
                            },
                          ),
                          // Botão de Editar para alterar os campos
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF3C3489)),
                            onPressed: () async {
                          final resultado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarSenhaView(
                                    id: widget.id,
                                    titulo: widget.titulo,
                                    usuario: _usuarioController.text,
                                    senha: _senhaController.text,
                                    url: _urlController.text,
                                    tipo: widget.tipo,
                                    imagemPath: _imagemPath,
                                  ),
                                ),
                              );
                              if (resultado == true && mounted) {
                                Navigator.of(context).pop('editado');
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _confirmarExclusao,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox( // Novo Widget
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
                          readOnly: true,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 216, 216, 224),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 20, color: Color(0xFF3C3489)),
                              onPressed: () {
                                _copiarParaAreaTransferencia(_usuarioController.text, 'Usuário/Email');
                              },
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
                          readOnly: true,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 216, 216, 224),
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
                          'URL',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C3489)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 216, 216, 224),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 20, color: Color(0xFF3C3489)),
                              onPressed: () {
                                _copiarParaAreaTransferencia(_urlController.text, 'URL');
                              },
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