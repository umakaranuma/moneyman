package com.fynux.finzo

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity : FlutterActivity() {
    private val mediaChannel = "finzo/media_scan"
    private val fileOpenChannel = "finzo/file_open"
    private val downloadsChannel = "finzo/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("INVALID_PATH", "Path is required", null)
                            return@setMethodCallHandler
                        }
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            null
                        ) { _, _ -> }
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fileOpenChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openFile" -> {
                        val path = call.argument<String>("path")
                        val uriString = call.argument<String>("uri")
                        try {
                            val uri: Uri
                            val extension: String
                            if (!uriString.isNullOrBlank()) {
                                uri = Uri.parse(uriString)
                                extension = uri.lastPathSegment?.substringAfterLast('.', "")?.lowercase()
                                    ?: ""
                            } else {
                                if (path.isNullOrBlank()) {
                                    result.error("INVALID_PATH", "Path or uri is required", null)
                                    return@setMethodCallHandler
                                }
                                val file = File(path)
                                if (!file.exists()) {
                                    result.error("FILE_NOT_FOUND", "File not found", null)
                                    return@setMethodCallHandler
                                }
                                uri = FileProvider.getUriForFile(
                                    this,
                                    "$packageName.fileprovider",
                                    file
                                )
                                extension = file.extension.lowercase()
                            }

                            val mimeType = when (extension) {
                                "pdf" -> "application/pdf"
                                "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                                "xls" -> "application/vnd.ms-excel"
                                else -> "*/*"
                            }

                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, mimeType)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: ActivityNotFoundException) {
                            result.error("NO_APP", "No app found to open this file type", null)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveBytesToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (fileName.isNullOrBlank() || bytes == null) {
                            result.error("INVALID_ARGS", "fileName and bytes are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val resolver = applicationContext.contentResolver
                            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
                            val displayName = buildUniqueDownloadsName(fileName, resolver, collection)

                            val values = ContentValues().apply {
                                put(MediaStore.Downloads.DISPLAY_NAME, displayName)
                                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                put(MediaStore.Downloads.IS_PENDING, 1)
                            }
                            val uri = resolver.insert(collection, values)
                                ?: throw IllegalStateException("Failed to create MediaStore record.")

                            resolver.openOutputStream(uri)?.use { stream ->
                                stream.write(bytes)
                                stream.flush()
                            } ?: throw IllegalStateException("Failed to open output stream.")

                            val completeValues = ContentValues().apply {
                                put(MediaStore.Downloads.IS_PENDING, 0)
                            }
                            resolver.update(uri, completeValues, null, null)

                            val pseudoPath = "/storage/emulated/0/Download/$displayName"
                            result.success(
                                mapOf(
                                    "displayName" to displayName,
                                    "uri" to uri.toString(),
                                    "path" to pseudoPath,
                                )
                            )
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun buildUniqueDownloadsName(
        baseName: String,
        resolver: android.content.ContentResolver,
        collection: Uri
    ): String {
        var candidate = baseName
        var index = 1
        while (downloadNameExists(candidate, resolver, collection)) {
            candidate = "$baseName($index)"
            index++
        }
        return candidate
    }

    private fun downloadNameExists(
        displayName: String,
        resolver: android.content.ContentResolver,
        collection: Uri
    ): Boolean {
        val projection = arrayOf(MediaStore.Downloads._ID)
        val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf(displayName)
        resolver.query(collection, projection, selection, selectionArgs, null).use { cursor ->
            return cursor != null && cursor.moveToFirst()
        }
    }
}

