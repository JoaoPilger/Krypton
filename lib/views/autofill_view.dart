import 'package:flutter/material.dart';
import '../services/autofill_bridge.dart';
import '../data/DAO/authController.dart';
import '../data/DAO/senhaController.dart';

const Color kryptonPurple = Color(0xFF3F3D8A);

// (o Home usa constLogadoUserID = 1 fixo por enquanto).
const int _userIdFixo = 1;

/// Primeira tela do fluxo de autofill: exige autenticação (PIN ou biometria)
/// antes de mostrar qualquer senha. Nunca reaproveita sessão desbloqueada
/// do app principal — cada chamada de autofill pede autenticação de novo.
class AutofillAuthView extends StatefulWidget {
  const AutofillAuthView({super.key});

  @override
  State<AutofillAuthView> createState() => _AutofillAuthViewState();
}

class _AutofillAuthViewState extends State<AutofillAuthView> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _erro;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _autenticarBIO() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    final ok = await KeystoreService.loginBIO();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _irParaSelecao();
    } else {
      setState(() => _erro = 'Autenticação biométrica falhou. Use sua senha.');
    }
  }

  Future<void> _autenticarPIN() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    final ok = await KeystoreService.loginPIN(_passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _irParaSelecao();
    } else {
      setState(() => _erro = 'Senha incorreta. Tente novamente.');
    }
  }

  void _irParaSelecao() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AutofillPickerView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('lib/images/logo.png', height: 100),
              const SizedBox(height: 32),
              const Text(
                'Desbloquear Krypton',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: kryptonPurple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Autentique-se para preencher a senha',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kryptonPurple),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Senha',
                  filled: true,
                  fillColor: const Color(0xFFDBDBE7),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _autenticarPIN,
                  style: FilledButton.styleFrom(
                    backgroundColor: kryptonPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Desbloquear'),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isLoading ? null : _autenticarBIO,
                child: Column(
                  children: [
                    Icon(Icons.fingerprint,
                        size: 64,
                        color: _isLoading ? Colors.grey : kryptonPurple),
                    const SizedBox(height: 4),
                    const Text('Usar biometria',
                        style: TextStyle(fontSize: 13, color: kryptonPurple)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segunda tela: usuário já autenticado. Mostra as senhas que combinam com
/// o app/site que solicitou o autofill e devolve a escolha pro Android.
class AutofillPickerView extends StatefulWidget {
  const AutofillPickerView({super.key});

  @override
  State<AutofillPickerView> createState() => _AutofillPickerViewState();
}

class _AutofillPickerViewState extends State<AutofillPickerView> {
  late Future<_PickerData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _carregarDados();
  }

  Future<_PickerData> _carregarDados() async {
    final metadata = await KryptonAutofillBridge.getAutofillMetadata();
    final todasSenhas = await SenhaController.buscarTodas(_userIdFixo);

    // Detecta o modo para saber qual método usar ao retornar a senha:
    // /autofill        → fillRequestedAutomatic  → deve retornar FillResponse (resultWithDatasets)
    // /autofill_select → fillRequestedInteractive → deve retornar Dataset     (resultWithDataset)
    final isAutomatic = await KryptonAutofillBridge.fillRequestedAutomatic();
    final isInteractive = await KryptonAutofillBridge.fillRequestedInteractive();
    debugPrint('AUTOFILL MODE: automatic=$isAutomatic, interactive=$isInteractive');

    // Coleta termos de busca: domínios web e nomes de pacotes Android
    final webDomainsFromMeta = (metadata?['webDomains'] as Iterable?)?.map((d) => (d as Map)['domain'] as String).toList() ?? <String>[];
    final packageNamesFromMeta = (metadata?['packageNames'] as Iterable?)?.map((p) => p as String).toList() ?? <String>[];

    final termosBusca = <String>[...webDomainsFromMeta, ...packageNamesFromMeta].map((t) => t.toLowerCase()).toList();

    // Extrai palavras-chave dos packageNames (ex: "com.instagram.android" → "instagram")
    // para cruzar com URLs salvas (ex: "instagram.com").
    final palavrasChave = <String>[
      ...packageNamesFromMeta.map((pkg) {
        final partes = pkg.toLowerCase().split('.');
        const ignorar = {'com', 'org', 'net', 'br', 'co', 'app', 'android', 'ios'};
        final significativas = partes.where((p) => !ignorar.contains(p) && p.length > 2);
        return significativas.isNotEmpty ? significativas.first : null;
      }).whereType<String>(),
    ];

    final todosBusca = [...termosBusca, ...palavrasChave];

    List<Map<String, dynamic>> filtradas;
    if (todosBusca.isEmpty) {
      filtradas = todasSenhas;
    } else {
      filtradas = todasSenhas.where((senha) {
        final url = (senha['url'] as String? ?? '').toLowerCase();
        if (url.isEmpty) return false;
        return todosBusca.any((termo) => url.contains(termo) || termo.contains(url));
      }).toList();

      // Se não achou nada com o filtro, mostra todas para o usuário escolher.
      if (filtradas.isEmpty) filtradas = todasSenhas;
    }

    final isNativeApp = packageNamesFromMeta.isNotEmpty && webDomainsFromMeta.isEmpty;

    return _PickerData(
      filtradas,
      isNativeApp: isNativeApp,
      isAutomatic: isAutomatic,
    );
  }

  Future<void> _selecionar(Map<String, dynamic> senha) async {
    final data = await _dataFuture;
    final label = senha['titulo'] ?? 'Krypton';
    final username = senha['usuario'] ?? '';
    final password = senha['senha'] ?? '';

    bool ok;

    if (data.isAutomatic) {
      // Fluxo /autofill: Android lançou a Activity via FillResponse.setAuthentication()
      // → espera receber de volta um FillResponse (usa resultWithDatasets)
      debugPrint('AUTOFILL: usando resultWithDatasets (fluxo /autofill)');
      ok = await KryptonAutofillBridge.resultWithDatasets([
        {'label': label, 'username': username, 'password': password},
      ]);
    } else {
      // Fluxo /autofill_select: Android lançou via Dataset.setAuthentication()
      // → espera receber de volta um Dataset (usa resultWithDataset)
      debugPrint('AUTOFILL: usando resultWithDataset (fluxo /autofill_select)');
      ok = await KryptonAutofillBridge.resultWithDataset(
        label: label,
        username: username,
        password: password,
      );
    }

    debugPrint('AUTOFILL RESULT: $ok');

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível preencher este campo automaticamente.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        title: const Text('Escolha uma senha'),
        foregroundColor: kryptonPurple,
      ),
      body: FutureBuilder<_PickerData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final senhas = snapshot.data!.senhas;
          if (senhas.isEmpty) {
            return const Center(child: Text('Nenhuma senha cadastrada.'));
          }

          return ListView.builder(
            itemCount: senhas.length,
            itemBuilder: (context, index) {
              final senha = senhas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color.fromARGB(255, 240, 240, 245),
                child: ListTile(
                  leading: const Icon(Icons.vpn_key, color: kryptonPurple),
                  title: Text(senha['titulo'] ?? 'Sem título',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(senha['usuario'] ?? ''),
                  onTap: () => _selecionar(senha),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PickerData {
  final List<Map<String, dynamic>> senhas;

  /// true quando o pedido vem de um app nativo (não de um navegador)
  final bool isNativeApp;

  /// true quando o modo é /autofill (fluxo automático → deve retornar FillResponse)
  final bool isAutomatic;

  _PickerData(
    this.senhas, {
    this.isNativeApp = false,
    this.isAutomatic = false,
  });
}
