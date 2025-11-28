package com.example.loginfirebase

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app.channel.pdf_save"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"savePdfToDownloads" -> {
					val fileName = call.argument<String>("fileName") ?: "file.pdf"
					val bytes = call.argument<ByteArray>("bytes")
					val subfolder = call.argument<String>("subfolder")
					if (bytes == null) {
						result.error("NO_BYTES", "No bytes provided", null)
						return@setMethodCallHandler
					}
					val uriString = saveFileToDownloads(fileName, bytes, subfolder)
					if (uriString != null) result.success(uriString) else result.error("SAVE_FAILED", "Save failed", null)
				}
				"openFile" -> {
					val uriStr = call.argument<String>("uri")
					if (uriStr == null) {
						result.error("NO_URI", "No uri provided", null)
						return@setMethodCallHandler
					}
					val ok = openFileUri(uriStr)
					if (ok) result.success(true) else result.error("OPEN_FAILED", "Failed to open uri", null)
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun openFileUri(uriString: String): Boolean {
		return try {
			val uri = Uri.parse(uriString)
			val intent = Intent(Intent.ACTION_VIEW)
			intent.setDataAndType(uri, "application/pdf")
			intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			startActivity(intent)
			true
		} catch (e: Exception) {
			e.printStackTrace()
			false
		}
	}

	private fun saveFileToDownloads(fileName: String, data: ByteArray, subfolder: String?): String? {
		val resolver = contentResolver
		val contentValues = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
			put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				val relativePath = if (subfolder.isNullOrEmpty()) "Download" else "Download/$subfolder"
				put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
			}
		}

		val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
		val uri = resolver.insert(collection, contentValues) ?: return null

		var out: java.io.OutputStream? = null
		return try {
			out = resolver.openOutputStream(uri)
			out?.write(data)
			uri.toString()
		} catch (e: Exception) {
			e.printStackTrace()
			null
		} finally {
			try { out?.close() } catch (_: Exception) {}
		}
	}
}
