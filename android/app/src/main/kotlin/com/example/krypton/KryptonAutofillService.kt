package com.example.krypton

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.Intent
import android.os.Build
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveRequest
import android.text.InputType
import android.util.Log
import android.view.View
import android.view.autofill.AutofillId
import android.widget.RemoteViews

private const val TAG = "KryptonAutofillSvc"

class KryptonAutofillService : AutofillService() {

    // ── Hints de senha (inclui variantes HTML5) ──────────────────────────────
    private val passwordHints = setOf(
        View.AUTOFILL_HINT_PASSWORD,        // "password"
        "password",
        "currentPassword", "current-password",
        "newPassword",     "new-password",
        "senha", "pass", "passwd",
    )

    // ── Hints de usuário / e-mail ────────────────────────────────────────────
    private val usernameHints = setOf(
        View.AUTOFILL_HINT_USERNAME,        // "username"
        View.AUTOFILL_HINT_EMAIL_ADDRESS,   // "emailAddress"
        "username", "user", "login",
        "email", "emailAddress", "email-address",
        "phone", "tel", "telephone",
        "usernameOrEmail",
    )

    // ── InputType masks de senha ─────────────────────────────────────────────
    private val passwordInputTypeMasks = listOf(
        InputType.TYPE_TEXT_VARIATION_PASSWORD,
        InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD,
        InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD,
    )

    // ────────────────────────────────────────────────────────────────────────

    override fun onFillRequest(
        request: FillRequest,
        signal: CancellationSignal,
        callback: FillCallback,
    ) {
        Log.i(TAG, "onFillRequest")

        val context = request.fillContexts.lastOrNull() ?: run {
            callback.onSuccess(null); return
        }

        val structure = context.structure

        // ── 1. Parseia ───────────────────────────────────────────────────────
        val usernameIds  = mutableListOf<AutofillId>()
        val passwordIds  = mutableListOf<AutofillId>()
        val unknownIds   = mutableListOf<AutofillId>() // texto sem hint reconhecido
        val packageNames = mutableListOf<String>()
        val webDomains   = mutableListOf<String>()

        for (i in 0 until structure.windowNodeCount) {
            val winTitle = structure.getWindowNodeAt(i).title?.toString() ?: ""
            // título da janela costuma ser "package/activity"
            winTitle.split("/").firstOrNull()
                ?.takeIf { it.contains('.') }
                ?.let { packageNames.add(it) }

            parseNode(
                structure.getWindowNodeAt(i).rootViewNode,
                usernameIds, passwordIds, unknownIds,
            )
        }

        collectWebDomains(structure, webDomains)

        Log.i(TAG, "Parsed: u=${usernameIds.size} p=${passwordIds.size} unknown=${unknownIds.size} pkg=$packageNames web=$webDomains")

        // ── 2. Fallback: se não achou campos com hint, usa campos desconhecidos
        //    Heurística: se há ≥2 campos desconhecidos → último = senha, outros = usuário.
        //    Se há 1 → trata como senha (ex: apps com login em 2 etapas).
        if (usernameIds.isEmpty() && passwordIds.isEmpty()) {
            when (unknownIds.size) {
                0    -> { Log.i(TAG, "Nenhum campo encontrado"); callback.onSuccess(null); return }
                1    -> passwordIds.addAll(unknownIds)
                else -> {
                    passwordIds.add(unknownIds.last())
                    usernameIds.addAll(unknownIds.dropLast(1))
                }
            }
            Log.i(TAG, "Fallback heurístico: u=${usernameIds.size} p=${passwordIds.size}")
        }

        // ── 3. Salva no store ────────────────────────────────────────────────
        KryptonAutofillRequestStore.apply {
            this.usernameIds  = usernameIds
            this.passwordIds  = passwordIds
            this.packageNames = packageNames
            this.webDomains   = webDomains
            this.isAutomatic  = true
        }

        // ── 4. PendingIntent ─────────────────────────────────────────────────
        val intent = Intent(this, AutofillActivity::class.java)

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_MUTABLE
        else
            @SuppressLint("UnspecifiedImmutableFlag") PendingIntent.FLAG_CANCEL_CURRENT

        val pendingIntent = PendingIntent.getActivity(this, REQUEST_CODE, intent, flags)

        // ── 5. Apresentação visual da sugestão ───────────────────────────────
        val presentation = RemoteViews(packageName, R.layout.autofill_list_item).also {
            it.setTextViewText(R.id.autofill_item_text, "Desbloquear com Krypton")
        }

        // ── 6. FillResponse ──────────────────────────────────────────────────
        val allIds = (usernameIds + passwordIds).distinct().toTypedArray()

        try {
            val fillResponse = FillResponse.Builder()
                .setAuthentication(allIds, pendingIntent.intentSender, presentation)
                .build()
            Log.i(TAG, "FillResponse ok — ${allIds.size} ids")
            callback.onSuccess(fillResponse)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao montar FillResponse", e)
            callback.onSuccess(null)
        }
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        callback.onSuccess()
    }

    // ────────────────────────────────────────────────────────────────────────

    private fun parseNode(
        node: AssistStructure.ViewNode,
        usernameIds: MutableList<AutofillId>,
        passwordIds: MutableList<AutofillId>,
        unknownIds:  MutableList<AutofillId>,
    ) {
        val autofillType = node.autofillType
        val autofillId   = node.autofillId

        if (autofillType == View.AUTOFILL_TYPE_TEXT && autofillId != null) {
            val hints = node.autofillHints
                ?.map { it.trim().lowercase() }
                ?: emptyList()

            val rawType = node.inputType

            val isPassword = hints.any { h -> passwordHints.any { it.lowercase() == h } } ||
                    passwordInputTypeMasks.any { mask ->
                        (rawType and InputType.TYPE_MASK_VARIATION) == mask
                    }

            val isUsername = hints.any { h -> usernameHints.any { it.lowercase() == h } }

            when {
                isPassword -> passwordIds.add(autofillId)
                isUsername -> usernameIds.add(autofillId)
                else       -> unknownIds.add(autofillId)  // campo de texto sem classificação
            }
        }

        for (i in 0 until node.childCount) {
            parseNode(node.getChildAt(i), usernameIds, passwordIds, unknownIds)
        }
    }

    private fun collectWebDomains(structure: AssistStructure, domains: MutableList<String>) {
        fun scan(node: AssistStructure.ViewNode) {
            node.webDomain?.takeIf { it.isNotBlank() }?.let { domains.add(it) }
            for (i in 0 until node.childCount) scan(node.getChildAt(i))
        }
        for (i in 0 until structure.windowNodeCount) scan(structure.getWindowNodeAt(i).rootViewNode)
    }

    companion object {
        const val REQUEST_CODE = 9876
    }
}
