import 'dart:io';
import 'package:flutter/material.dart';
import 'views/password_generator_view.dart';
import 'views/password_creator_view.dart';
import 'views/login_view.dart';
import 'views/ver_senha.dart';
import 'package:krypton/data/dao/senhaController.dart';
import 'package:flutter/services.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MaterialApp(home: LoginView(), debugShowCheckedModeBanner: false));
}

class Home extends StatefulWidget {

  final String filtroInicial;
  const Home({super.key, this.filtroInicial = 'Todos'});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int constLogadoUserID = 1;
  String _termoBusca = '';
  late String _filtroAtivo; 
  late Future<List<Map<String, dynamic>>> _senhasFuture;

  @override
  void initState() {
    super.initState();
    _filtroAtivo = widget.filtroInicial;
    _senhasFuture = SenhaController.buscarTodas(constLogadoUserID);
  }

  void _atualizarLista() {
    setState(() {
      _senhasFuture = SenhaController.buscarTodas(constLogadoUserID);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
                    selected: _filtroAtivo == 'Todos',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Todos');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('Favoritos'),
                    selected: _filtroAtivo == 'Favoritos',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Favoritos');
                      Navigator.pop(context);
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
                    selected: _filtroAtivo == 'Redes Sociais',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Redes Sociais');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: const Text('Bancos'),
                    selected: _filtroAtivo == 'Bancos',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Bancos');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.work),
                    title: const Text('Trabalhos'),
                    selected: _filtroAtivo == 'Trabalhos',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Trabalhos');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.other_houses),
                    title: const Text ('Outros'),
                    selected: _filtroAtivo == 'Outros',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Outros');
                      Navigator.pop(context);
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _termoBusca = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar Senhas',
                      hintStyle: const TextStyle(color: Color(0xFF666475)),
                      prefixIcon: const Icon(Icons.search, color: Color.fromARGB( 255, 60, 52, 137)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 216, 216, 224),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _senhasFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Nenhuma senha cadastrada.'));
                        }

                        final listaSenhas = snapshot.data!;

                        final listaFiltrada = listaSenhas.where((item) {
                          final titulo = item['titulo']?.toString().toLowerCase() ?? '';
                          final usuario = item['usuario']?.toString().toLowerCase() ?? '';
                          final busca = _termoBusca.toLowerCase();
                          final bateTexto = titulo.contains(busca) || usuario.contains(busca);
                          if (!bateTexto) return false;

                          if (_filtroAtivo == 'Todos') {
                            return true;
                          } else if (_filtroAtivo == 'Favoritos') {
                            return (item['favorito'] as int? ?? 0) == 1;
                          } else {
                            return item['tipo'] == _filtroAtivo;
                          }
                        }).toList();

                        if (listaFiltrada.isEmpty) {
                          return const Center(child: Text('Nenhum resultado encontrado.'));
                        }

                        return ListView.builder(
                          itemCount: listaFiltrada.length,
                          itemBuilder: (context, index) {
                            final item = listaFiltrada[index];
                            final imagemPath = item['imagemPath'] as String?;
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: const Color.fromARGB(255, 240, 240, 245),
                              child: ListTile(
                                leading: (imagemPath != null && File(imagemPath).existsSync())
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(imagemPath),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.vpn_key, color: Color(0xFF333383)),
                                title: Text(
                                  item['titulo'] ?? 'Sem categoria',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(item['usuario'] ?? ''),
                                onTap: () async {
                                  final deletar = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VisualizarSenhaView(
                                        id: item['id'],
                                        titulo: item['titulo'] ?? 'Sem categoria',
                                        usuario: item['usuario'] ?? '',
                                        senha: item['senha'] ?? '',
                                        url: item['url'] ?? '',
                                        favorito: item['favorito'] ?? 0,
                                        tipo: item['tipo'] ?? 'Outros', 
                                        imagemPath: imagemPath,
                                      ),
                                    ),
                                  );

                                  if (deletar == true) {
                                    await SenhaController.deletar(item['id']); 
                                    _atualizarLista();
                                  } else if (deletar == 'editado') {
                                    _atualizarLista();
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CriarSenhaView()),
                        );
                        if (resultado == true) {
                          _atualizarLista();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 60, 52, 137),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Nova senha',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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
    );
  }
}