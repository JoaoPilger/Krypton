package com.example.krypton

import android.view.autofill.AutofillId

/**
 * Singleton que armazena os dados da última requisição de autofill.
 *
 * Populado em KryptonAutofillService.onFillRequest() e lido em
 * AutofillActivity quando o usuário seleciona uma senha.
 *
 * Ao usar os AutofillIds capturados diretamente no onFillRequest,
 * garantimos que o Dataset retornado tem os IDs exatos dos campos
 * que o Android precisa preencher — eliminando o bug de re-parsing
 * da AssistStructure na AutofillActivity.
 */
object KryptonAutofillRequestStore {

    /** IDs dos campos de nome de usuário / e-mail encontrados */
    @Volatile var usernameIds: List<AutofillId> = emptyList()

    /** IDs dos campos de senha encontrados */
    @Volatile var passwordIds: List<AutofillId> = emptyList()

    /** Todos os IDs autofillables (username + password) */
    val allFieldIds: List<AutofillId>
        get() = (usernameIds + passwordIds).distinct()

    /** Nomes de pacote do app que pediu autofill (ex: ["com.instagram.android"]) */
    @Volatile var packageNames: List<String> = emptyList()

    /** Domínios web encontrados na estrutura (ex: ["instagram.com"]) */
    @Volatile var webDomains: List<String> = emptyList()

    /** true = lançado via FillResponse.setAuthentication (/autofill automático) */
    @Volatile var isAutomatic: Boolean = true

    fun clear() {
        usernameIds = emptyList()
        passwordIds = emptyList()
        packageNames = emptyList()
        webDomains   = emptyList()
        isAutomatic  = true
    }
}
