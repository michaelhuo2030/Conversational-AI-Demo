package io.agora.scene.common

import java.util.ServiceLoader

object DataProviderLoader {
    fun getDataProvider(): DataProvider? {
        val loader = ServiceLoader.load(DataProvider::class.java)
        return loader.firstOrNull()
    }
}