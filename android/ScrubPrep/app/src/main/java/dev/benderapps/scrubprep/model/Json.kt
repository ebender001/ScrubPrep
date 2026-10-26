package dev.benderapps.scrubprep.model

import org.json.JSONArray
import org.json.JSONObject

internal fun JSONArray.toStringList(): List<String> = List(length()) { getString(it) }

internal fun <T> JSONArray.mapObjects(transform: (JSONObject) -> T): List<T> =
    List(length()) { transform(getJSONObject(it)) }

internal fun JSONObject.stringList(key: String): List<String> =
    optJSONArray(key)?.toStringList() ?: emptyList()

/** `optString` returns "null" for JSON null; this returns a real Kotlin null instead. */
internal fun JSONObject.stringOrNull(key: String): String? =
    if (isNull(key)) null else optString(key)

internal fun Iterable<String>.toJsonArray(): JSONArray = JSONArray().also { array -> forEach { array.put(it) } }

internal fun <T> Iterable<T>.toJsonArray(transform: (T) -> JSONObject): JSONArray =
    JSONArray().also { array -> forEach { array.put(transform(it)) } }
