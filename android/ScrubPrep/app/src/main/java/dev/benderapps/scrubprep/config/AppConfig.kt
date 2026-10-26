package dev.benderapps.scrubprep.config

/**
 * Central place for backend configuration. Nothing here is a secret in the way an OpenAI
 * key is — the Parse Client Key is designed to ship inside client apps and is scoped by
 * the server's Class-Level Permissions, unlike the Master Key (which must only ever live
 * server-side, see backend/README.md). Same values as the iOS app's AppConfig.
 */
object AppConfig {
    const val PARSE_APPLICATION_ID = "8wtDjVoWgS9tKzB9DFwsXpnvOsJsyZuAl0RR6J6c"
    const val PARSE_CLIENT_KEY = "5ZCOxyWsRhXRyYZNsDPMY3vkq1xKCLRWvkiMZULN"
    const val PARSE_SERVER_URL = "https://parseapi.back4app.com"
}

/** External legal links shown on the paywall and in Settings (hosted from website/). */
object AppLinks {
    const val TERMS_OF_USE = "https://scrubprep.app/terms.html"
    const val PRIVACY_POLICY = "https://scrubprep.app/privacy.html"
    const val SUPPORT_EMAIL = "support@benderapps.dev"
}
