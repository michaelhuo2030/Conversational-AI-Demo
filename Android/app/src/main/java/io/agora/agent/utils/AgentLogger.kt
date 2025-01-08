package io.agora.agent.utils

import android.util.Log

object AgentLogger {

    private val entLogger = EntLogger(EntLogger.Config("Agent"))

    @JvmStatic
    fun d(tag: String, message: String, vararg args: Any) {
        Log.d("AgentLogger", message)
        entLogger.d(tag, message, args)
    }

    @JvmStatic
    fun w(tag: String, message: String, vararg args: Any) {
        entLogger.w(tag, message, args)
    }

    @JvmStatic
    fun e(tag: String, message: String, vararg args: Any) {
        entLogger.e(tag, message, args)
    }

    @JvmStatic
    fun e(tag: String, throwable: Throwable? = null, message: String = "") {
        if (throwable != null) {
            entLogger.e(tag, throwable, message)
        } else {
            entLogger.e(tag, message)
        }
    }

}