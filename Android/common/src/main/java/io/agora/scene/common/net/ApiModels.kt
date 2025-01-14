package io.agora.scene.common.net

import com.google.gson.annotations.SerializedName
import java.io.Serializable

open class BaseResponse<T> : Serializable {
    @SerializedName("errorCode", alternate = ["code"])
    var code: Int? = null

    @SerializedName("message", alternate = ["msg"])
    var message: String? = ""

    @SerializedName(value = "obj", alternate = ["result", "data"])
    var data: T? = null

    val isSuccess: Boolean get() = 0 == code
}
