// Generated from the iOS app's Learn catalogs. Clinically reviewed 2026-09-26. Re-review any new or changed
// numeric, anatomic, or safety-critical statement before release.

package dev.benderapps.scrubprep.learn

import dev.benderapps.scrubprep.model.QAPair

val firstDayTopics: List<LearnTopic> = listOf(
    LearnTopic(
        title = "Before Rounds",
        systemImage = "sunrise",
        items = listOf(
            "Arrive early enough to review your patients before the team gathers.",
            "Know overnight events.",
            "Vitals, intake/output, diet, and bowel function.",
            "Pain control and ambulation status.",
            "Wounds and drains.",
            "Relevant labs.",
            "Prophylaxis (DVT, etc.).",
            "Disposition issues (what's needed before discharge).",
        )
    ),
    LearnTopic(
        title = "Presenting on Rounds",
        systemImage = "person.wave.2",
        items = listOf(
            "Identify the patient and post-op day.",
            "Overnight events and how the patient is feeling.",
            "Vitals and key trends (fever, tachycardia, urine output).",
            "Pertinent exam findings (wound, abdomen, lungs).",
            "Relevant labs and imaging.",
            "Diet, activity, lines/drains/tubes status.",
            "Assessment and plan for the day.",
        )
    ),
    LearnTopic(
        title = "Going to the OR",
        systemImage = "arrow.right.square",
        items = listOf(
            "Know where to go and get there early.",
            "Introduce yourself to the team.",
            "Review the patient's history before the case.",
            "Know the operation being performed.",
            "Meet the OR team — surgeon, anesthesia, nursing, techs.",
        )
    ),
    LearnTopic(
        title = "Scrubbing",
        systemImage = "hands.and.sparkles",
        items = listOf(
            "Surgical hand preparation.",
            "Entering the OR without breaking sterility.",
            "Gowning and gloving.",
            "Maintaining sterility throughout the case.",
            "Follow your institution's specific sterile technique policies and the instructions of OR personnel — this isn't a substitute for that training.",
        )
    ),
    LearnTopic(
        title = "OR Etiquette",
        systemImage = "person.2.badge.gearshape",
        items = listOf(
            "Introduce yourself to the team.",
            "Ask where you should stand.",
            "Don't touch anything unless you know it's sterile.",
            "If you think you've contaminated yourself, say so immediately.",
            "Questions are usually welcome — choose appropriate moments.",
            "Don't take correction personally.",
            "Help when appropriate, and remain engaged.",
        )
    ),
    LearnTopic(
        title = "When You Don't Know an Answer",
        systemImage = "questionmark.bubble",
        items = listOf(
            "It's okay to say you don't know.",
            "Try: \u201CI'm not sure, but I think\u2026\u201D when you have a reasonable thought process.",
            "Don't bluff — reasoning out loud is far better than guessing with false confidence.",
        )
    ),
)

val abbreviationTopics: List<LearnTopic> = listOf(
    LearnTopic(
        title = "Patient Status & Orders",
        systemImage = "list.clipboard",
        items = listOf(
            "NPO — nothing by mouth.",
            "PRN — as needed.",
            "DVT ppx — deep vein thrombosis prophylaxis.",
            "PO / IV / IM — by mouth / intravenous / intramuscular.",
            "I&O — intake and output.",
        )
    ),
    LearnTopic(
        title = "Vitals & Labs",
        systemImage = "waveform.path.ecg",
        items = listOf(
            "BP / HR / RR / SpO2 — blood pressure / heart rate / respiratory rate / oxygen saturation.",
            "Tmax — maximum recorded temperature.",
            "Hgb / Hct — hemoglobin / hematocrit.",
            "WBC — white blood cell count.",
            "Cr / BUN — creatinine / blood urea nitrogen (kidney function).",
            "Na / K — sodium / potassium.",
        )
    ),
    LearnTopic(
        title = "Perioperative",
        systemImage = "clock.arrow.circlepath",
        items = listOf(
            "Pre-op / intra-op / post-op — before, during, and after surgery.",
            "POD# — post-operative day number.",
            "EBL — estimated blood loss.",
            "NGT — nasogastric tube.",
            "Foley — indwelling urinary catheter.",
        )
    ),
    LearnTopic(
        title = "Documentation",
        systemImage = "doc.text",
        items = listOf(
            "H&P — history and physical.",
            "A&P — assessment and plan.",
            "ROS — review of systems.",
            "WNL — within normal limits.",
            "NKDA — no known drug allergies.",
            "c/o — complains of.",
            "s/p — status post (after a prior procedure or event).",
            "DC / D/C — discharge, or discontinue (context-dependent).",
        )
    ),
    LearnTopic(
        title = "OR-Specific",
        systemImage = "stethoscope",
        items = listOf(
            "Time-out — final safety check before incision (site, procedure, patient verification).",
            "Sterile field — the area maintained free of contamination during surgery.",
            "Circulator — the non-sterile OR nurse managing the room.",
            "Scrub tech/nurse — the sterile team member managing instruments.",
            "CVL / A-line — central venous line / arterial line.",
        )
    ),
)
