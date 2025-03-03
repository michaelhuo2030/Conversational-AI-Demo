package io.agora.scene.convoai.api

class ApiException (val errorCode: Int, message: String="") : Exception(message)