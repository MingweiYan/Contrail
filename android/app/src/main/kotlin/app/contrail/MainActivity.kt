package app.contrail

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.contrail/logging"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    }
}
