package io.github.jean8791.aventura

import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private var eventos: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "aventura/controles")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(argumentos: Any?, sink: EventChannel.EventSink?) {
                    eventos = sink
                }

                override fun onCancel(argumentos: Any?) {
                    eventos = null
                }
            })
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val sink = eventos
        if (sink != null && event.repeatCount == 0 &&
            (event.action == KeyEvent.ACTION_DOWN || event.action == KeyEvent.ACTION_UP)
        ) {
            sink.success(
                mapOf(
                    "tipo" to "tecla",
                    "dispositivo" to event.deviceId,
                    "codigo" to event.keyCode,
                    "apertou" to (event.action == KeyEvent.ACTION_DOWN),
                )
            )
        }
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        val sink = eventos
        if (sink != null && event.action == MotionEvent.ACTION_MOVE &&
            (event.isFromSource(InputDevice.SOURCE_JOYSTICK) || event.isFromSource(InputDevice.SOURCE_GAMEPAD))
        ) {
            val chapeuX = event.getAxisValue(MotionEvent.AXIS_HAT_X)
            val chapeuY = event.getAxisValue(MotionEvent.AXIS_HAT_Y)
            val alavancaX = event.getAxisValue(MotionEvent.AXIS_X)
            val x = if (abs(chapeuX) > 0.5f) chapeuX else if (abs(alavancaX) > 0.4f) alavancaX else 0f
            sink.success(
                mapOf(
                    "tipo" to "eixo",
                    "dispositivo" to event.deviceId,
                    "x" to x.toDouble(),
                    "y" to chapeuY.toDouble(),
                )
            )
        }
        return super.dispatchGenericMotionEvent(event)
    }
}
