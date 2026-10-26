// Generated from the iOS app's Learn catalogs. Clinically reviewed 2026-09-26. Re-review any new or changed
// numeric, anatomic, or safety-critical statement before release.

package dev.benderapps.scrubprep.learn

import dev.benderapps.scrubprep.model.QAPair

val instrumentCategories: List<InstrumentCategory> = listOf(
    InstrumentCategory(
        title = "Cutting",
        systemImage = "scissors",
        instruments = listOf(
            Instrument(
                name = "Scalpel (Bard-Parker)",
                description = "The primary tool for skin and tissue incisions.",
                images = listOf(InstrumentImage("scalpel-bard-parker"))
            ),
            Instrument(
                name = "Metzenbaum scissors",
                description = "Fine scissors for dissecting delicate tissue.",
                images = listOf(InstrumentImage("metzenbaum-scissors")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/7007-216-2sc/"
                )
            ),
            Instrument(
                name = "Mayo scissors",
                description = "Heavier scissors for cutting sutures and tougher tissue.",
                images = listOf(
                    InstrumentImage("mayo-scissors-curved", caption = "Curved"),
                    InstrumentImage("mayo-scissors-straight", caption = "Straight"),
                ),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/7007-204sc/"
                )
            ),
            Instrument(
                name = "Iris scissors",
                description = "Small, fine scissors for precise cutting of delicate tissue or sutures.",
                images = listOf(InstrumentImage("iris-scissors")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/7007-288sc/"
                )
            ),
        )
    ),
    InstrumentCategory(
        title = "Grasping & Holding",
        systemImage = "hand.raised",
        instruments = listOf(
            Instrument(
                name = "DeBakey forceps",
                description = "Atraumatic forceps for handling delicate tissue and vessels.",
                images = listOf(InstrumentImage("debakey-forceps")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/4004-42/"
                )
            ),
            Instrument(
                name = "Adson forceps",
                description = "Toothed forceps for grasping skin during closure.",
                images = listOf(InstrumentImage("adson-forceps")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/4004-27/"
                )
            ),
            Instrument(
                name = "Allis clamp",
                description = "Grasps and holds tissue with minimal crush injury.",
                images = listOf(InstrumentImage("allis-clamp")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/4635-06/"
                )
            ),
            Instrument(
                name = "Babcock clamp",
                description = "Gently grasps bowel or other delicate structures.",
                images = listOf(InstrumentImage("babcock-clamp"))
            ),
            Instrument(
                name = "Gerald forceps",
                description = "Fine-tipped forceps for delicate tissue handling, often with a platform tip for microsurgical work.",
                images = listOf(InstrumentImage("gerald-forceps")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/4004-240/"
                )
            ),
        )
    ),
    InstrumentCategory(
        title = "Clamping & Hemostasis",
        systemImage = "bolt.heart",
        instruments = listOf(
            Instrument(
                name = "Kelly clamp",
                description = "General-purpose clamp for grasping tissue or vessels.",
                images = listOf(InstrumentImage("kelly-clamp"))
            ),
            Instrument(
                name = "Mosquito clamp",
                description = "Small clamp for fine hemostasis.",
                images = listOf(InstrumentImage("mosquito-clamp"))
            ),
            Instrument(
                name = "Right-angle clamp",
                description = "Used to dissect around and encircle structures.",
                images = listOf(InstrumentImage("right-angle-clamp"))
            ),
        )
    ),
    InstrumentCategory(
        title = "Retracting",
        systemImage = "rectangle.expand.vertical",
        instruments = listOf(
            Instrument(
                name = "Army-Navy retractor",
                description = "Handheld retractor for shallow wounds.",
                images = listOf(InstrumentImage("army-navy-retractor"))
            ),
            Instrument(
                name = "Richardson retractor",
                description = "Wide-bladed retractor for deeper exposure.",
                images = listOf(InstrumentImage("richardson-retractor"))
            ),
            Instrument(
                name = "Self-retaining retractor (Bookwalter, Balfour)",
                description = "Holds a wound open hands-free.",
                images = listOf(
                    InstrumentImage("self-retaining-retractor-bookwalter", caption = "Bookwalter"),
                    InstrumentImage("self-retaining-retractor-balfour", caption = "Balfour"),
                )
            ),
            Instrument(
                name = "Weitlaner retractor",
                description = "Self-retaining retractor with sharp or blunt prongs, commonly used for smaller or superficial wounds.",
                images = listOf(InstrumentImage("weitlaner-retractor"))
            ),
        )
    ),
    InstrumentCategory(
        title = "Suturing",
        systemImage = "link",
        instruments = listOf(
            Instrument(
                name = "Needle driver",
                description = "Holds and passes the needle during suturing.",
                images = listOf(InstrumentImage("needle-driver"))
            ),
            Instrument(
                name = "Ryder needle holder",
                description = "A slender needle holder favored for fine, delicate suturing.",
                images = listOf(InstrumentImage("ryder-needle-holder")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/6006-29/"
                )
            ),
            Instrument(
                name = "Castroviejo needle holder",
                description = "A spring-loaded, palm-controlled needle holder used for fine or microsurgical suturing.",
                images = listOf(InstrumentImage("castroviejo-needle-holder")),
                attribution = InstrumentAttribution(
                    sourceName = "Scanlan International",
                    usedWithPermission = true,
                    productURL = "https://www.scanlaninternational.com/product/6006-56-3/"
                )
            ),
        )
    ),
)
