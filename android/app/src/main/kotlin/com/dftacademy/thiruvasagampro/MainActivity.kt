package com.dftacademy.thiruvasagampro

import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity

// Extends AudioServiceActivity (which itself extends FlutterActivity) so the
// background audio service can attach to this activity and show its media
// notification / respond to lock-screen and headset controls.
class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
