import 'dart:io';
import 'package:flutter/material.dart';
import 'views/password_generator_view.dart';
import 'views/password_creator_view.dart';
import 'views/login_view.dart';
import 'views/ver_senha.dart';
import 'views/autofill_view.dart';
import 'views/configuracoes_view.dart';
import 'package:krypton/data/DAO/senhaController.dart';
import 'package:flutter/services.dart';

void main() async {
  // Garante que o Flutter esteja conectado e pronto para falar com o sistema operacional antes de rodar códigos nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Define e trava quais orientações a tela do aplicativo pode ter
  await SystemChrome.setPreferredOrientations([
    // Para a tela ficar na posição vertical padrão (em pé)
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MaterialApp(home: LoginView(), debugShowCheckedModeBanner: false));
}

@pragma('vm:entry-point')
void autofillEntryPoint() async {
  // 1. Captura erros de renderização e lógica que acontecem nesta thread isolada
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('!!! ERRO CRÍTICO NO AUTOFILL: ${details.exception}');
    debugPrint('!!! STACK TRACE: ${details.stack}');
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // O banco é inicializado APÓS autenticação do usuário.
    // O entry point de autofill apenas sobe a UI de autenticação;
    // KeystoreService.loginBIO() e loginPIN() chamam DbService.init()
    // com a chave descriptografada depois que o usuário se autentica.

    runApp(const MaterialApp(
      home: AutofillAuthView(),
      debugShowCheckedModeBanner: false,
    ));
  } catch (e, stack) {
    debugPrint('!!! FALHA NO PROCESSO DE INICIALIZAÇÃO DO AUTOFILL: $e');
    debugPrint('$stack');
  }
}

class Home extends StatefulWidget {
  // Filtro inicial para definir quais senhas serão mostradas ao abrir a tela (padrão é 'Todos')
  final String filtroInicial;
  const Home({super.key, this.filtroInicial = 'Todos'});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ID estático do usuário logado (atualmente simulado como 1)
  int constLogadoUserID = 1;
  // Termo digitado pelo usuário na barra de buscas
  String _termoBusca = '';
  // Filtro atual
  late String _filtroAtivo; 
  // Future que armazena a lista de senhas que está sendo buscada no banco
  late Future<List<Map<String, dynamic>>> _senhasFuture;

  @override
  void initState() {
    super.initState();
    // Define o filtro inicial com base no parâmetro passado pelo construtor do widget
    _filtroAtivo = widget.filtroInicial;
    // Dispara a busca inicial das senhas no banco
    _senhasFuture = SenhaController.buscarTodas(constLogadoUserID);
  }

  /// Recarrega as senhas do banco e atualiza o estado da tela principal.
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
            // Abre o menu lateral (Drawer uns do novos widgets)
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'lib/images/logo.png',
              height: 45,
              // Redimensiona a imagem para que ela caiba inteira no espaço disponível, sem cortar nada
            fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
      drawer: Drawer( // Novo widget
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Cabeçalho do Drawer com o logotipo e botão rápido de geração de senha
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
                        // Botão para ir direto ao Gerador de Senhas
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Fecha o Drawer
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => const PasswordGeneratorView())
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 60, 52, 137),
                              foregroundColor: Colors.white,
                              // Define uma forma geométrica de retângulo com cantos arredondados para o botão
                              shape: RoundedRectangleBorder(
                                // Define um raio para deixar os cantos arredondados de forma simétrica
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
                  // Opção de filtro: Todos os itens
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Todos os itens'),
                    selected: _filtroAtivo == 'Todos',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Todos');
                      Navigator.pop(context); // Fecha o Drawer
                    },
                  ),
                  // Opção de filtro: Apenas Favoritos
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('Favoritos'),
                    selected: _filtroAtivo == 'Favoritos',
                    iconColor: const Color.fromARGB(255, 102, 100, 117),
                    textColor: const Color.fromARGB(255, 102, 100, 117),
                    onTap: () {
                      setState(() => _filtroAtivo = 'Favoritos');
                      Navigator.pop(context); // Fecha o Drawer
                    },
                  ),
                  // Divisor de seção para categorias específicas
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
                  // Categoria: Redes Sociais
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
                  // Categoria: Bancos
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
                  // Categoria: Trabalhos
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
                  // Categoria: Outros
                  ListTile(
                    leading: const Icon(Icons.other_houses),
                    title: const Text('Outros'),
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
            // Item de configurações
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              iconColor: const Color.fromARGB(255, 102, 100, 117),
              textColor: const Color.fromARGB(255, 102, 100, 117),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConfiguracoesView()),
                );
              },
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
                  // Busca para encontrar senhas por título ou usuário
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _termoBusca = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar Senhas',
                      hintStyle: const TextStyle(color: Color(0xFF666475)),
                      prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 60, 52, 137)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 216, 216, 224),
                      // Desenha aquela borda em formato de linha que contorna completamente toda a volta do campo de texto
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        // Define que o elemento não terá nenhuma linha de borda visível
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Componente para lidar de forma reativa com o retorno assíncrono das senhas
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _senhasFuture,
                      builder: (context, snapshot) {
                        // Estado de carregamento dos dados
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        // Caso não haja dados ou a lista esteja vazia no banco
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Nenhuma senha cadastrada.'));
                        }

                        final listaSenhas = snapshot.data!;

                        // Filtra localmente a lista de senhas com base no termo de busca e filtro de categoria ativo
                        final listaFiltrada = listaSenhas.where((item) {
                          final titulo = item['titulo']?.toString().toLowerCase() ?? '';
                          final usuario = item['usuario']?.toString().toLowerCase() ?? '';
                          final busca = _termoBusca.toLowerCase();
                        // Transforma todas as letras de um texto em minúsculas

                        final bateTexto = titulo.contains(busca) || usuario.contains(busca);
                        if (!bateTexto) return false;

                        // Verifica o tipo/categoria ativa
                        if (_filtroAtivo == 'Todos') {
                          return true;
                        } else if (_filtroAtivo == 'Favoritos') {
                          return (item['favorito'] as int? ?? 0) == 1;
                        } else {
                          return item['tipo'] == _filtroAtivo;
                        }
                      }).toList();

                        // Caso a busca ou filtro não retorne resultados
                        if (listaFiltrada.isEmpty) {
                          return const Center(child: Text('Nenhuma senha encontrada.'));
                        }

                        // Constrói a lista scrollable de senhas filtradas
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
                                // Exibe a imagem de capa customizada ou o ícone de chave padrão
                                leading: (imagemPath != null && File(imagemPath).existsSync())
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(imagemPath),
                                          width: 40,
                                          height: 40,
                                          // Aumenta e estica a imagem para preencher todo o espaço disponível, aceitando cortar as bordas
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.vpn_key, color: Color(0xFF333383)),
                                title: Text(
                                  item['titulo'] ?? 'Sem categoria',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(item['usuario'] ?? ''),
                                // Ao clicar em um item, abre a tela de exibição detalhada da senha
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

                                  // Se o item foi deletado ou editado, atualiza a lista exibida
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
                  // Botão para adicionar manualmente uma nova senha
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Navega para a tela de criação
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CriarSenhaView()),
                        );
                        // Atualiza a lista se uma senha foi adicionada
                        if (resultado == true) {
                          _atualizarLista();
                        }
                      },
                      // Atalho para criar um estilo de botão de forma simples
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
          // Cria espaçamentos iguais nos lados verticais ou horizontais
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