package dev.benderapps.scrubprep.learn

import dev.benderapps.scrubprep.model.QAPair

/**
 * A single Learn-tab section (e.g. "Cutting Instruments"): a titled, icon-labeled list of
 * short bullets. `systemImage` is the iOS SF Symbol name the content was authored with;
 * see `iconForSymbol`.
 */
data class LearnTopic(val title: String, val systemImage: String, val items: List<String>)

/**
 * One reference diagram on a Learn detail sheet (Positioning, Incisions) — `caption` labels
 * the view ("Side view", "Overhead view") when an entry has more than one. `assetName` is a
 * drawable name (hyphens allowed; looked up with underscores).
 */
data class LearnDiagram(val assetName: String, val caption: String? = null) {
    companion object {
        /** A side view plus an overhead view, captioned. */
        fun sideAndOverhead(baseName: String) = listOf(
            LearnDiagram(baseName, caption = "Side view"),
            LearnDiagram("$baseName-overhead", caption = "Overhead view"),
        )
    }
}

/** A citation for Learn content (medical information must cite its sources). */
data class LearnSource(val title: String, val detail: String, val url: String)

/** One photo of an instrument — `caption` labels which variant it is (e.g. "Curved"). */
data class InstrumentImage(val assetName: String, val caption: String? = null)

/** Photo credit shown at the bottom of an instrument's detail sheet. */
data class InstrumentAttribution(
    val sourceName: String,
    val usedWithPermission: Boolean,
    val productURL: String?,
)

/**
 * One instrument in the Instruments 101 reference. A row is only tappable once it has at
 * least one image, so there's never a tap that opens an empty sheet.
 */
data class Instrument(
    val name: String,
    val description: String,
    val images: List<InstrumentImage> = emptyList(),
    val attribution: InstrumentAttribution? = null,
)

data class InstrumentCategory(val title: String, val systemImage: String, val instruments: List<Instrument>)

/**
 * One patient position in the Positioning reference. Written for recognition and
 * discussion — deliberately not step-by-step positioning protocols.
 */
data class PatientPosition(
    val name: String,
    val alternateNames: String?,
    /** One-line summary shown in the list row. */
    val summary: String,
    val description: String,
    val commonlyUsedFor: List<String>,
    val pressurePointsAndNerves: List<String>,
    /** Only effects that are commonly taught; empty when there's nothing notable. */
    val physiologicEffects: List<String>,
    val howYouCanHelp: List<String>,
    val questions: List<QAPair>,
    val diagrams: List<LearnDiagram> = emptyList(),
)

/** One incision in the Incisions reference — deliberately not operative technique. */
data class Incision(
    val name: String,
    val alternateNames: String?,
    val summary: String,
    val description: String,
    val commonlyUsedFor: List<String>,
    /** Layers, landmarks, and structures at risk. */
    val anatomy: List<String>,
    /** Advantages and drawbacks compared with other approaches. */
    val tradeoffs: List<String>,
    val questions: List<QAPair>,
    val diagrams: List<LearnDiagram> = emptyList(),
)

/** A body region grouping incisions on the Incisions screen. */
data class IncisionRegion(val title: String, val systemImage: String, val incisions: List<Incision>)

/**
 * One device in the Energy devices reference. `name` is the generic name; `brandNames` are
 * common brand names/nicknames. Orientation content — deliberately not operating instructions.
 */
data class EnergyDevice(
    val name: String,
    val brandNames: String?,
    val summary: String,
    val howItWorks: String,
    val whenUsed: List<String>,
    val safetyPoints: List<String>,
    val questions: List<QAPair>,
)
