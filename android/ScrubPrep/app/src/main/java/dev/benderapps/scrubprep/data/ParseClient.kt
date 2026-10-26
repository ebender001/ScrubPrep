package dev.benderapps.scrubprep.data

import dev.benderapps.scrubprep.config.AppConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/** A Parse Server error response: `{"code": 101, "error": "..."}`. */
class ParseApiException(val code: Int, message: String) : Exception(message) {
    companion object {
        const val OBJECT_NOT_FOUND = 101
        const val INVALID_EMAIL_ADDRESS = 125
        const val USERNAME_TAKEN = 202
        const val USER_EMAIL_TAKEN = 203
        const val INVALID_SESSION_TOKEN = 209
    }
}

/** The network couldn't be reached (or the response couldn't be read). */
class ParseNetworkException(cause: Throwable) : Exception(cause)

/**
 * A minimal Parse Server REST client — just what the app needs (Cloud Functions plus
 * email/password auth). The iOS app uses the Parse Swift SDK; the Android app talks to the
 * same REST API directly, so the backend needs no changes.
 */
class ParseClient(private val sessionStore: SessionStore) {

    /** Calls the Cloud Function [name] and returns its `result` object. */
    suspend fun callFunction(name: String, params: JSONObject = JSONObject()): JSONObject =
        request("POST", "/functions/$name", params).optJSONObject("result") ?: JSONObject()

    suspend fun logIn(username: String, password: String): JSONObject =
        request("POST", "/login", JSONObject().put("username", username).put("password", password))

    suspend fun signUp(username: String, email: String, password: String): JSONObject =
        request(
            "POST",
            "/users",
            JSONObject().put("username", username).put("email", email).put("password", password),
        )

    suspend fun requestPasswordReset(email: String) {
        request("POST", "/requestPasswordReset", JSONObject().put("email", email))
    }

    suspend fun logOut() {
        request("POST", "/logout", JSONObject())
    }

    /** The signed-in user's own `_User` row. */
    suspend fun fetchCurrentUser(): JSONObject = request("GET", "/users/me", null)

    private suspend fun request(method: String, path: String, body: JSONObject?): JSONObject =
        withContext(Dispatchers.IO) {
            val connection = try {
                (URL(AppConfig.PARSE_SERVER_URL + path).openConnection() as HttpURLConnection)
            } catch (e: IOException) {
                throw ParseNetworkException(e)
            }
            try {
                connection.requestMethod = method
                connection.connectTimeout = 20_000
                // AI generation (prep, quiz questions) can take a while server-side.
                connection.readTimeout = 120_000
                connection.setRequestProperty("X-Parse-Application-Id", AppConfig.PARSE_APPLICATION_ID)
                connection.setRequestProperty("X-Parse-Client-Key", AppConfig.PARSE_CLIENT_KEY)
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                sessionStore.sessionToken?.let { connection.setRequestProperty("X-Parse-Session-Token", it) }
                if (body != null) {
                    connection.doOutput = true
                    connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                }

                val status = connection.responseCode
                val stream = if (status in 200..299) connection.inputStream else connection.errorStream
                val text = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
                val json = try {
                    if (text.isBlank()) JSONObject() else JSONObject(text)
                } catch (e: JSONException) {
                    if (status in 200..299) throw ParseNetworkException(e)
                    JSONObject()
                }
                if (status !in 200..299) {
                    throw ParseApiException(json.optInt("code", status), json.optString("error", "HTTP $status"))
                }
                json
            } catch (e: IOException) {
                throw ParseNetworkException(e)
            } finally {
                connection.disconnect()
            }
        }
}
