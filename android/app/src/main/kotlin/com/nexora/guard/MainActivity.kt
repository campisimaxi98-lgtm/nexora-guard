package com.nexora.guard

import android.Manifest
import android.content.Intent
import android.os.Build
import android.util.Base64
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal: registra el canal `nexora/collectors` (la
 * implementación compartida vive en [CollectorsChannel]) y atiende las
 * peticiones de permisos en tiempo de ejecución (BLE y notificaciones).
 */
class MainActivity : FlutterActivity() {

    private var pendingBleResult: MethodChannel.Result? = null
    private var pendingNotifResult: MethodChannel.Result? = null
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingImageResult: MethodChannel.Result? = null

    private companion object {
        const val PICK_FILE_REQUEST = 7404
        const val PICK_IMAGE_REQUEST = 7405
        const val PICK_MAX_BYTES = 20L * 1024 * 1024
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CollectorsChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext,
            activity = this,
            onRequestBlePermissions = { result ->
                // Una petición nueva reemplaza a una anterior sin resolver.
                pendingBleResult?.success(false)
                pendingBleResult = result
                CollectorsChannel.requestBlePermissions(this)
            },
            onRequestNotificationPermissions = { result ->
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    result.success(true)
                } else {
                    pendingNotifResult?.success(false)
                    pendingNotifResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        CollectorsChannel.NOTIF_REQUEST_CODE,
                    )
                }
            },
            onPickFile = { result ->
                pendingPickResult?.success(null)
                pendingPickResult = result
                try {
                    startActivityForResult(
                        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        },
                        PICK_FILE_REQUEST,
                    )
                } catch (_: Throwable) {
                    pendingPickResult?.success(null)
                    pendingPickResult = null
                }
            },
            onPickImage = { result ->
                pendingImageResult?.success(null)
                pendingImageResult = result
                try {
                    startActivityForResult(
                        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "image/*"
                        },
                        PICK_IMAGE_REQUEST,
                    )
                } catch (_: Throwable) {
                    pendingImageResult?.success(null)
                    pendingImageResult = null
                }
            },
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            PICK_FILE_REQUEST -> handlePickFile(resultCode, data)
            PICK_IMAGE_REQUEST -> handlePickImage(resultCode, data)
        }
    }

    private fun handlePickFile(resultCode: Int, data: Intent?) {
        val result = pendingPickResult ?: return
        pendingPickResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        Thread {
            val content = try {
                contentResolver.openInputStream(uri)?.use { stream ->
                    val bytes = stream.readBytes()
                    if (bytes.size > PICK_MAX_BYTES) null else String(bytes, Charsets.UTF_8)
                }
            } catch (_: Throwable) {
                null
            }
            runOnUiThread { result.success(content) }
        }.start()
    }

    private fun handlePickImage(resultCode: Int, data: Intent?) {
        val result = pendingImageResult ?: return
        pendingImageResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        Thread {
            val encoded = try {
                contentResolver.openInputStream(uri)?.use { stream ->
                    val bytes = stream.readBytes()
                    if (bytes.size > PICK_MAX_BYTES) null else Base64.encodeToString(bytes, Base64.NO_WRAP)
                }
            } catch (_: Throwable) {
                null
            }
            runOnUiThread { result.success(encoded) }
        }.start()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            CollectorsChannel.BLE_REQUEST_CODE -> {
                pendingBleResult?.success(CollectorsChannel.blePermissionsGranted(this))
                pendingBleResult = null
            }
            CollectorsChannel.NOTIF_REQUEST_CODE -> {
                pendingNotifResult?.success(NotificationHelper.permissionGranted(this))
                pendingNotifResult = null
            }
        }
    }
}
