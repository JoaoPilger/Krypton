package com.example.krypton

import android.content.Intent
import android.os.Bundle
import android.service.autofill.Dataset
import android.util.Log
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import android.widget.Toast
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val TAG      = "AutofillActivity"
private const val CHANNEL  = "com.example.krypton/autofill"

/**
 * Activity de autofill do Krypton.
 *
 * Expõe um MethodChannel ao Dart com todos os métodos de preenchimento.
 * Usa KryptonAutofillRequestStore para obter os AutofillIds exatos
 * capturados em KryptonAutofillService.onFillRequest().
 */
class AutofillActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val store = KryptonAutofillRequestStore
        Log.i(TAG, "onCreate — usernameIds=${store.usernameIds.size} passwordIds=${store.passwordIds.size}")
    }

    override fun getDartEntrypointFunctionName(): String = "autofillEntryPoint"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "MethodChannel: ${call.method}")
                when (call.method) {

                    "getAutofillMetadata" -> {
                        val store = KryptonAutofillRequestStore
                        result.success(mapOf(
                            "packageNames" to store.packageNames,
                            "webDomains"   to store.webDomains.map { mapOf("domain" to it) },
                        ))
                    }

                    "fillRequestedAutomatic"   -> result.success(KryptonAutofillRequestStore.isAutomatic)
                    "fillRequestedInteractive" -> result.success(!KryptonAutofillRequestStore.isAutomatic)

                    "resultWithDataset" -> {
                        val username = call.argument<String>("username") ?: ""
                        val password = call.argument<String>("password") ?: ""
                        result.success(applyAutofill(username, password))
                    }

                    "resultWithDatasets" -> {
                        @Suppress("UNCHECKED_CAST")
                        val datasets = call.argument<List<Map<String, String>>>("datasets") ?: emptyList()
                        val first = datasets.firstOrNull()
                        result.success(
                            if (first != null) applyAutofill(
                                first["username"] ?: "",
                                first["password"] ?: "",
                            ) else false
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Constrói um Dataset com os AutofillIds do store e devolve ao Android
     * via setResult(RESULT_OK) para que os campos do app-alvo sejam preenchidos.
     */
    private fun applyAutofill(username: String, password: String): Boolean {
        val store = KryptonAutofillRequestStore

        val uIds = store.usernameIds
        val pIds = store.passwordIds
        Log.i(TAG, "applyAutofill: u=${uIds.size} p=${pIds.size} user='$username' pass=${if (password.isNotEmpty()) "***" else "(empty)"}")

        // Toast de debug — remove em produção
        Toast.makeText(
            this,
            "Krypton autofill: ${uIds.size} user + ${pIds.size} pass IDs",
            Toast.LENGTH_LONG
        ).show()

        if (uIds.isEmpty() && pIds.isEmpty()) {
            Log.w(TAG, "Store vazio — onFillRequest não rodou ou não achou campos")
            Toast.makeText(this, "ERRO: store vazio — selecione Krypton nas config de autofill", Toast.LENGTH_LONG).show()
            return false
        }

        return try {
            val presentation = RemoteViews(packageName, R.layout.autofill_list_item).also {
                it.setTextViewText(R.id.autofill_item_text, "Krypton")
            }

            // Monta o Dataset com os AutofillIds do store
            val datasetBuilder = Dataset.Builder(presentation)
            uIds.forEach { id -> datasetBuilder.setValue(id, AutofillValue.forText(username)) }
            pIds.forEach { id -> datasetBuilder.setValue(id, AutofillValue.forText(password)) }
            val dataset = datasetBuilder.build()

            // IMPORTANTE: como usamos FillResponse.setAuthentication() (auth no nível da
            // resposta), o Android espera receber uma FillResponse de volta — não um Dataset.
            // Devolver apenas um Dataset causa o fill silencioso sem preencher nada.
            val fillResponse = android.service.autofill.FillResponse.Builder()
                .addDataset(dataset)
                .build()

            val replyIntent = Intent().apply {
                putExtra(android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT, fillResponse)
            }

            setResult(RESULT_OK, replyIntent)
            Log.i(TAG, "setResult(RESULT_OK) FillResponse — u=${uIds.size} p=${pIds.size}")
            finish()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao construir dataset/fillResponse", e)
            Toast.makeText(this, "ERRO: ${e.message}", Toast.LENGTH_LONG).show()
            false
        }
    }
}
