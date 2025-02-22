package io.agora.scene.common.net

import com.google.gson.GsonBuilder
import com.google.gson.ToNumberPolicy
import com.google.gson.TypeAdapter
import com.google.gson.reflect.TypeToken
import com.google.gson.stream.JsonReader
import com.google.gson.stream.JsonWriter
import okhttp3.Interceptor
import okhttp3.Response
import org.json.JSONObject
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.io.IOException
import java.net.URI
import java.util.concurrent.TimeUnit

object ApiManager {

    private val gson =
        GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").setObjectToNumberStrategy(ToNumberPolicy.LONG_OR_DOUBLE)
            .registerTypeAdapter(TypeToken.get(JSONObject::class.java).type, object : TypeAdapter<JSONObject>() {
                @Throws(IOException::class)
                override fun write(jsonWriter: JsonWriter, value: JSONObject) {
                    jsonWriter.jsonValue(value.toString())
                }

                @Throws(IOException::class)
                override fun read(jsonReader: JsonReader): JSONObject? {
                    return null
                }
            })
            .disableHtmlEscaping()
            .enableComplexMapKeySerialization()
            .create()

    private var baseUrl = ""
    private const val version = "v2"
    private var retrofit: Retrofit? = null

    // 全局未授权回调
    private var onUnauthorizedCallback: (() -> Unit)? = null

    // 设置未授权回调
    fun setOnUnauthorizedCallback(callback: () -> Unit) {
        onUnauthorizedCallback = callback
    }

    // 清除未授权回调
    fun clearOnUnauthorizedCallback() {
        onUnauthorizedCallback = null
    }

    // 内部触发未授权回调
    internal fun notifyUnauthorized() {
        onUnauthorizedCallback?.invoke()
    }

    fun <T> getService(clazz: Class<T>): T {
        return retrofit!!.create(clazz)
    }

    fun setBaseURL(url: String) {
        if (baseUrl == url) {
            return
        }
        baseUrl = url
        retrofit = Retrofit.Builder()
            .client(
                SecureOkHttpClient.create()
                    .addInterceptor(HttpLogger())
                    .addInterceptor(DynamicConnectTimeout())
                    .addInterceptor(AuthorizationInterceptor())
                    .build()
            )
            .baseUrl(url)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }
}

class DynamicConnectTimeout : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val requestUrl = request.url.toString()
        val isUploadFileApi = requestUrl.contains(ApiManagerService.requestUploadLog)
        if (isUploadFileApi) {
            return chain.withConnectTimeout(60 * 3, TimeUnit.SECONDS)
                .withReadTimeout(60 * 3, TimeUnit.SECONDS)
                .withWriteTimeout(60 * 3, TimeUnit.SECONDS)
                .proceed(request)
        }
        return chain.proceed(request)
    }
}

class AuthorizationInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val response = chain.proceed(request)
        
        // Check for 401 response
        if (response.code == 401) {
            // 触发全局回调
            ApiManager.notifyUnauthorized()
//            throw UnauthorizedException("Unauthorized access. Please login again.")
        }
        
        return response
    }
}

class UnauthorizedException(message: String) : IOException(message)
