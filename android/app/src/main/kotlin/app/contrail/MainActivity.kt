package app.contrail

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.OutputStreamWriter
import java.nio.charset.StandardCharsets

class MainActivity : FlutterActivity() {
    private val LOGGING_CHANNEL = "app.contrail/logging"
    private val SAF_CHANNEL = "app.contrail/saf"
    private val OPEN_DOCUMENT_TREE_READ_WRITE_REQUEST = 11027
    private var pendingSafResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOGGING_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "log") {
                val level = call.argument<String>("level")
                val tag = call.argument<String>("tag") ?: "Contrail"
                val message = call.argument<String>("message") ?: ""
                
                when (level) {
                    "verbose" -> Log.v(tag, message)
                    "debug" -> Log.d(tag, message)
                    "info" -> Log.i(tag, message)
                    "warning" -> Log.w(tag, message)
                    "error" -> Log.e(tag, message)
                    "fatal" -> Log.wtf(tag, message)
                    else -> Log.i(tag, message)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDocumentTreeReadWrite" -> openDocumentTreeReadWrite(result)
                "listJsonFiles" -> {
                    val treeUriString = call.argument<String>("treeUri")
                    if (treeUriString.isNullOrBlank()) {
                        result.error("invalid_args", "treeUri 不能为空", null)
                    } else {
                        result.success(listJsonFiles(treeUriString))
                    }
                }
                "readTextFile" -> {
                    val fileUri = call.argument<String>("fileUri")
                    if (fileUri.isNullOrBlank()) {
                        result.error("invalid_args", "fileUri 不能为空", null)
                    } else {
                        result.success(readTextFile(fileUri))
                    }
                }
                "writeJsonFile" -> {
                    val treeUriString = call.argument<String>("treeUri")
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")
                    if (treeUriString.isNullOrBlank() || fileName.isNullOrBlank() || content == null) {
                        result.error("invalid_args", "treeUri、fileName、content 不能为空", null)
                    } else {
                        result.success(writeJsonFile(treeUriString, fileName, content))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readTextFile(fileUri: String): String? {
        val uri = Uri.parse(fileUri)
        contentResolver.openInputStream(uri)?.use { inputStream ->
            val buffer = ByteArrayOutputStream()
            val chunk = ByteArray(8 * 1024)
            while (true) {
                val count = inputStream.read(chunk)
                if (count <= 0) break
                buffer.write(chunk, 0, count)
            }
            return buffer.toString(StandardCharsets.UTF_8.name())
        }
        return null
    }

    private fun writeJsonFile(treeUriString: String, fileName: String, content: String): String? {
        val treeUri = Uri.parse(treeUriString)
        val parentDocumentUri = DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )
        val targetUri =
            findChildDocumentUri(treeUri, fileName)
                ?: DocumentsContract.createDocument(
                    contentResolver,
                    parentDocumentUri,
                    "application/json",
                    fileName,
                )
        if (targetUri != null) {
            contentResolver.openOutputStream(targetUri, "wt")?.use { outputStream ->
                OutputStreamWriter(outputStream, StandardCharsets.UTF_8).use { writer ->
                    writer.write(content)
                    writer.flush()
                }
            }
            return targetUri.toString()
        }
        return null
    }

    private fun findChildDocumentUri(treeUri: Uri, fileName: String): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(childrenUri, projection, null, null, null)
            while (cursor?.moveToNext() == true) {
                val documentId = cursor.getString(0) ?: continue
                val name = cursor.getString(1) ?: continue
                if (name == fileName) {
                    return DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                }
            }
        } finally {
            cursor?.close()
        }
        return null
    }

    private fun listJsonFiles(treeUriString: String): List<Map<String, Any>> {
        val treeUri = Uri.parse(treeUriString)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )

        val files = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(childrenUri, projection, null, null, null)
            while (cursor?.moveToNext() == true) {
                val documentId = cursor.getString(0) ?: continue
                val name = cursor.getString(1) ?: continue
                if (!name.endsWith(".json")) continue

                val size = if (cursor.isNull(2)) 0L else cursor.getLong(2)
                val lastModified = if (cursor.isNull(3)) 0L else cursor.getLong(3)
                val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)

                files.add(
                    mapOf(
                        "name" to name,
                        "uri" to fileUri.toString(),
                        "size" to size,
                        "lastModified" to lastModified,
                    )
                )
            }
        } finally {
            cursor?.close()
        }

        return files
    }

    private fun openDocumentTreeReadWrite(result: MethodChannel.Result) {
        if (pendingSafResult != null) {
            result.error("saf_busy", "已有一个目录授权请求正在进行中", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }

        pendingSafResult = result
        startActivityForResult(intent, OPEN_DOCUMENT_TREE_READ_WRITE_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == OPEN_DOCUMENT_TREE_READ_WRITE_REQUEST) {
            val result = pendingSafResult
            pendingSafResult = null

            if (result == null) {
                super.onActivityResult(requestCode, resultCode, data)
                return
            }

            if (resultCode != Activity.RESULT_OK) {
                result.success(null)
                return
            }

            val uri = data?.data
            if (uri == null) {
                result.success(null)
                return
            }

            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
                result.success(uri.toString())
            } catch (e: Exception) {
                result.error("saf_permission_error", e.message, null)
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }
}
