package com.fittrack.fittrack_mobile

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var musicAudio: MusicAudio? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        musicAudio = MusicAudio(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    // onStop (not onPause): a notification shade or permission dialog pauses the
    // activity without hiding it, and Flutter only stops the tuner once hidden.
    override fun onStop() {
        musicAudio?.stop()
        super.onStop()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        musicAudio?.dispose()
        musicAudio = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        musicAudio?.permissionResult(requestCode, grantResults)
    }
}
