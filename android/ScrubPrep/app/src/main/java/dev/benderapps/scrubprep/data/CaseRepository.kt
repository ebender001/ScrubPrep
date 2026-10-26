package dev.benderapps.scrubprep.data

import dev.benderapps.scrubprep.model.ScrubCase

/**
 * Looks up an already-prepared case by (normalized) description — used to skip a
 * network/OpenAI hit entirely when this exact case was already prepared. The backend is
 * the single source of truth for a user's saved cases, not the device.
 */
suspend fun ScrubPrepService.findCase(caseDescription: String): ScrubCase? {
    val normalized = ScrubCase.normalize(caseDescription)
    return listCases().firstOrNull { ScrubCase.normalize(it.caseDescription) == normalized }
}
