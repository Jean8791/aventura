package io.github.jean8791.aventura

import android.content.Context
import android.hardware.input.InputManager
import android.os.Handler
import android.os.Looper
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private var eventos: EventChannel.EventSink? = null
    private var jogandoEmDupla = false
    private val origens = HashMap<Int, String>()
    private val ultimaDirecao = HashMap<Int, Pair<Int, Int>>()

    private val ouvinteDeDispositivos = object : InputManager.InputDeviceListener {
        override fun onInputDeviceAdded(id: Int) = esquecerDispositivos()
        override fun onInputDeviceRemoved(id: Int) = esquecerDispositivos()
        override fun onInputDeviceChanged(id: Int) = esquecerDispositivos()
    }

    private fun esquecerDispositivos() {
        origens.clear()
        ultimaDirecao.clear()
    }

    private fun origemDe(id: Int): String = origens.getOrPut(id) {
        val dispositivo = InputDevice.getDevice(id)
        if (dispositivo == null || dispositivo.isVirtual) {
            "$id"
        } else {
            val descritor = dispositivo.descriptor
            val repetido = InputDevice.getDeviceIds().any {
                it != id && InputDevice.getDevice(it)?.descriptor == descritor
            }
            if (repetido) "$descritor#$id" else descritor
        }
    }

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aventura/estado")
            .setMethodCallHandler { chamada, resposta ->
                if (chamada.method == "jogandoEmDupla") {
                    jogandoEmDupla = chamada.arguments == true
                    ultimaDirecao.clear()
                    resposta.success(null)
                } else {
                    resposta.notImplemented()
                }
            }
        (getSystemService(Context.INPUT_SERVICE) as InputManager)
            .registerInputDeviceListener(ouvinteDeDispositivos, Handler(Looper.getMainLooper()))
    }

    override fun onDestroy() {
        (getSystemService(Context.INPUT_SERVICE) as InputManager)
            .unregisterInputDeviceListener(ouvinteDeDispositivos)
        super.onDestroy()
    }

    override fun onWindowFocusChanged(temFoco: Boolean) {
        super.onWindowFocusChanged(temFoco)
        if (temFoco) {
            focarNoJogo()
        }
    }

    private fun focarNoJogo() {
        val tela = findViewById<View>(FLUTTER_VIEW_ID) ?: return
        if (!tela.hasFocus()) {
            tela.isFocusable = true
            tela.isFocusableInTouchMode = true
            tela.requestFocus()
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode in teclasQueFicamNoJogo) {
            focarNoJogo()
        }
        val sink = eventos
        if (sink != null && event.repeatCount == 0 &&
            (event.action == KeyEvent.ACTION_DOWN || event.action == KeyEvent.ACTION_UP)
        ) {
            sink.success(
                mapOf(
                    "tipo" to "tecla",
                    "dispositivo" to event.deviceId,
                    "origem" to origemDe(event.deviceId),
                    "codigo" to event.keyCode,
                    "apertou" to (event.action == KeyEvent.ACTION_DOWN),
                )
            )
        }
        val tratado = super.dispatchKeyEvent(event)
        return tratado || event.keyCode in teclasQueFicamNoJogo
    }

    private val teclasQueFicamNoJogo = setOf(
        KeyEvent.KEYCODE_DPAD_UP,
        KeyEvent.KEYCODE_DPAD_DOWN,
        KeyEvent.KEYCODE_DPAD_LEFT,
        KeyEvent.KEYCODE_DPAD_RIGHT,
        KeyEvent.KEYCODE_DPAD_CENTER,
        KeyEvent.KEYCODE_DPAD_UP_LEFT,
        KeyEvent.KEYCODE_DPAD_UP_RIGHT,
        KeyEvent.KEYCODE_DPAD_DOWN_LEFT,
        KeyEvent.KEYCODE_DPAD_DOWN_RIGHT,
        KeyEvent.KEYCODE_ENTER,
        KeyEvent.KEYCODE_NUMPAD_ENTER,
        KeyEvent.KEYCODE_TAB,
    )

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        val doControle = event.action == MotionEvent.ACTION_MOVE &&
            (event.isFromSource(InputDevice.SOURCE_JOYSTICK) || event.isFromSource(InputDevice.SOURCE_GAMEPAD))
        if (!doControle) {
            return super.dispatchGenericMotionEvent(event)
        }
        val chapeuX = event.getAxisValue(MotionEvent.AXIS_HAT_X)
        val chapeuY = event.getAxisValue(MotionEvent.AXIS_HAT_Y)
        val alavancaX = event.getAxisValue(MotionEvent.AXIS_X)
        val zonaMorta = max(0.5f, (event.device?.getMotionRange(MotionEvent.AXIS_X, event.source)?.flat ?: 0f) * 2f)
        val x = when {
            abs(chapeuX) > 0.5f -> if (chapeuX > 0) 1 else -1
            abs(alavancaX) > zonaMorta -> if (alavancaX > 0) 1 else -1
            else -> 0
        }
        val y = if (abs(chapeuY) > 0.5f) (if (chapeuY > 0) 1 else -1) else 0
        val direcao = Pair(x, y)
        val sink = eventos
        if (sink != null && ultimaDirecao[event.deviceId] != direcao) {
            ultimaDirecao[event.deviceId] = direcao
            sink.success(
                mapOf(
                    "tipo" to "eixo",
                    "dispositivo" to event.deviceId,
                    "origem" to origemDe(event.deviceId),
                    "x" to x.toDouble(),
                    "y" to y.toDouble(),
                )
            )
        }
        if (jogandoEmDupla) {
            return true
        }
        return super.dispatchGenericMotionEvent(event)
    }
}
