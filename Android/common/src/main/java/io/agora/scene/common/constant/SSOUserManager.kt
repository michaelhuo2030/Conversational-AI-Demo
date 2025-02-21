package io.agora.scene.common.constant

import android.text.TextUtils
import com.google.gson.JsonIOException
import io.agora.scene.common.net.SSOUserInfo
import io.agora.scene.common.util.CommonLogger
import io.agora.scene.common.util.GsonTools
import io.agora.scene.common.util.LocalStorageUtil

object SSOUserManager {

    private const val TAG = "SSOUserManager"

    private const val CURRENT_SSO_TOKEN: String = "current_sso_token"

    private const val CURRENT_SSO_USER: String = "current_sso_user"

    private var mToken: String = ""

    private var mUserIfo: SSOUserInfo? = null

    fun saveToken(token: String) {
        this.mToken = token
        LocalStorageUtil.putString(CURRENT_SSO_TOKEN, mToken)
    }

    fun getToken(): String {
        if (mToken.isEmpty()) {
            mToken = LocalStorageUtil.getString(CURRENT_SSO_TOKEN, "")
        }
        return mToken
    }

    @JvmStatic
    fun logout() {
        this.mToken = ""
        this.mUserIfo = null
        LocalStorageUtil.clear()
    }

    fun saveUser(userData: SSOUserInfo) {
        this.mUserIfo = userData
        val userString: String = try {
            GsonTools.beanToString(mUserIfo) ?: ""
        } catch (io: JsonIOException) {
            CommonLogger.e(TAG, io.message ?: "parse error")
            ""
        }
        LocalStorageUtil.putString(CURRENT_SSO_USER, userString)
    }

    fun isLogin(): Boolean {
        val userInfo = getUser()
        return userInfo.accountUid.isNotEmpty() && userInfo.displayName.isNotEmpty() && mToken.isNotEmpty()
    }

    @JvmStatic
    fun getUser(): SSOUserInfo {
        if (mUserIfo != null && !mUserIfo?.accountUid.isNullOrEmpty()) {
            return mUserIfo!!
        }
        readingUserInfoFromPrefs()
        return mUserIfo!!
    }

    private fun readingUserInfoFromPrefs() {
        val userInfo = LocalStorageUtil.getString(CURRENT_SSO_USER, "")
        try {
            if (!TextUtils.isEmpty(userInfo)) {
                mUserIfo = GsonTools.toBean(userInfo, SSOUserInfo::class.java)
            }
        } catch (e: Exception) {
            CommonLogger.e(TAG, "Error parsing user info: ${e.message}")
            mUserIfo = SSOUserInfo("")
        }
        if (mUserIfo == null) mUserIfo = SSOUserInfo("")
    }
}