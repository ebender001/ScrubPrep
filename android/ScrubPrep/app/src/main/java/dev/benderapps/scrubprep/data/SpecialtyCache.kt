package dev.benderapps.scrubprep.data

import android.content.Context
import dev.benderapps.scrubprep.model.Specialty
import dev.benderapps.scrubprep.model.mapObjects
import dev.benderapps.scrubprep.model.toJsonArray
import org.json.JSONArray

/**
 * Persists the last-fetched specialty list so the Home screen's specialty menu can render
 * instantly on launch, plus which specialty the student had selected so it's remembered
 * across launches.
 */
class SpecialtyCache(context: Context) {
    private val prefs = context.getSharedPreferences("specialties.v1", Context.MODE_PRIVATE)

    fun load(): List<Specialty> {
        val text = prefs.getString(KEY_SPECIALTIES, null) ?: return emptyList()
        return runCatching { JSONArray(text).mapObjects(Specialty::fromJson) }.getOrDefault(emptyList())
    }

    fun save(specialties: List<Specialty>) {
        prefs.edit().putString(KEY_SPECIALTIES, specialties.toJsonArray { it.toJson() }.toString()).apply()
    }

    fun loadSelectedId(): String? = prefs.getString(KEY_SELECTED, null)

    /** Pass `null` to clear the persisted selection (e.g. when the user deselects). */
    fun saveSelectedId(id: String?) {
        prefs.edit().apply { if (id == null) remove(KEY_SELECTED) else putString(KEY_SELECTED, id) }.apply()
    }

    private companion object {
        const val KEY_SPECIALTIES = "cachedSpecialties"
        const val KEY_SELECTED = "selectedSpecialtyID"
    }
}
