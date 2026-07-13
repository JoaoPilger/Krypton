import 'package:flutter/material.dart';
import '../services/autofill_bridge.dart';

const Color kryptonPurple = Color(0xFF3F3D8A);

class ConfiguracoesView extends StatefulWidget {
  const ConfiguracoesView({super.key});

  @override
  State<ConfiguracoesView> createState() => _ConfiguracoesViewState();
}

class _ConfiguracoesViewState extends State<ConfiguracoesView> {
  bool? _autofillAtivo; // null = ainda não verificado

  @override
  void initState() {
    super.initState();
    _verificarStatusAutofill();
  }

  Future<void> _verificarStatusAutofill() async {
    final enabled = await KryptonAutofillBridge.hasEnabledAutofillServices();
    if (!mounted) return;
    setState(() {
      _autofillAtivo = enabled;
    });
  }

  Future<void> _solicitarAutofill() async {
    // Abre a tela nativa do Android onde o usuário escolhe o Krypton
    // como serviço de autofill do sistema. Não dá pra ativar isso
    // programaticamente sem a confirmação do usuário — é o Android
    // que exige essa etapa manual por segurança.
    await KryptonAutofillBridge.requestSetAutofillService();

    // Ao voltar pro app, reconsulta o status real (o usuário pode ter
    // cancelado a solicitação).
    await _verificarStatusAutofill();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        title: const Text('Configurações'),
        foregroundColor: kryptonPurple,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.auto_fix_high, color: kryptonPurple),
            title: const Text('Autopreenchimento'),
            subtitle: Text(
              _autofillAtivo == null
                  ? 'Verificando...'
                  : _autofillAtivo!
                      ? 'Ativado — o Krypton pode preencher senhas em outros apps'
                      : 'Desativado',
            ),
            trailing: _autofillAtivo == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
            onTap: _autofillAtivo == true ? null : _solicitarAutofill,
          ),
          const Divider(),
        ],
      ),
    );
  }
}