package io.agora.agent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class ServiceStarterReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "io.agora.agent.START_FOREGROUND_SERVICE") {
            val serviceIntent = Intent(context, RtcForegroundService::class.java)
            context.startForegroundService(serviceIntent)
        }
    }
} 