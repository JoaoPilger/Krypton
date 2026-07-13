import 'package:flutter/services.dart';

/// Bridge Dart para o serviço de autofill nativo do Krypton.
///
/// Comunica com o MethodChannel 'com.example.krypton/autofill' exposto:
///   - pela MainActivity  → métodos de configuração do sistema
///   - pela AutofillActivity → métodos de preenchimento
///
/// Substitui completamente o pacote flutter_autofill_service.
class KryptonAutofillBridge {
  static const _channel = MethodChannel('com.example.krypton/autofill');

  // ── Configuração (chamados de ConfiguracoesView / MainActivity) ───────────

  /// Retorna true se o Krypton está definido como serviço de autofill ativo.
  static Future<bool> hasEnabledAutofillServices() async {
    try {
      return await _channel.invokeMethod<bool>('hasEnabledAutofillServices') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre a tela nativa do Android para o usuário escolher o serviço de autofill.
  static Future<void> requestSetAutofillService() async {
    try {
      await _channel.invokeMethod<void>('requestSetAutofillService');
    } catch (_) {}
  }

  // ── Contexto de autofill (chamados de autofill_view / AutofillActivity) ───

  /// Metadados do contexto de autofill atual:
  ///   - 'packageNames': List<String> — pacotes do app alvo
  ///   - 'webDomains':   List<Map>    — [{'domain': '...'}, ...]
  static Future<Map<dynamic, dynamic>?> getAutofillMetadata() async {
    try {
      return await _channel.invokeMapMethod<dynamic, dynamic>('getAutofillMetadata');
    } catch (_) {
      return null;
    }
  }

  /// Retorna true se o fluxo é automático (/autofill via FillResponse.setAuthentication)
  static Future<bool> fillRequestedAutomatic() async {
    try {
      return await _channel.invokeMethod<bool>('fillRequestedAutomatic') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retorna true se o fluxo é interativo (/autofill_select via Dataset.setAuthentication)
  static Future<bool> fillRequestedInteractive() async {
    try {
      return await _channel.invokeMethod<bool>('fillRequestedInteractive') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Preenche com lista de datasets — usa o primeiro.
  /// Usado no fluxo /autofill (FillResponse.setAuthentication).
  ///
  /// [datasets] — lista de mapas com 'label', 'username', 'password'
  static Future<bool> resultWithDatasets(List<Map<String, String>> datasets) async {
    try {
      return await _channel.invokeMethod<bool>(
            'resultWithDatasets',
            {'datasets': datasets},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Preenche com um único dataset.
  /// Usado no fluxo /autofill_select (Dataset.setAuthentication).
  static Future<bool> resultWithDataset({
    required String label,
    required String username,
    required String password,
  }) async {
    try {
      return await _channel.invokeMethod<bool>(
            'resultWithDataset',
            {'label': label, 'username': username, 'password': password},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
