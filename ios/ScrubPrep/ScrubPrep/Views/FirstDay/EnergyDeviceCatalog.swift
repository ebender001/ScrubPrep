// CLINICAL REVIEW NEEDED: every numeric and safety-critical statement below should be
// checked by someone with surgical training before release.

import Foundation

/// One device in the Energy devices reference (Learn tab). `name` is the generic name;
/// `brandNames` are common brand names/nicknames shown as secondary text (`nil` if none).
/// Orientation content for students — deliberately not operating instructions.
struct EnergyDevice: Identifiable {
    let id = UUID()
    let name: String
    let brandNames: String?
    /// One-line summary shown in the list row.
    let summary: String
    /// 2–3 plain-language sentences.
    let howItWorks: String
    let whenUsed: [String]
    let safetyPoints: [String]
    let questions: [QAPair]
}

let energyDevices: [EnergyDevice] = [
    EnergyDevice(
        name: "Monopolar electrosurgery",
        brandNames: "the \u{201C}Bovie\u{201D}",
        summary: "Cuts and coagulates using current that travels through the patient to a grounding pad.",
        howItWorks: "High-frequency electrical current flows from a small active tip, through the patient's body, to a large grounding (dispersive) pad and back to the generator. Because the tip is tiny, current is concentrated there and heats tissue; the large pad spreads the same current out so the skin under it stays cool.",
        whenUsed: [
            "Cut mode — a continuous, lower-voltage waveform that vaporizes cells for a clean incision with little hemostasis.",
            "Coag mode — an interrupted, higher-voltage waveform that heats tissue more slowly, sealing small vessels with more heat spread.",
            "Blend — a cut waveform with some interruption, to cut while providing some hemostasis.",
            "Fulguration — held just off the tissue in coag mode, it sparks across the gap to coagulate a broad surface superficially.",
            "Common uses: dissecting through fat and fascia, and stopping small bleeders.",
        ],
        safetyPoints: [
            "The grounding pad needs full contact on clean, dry, hair-free skin over a large, well-perfused muscle (such as the thigh), close to the operative site.",
            "Keep the pad away from bony prominences, scars, and metal implants. Poor contact concentrates current at the pad and can burn the skin.",
            "Current can take unintended paths (for example through ECG leads or skin touching metal), causing burns away from the operative site.",
            "In laparoscopy, damaged insulation or current coupling to nearby instruments can burn tissue outside the camera's view.",
            "The active pencil goes back in its insulated holster when not in use, not on the drapes.",
        ],
        questions: [
            QAPair(
                question: "Where does the grounding pad go, and why does placement matter?",
                answer: "On clean, dry, hair-free skin over a large, well-perfused muscle near the operative site, away from bone and metal implants. Good contact spreads the current out; poor contact concentrates it and can burn the skin under the pad."
            ),
            QAPair(
                question: "What's the difference between cut and coag?",
                answer: "Cut uses a continuous, lower-voltage waveform that vaporizes tissue with little hemostasis. Coag uses an interrupted, higher-voltage waveform that heats tissue more slowly, sealing small vessels but with more thermal spread."
            ),
        ]
    ),
    EnergyDevice(
        name: "Bipolar electrosurgery",
        brandNames: "bipolar forceps",
        summary: "Current passes only between the two tips of the forceps — no grounding pad.",
        howItWorks: "The two tips of the forceps are the two electrodes. Current flows from one tip to the other through only the tissue grasped between them, so it doesn't travel through the rest of the patient and no grounding pad is needed.",
        whenUsed: [
            "Precise coagulation of small vessels in delicate tissue.",
            "Near nerves and other critical structures — neurosurgery, ENT, plastic, hand, and eye surgery.",
            "When monopolar current through the body is undesirable, such as in patients with implanted cardiac devices.",
        ],
        safetyPoints: [
            "Heat still spreads a little beyond the tips, so nearby structures can be injured — just less than with monopolar.",
            "If the tips touch each other, current flows tip to tip and little tissue is coagulated.",
        ],
        questions: [
            QAPair(
                question: "Why doesn't bipolar need a grounding pad?",
                answer: "Both electrodes are in the forceps tips, so current completes its circuit through the tissue between them instead of through the patient's body."
            ),
            QAPair(
                question: "Why is bipolar preferred near nerves?",
                answer: "The current is confined to the tissue between the tips, so there's much less spread to surrounding structures than with monopolar."
            ),
        ]
    ),
    EnergyDevice(
        name: "Advanced bipolar vessel sealer",
        brandNames: "LigaSure, Enseal",
        summary: "Clamps and seals vessels with bipolar energy, then divides them with a built-in blade.",
        howItWorks: "The jaws compress the vessel while the generator delivers controlled bipolar energy, fusing the collagen and elastin in the vessel wall into a seal. The generator senses the tissue and stops when the seal is complete; a separate blade in the jaws then divides the sealed tissue.",
        whenUsed: [
            "Dividing mesentery, omentum, and vascular pedicles — especially in laparoscopic cases like colectomy, splenectomy, and hysterectomy.",
            "Sealing vessels up to about 7 mm in diameter, the limit most commonly cited for these devices.",
        ],
        safetyPoints: [
            "Sealing and cutting are separate steps — tissue is sealed first, then divided.",
            "The jaws stay hot briefly after activation and can injure tissue they touch.",
            "Heat spreads a short distance beyond the jaws, so they're kept away from bowel, ureter, and bile duct.",
            "Large, named vessels are often still controlled with clips, staples, or ties.",
        ],
        questions: [
            QAPair(
                question: "What's the difference between sealing and cutting with a vessel sealer?",
                answer: "Sealing uses compression plus bipolar energy to fuse the vessel wall; cutting is a separate step where a blade divides the tissue after it's sealed."
            ),
            QAPair(
                question: "Why might the surgeon still clip or staple a vessel?",
                answer: "If the vessel is larger than the device is meant to seal, or it's a major named vessel where the surgeon wants a more secure closure."
            ),
        ]
    ),
    EnergyDevice(
        name: "Ultrasonic device",
        brandNames: "Harmonic scalpel",
        summary: "Cuts and coagulates with high-frequency mechanical vibration, not electrical current.",
        howItWorks: "The active blade vibrates tens of thousands of times per second. The vibration breaks down proteins into a sticky coagulum that seals small vessels while the blade cuts, and no electrical current passes through the patient.",
        whenUsed: [
            "Dissecting and dividing tissue with small vessels, such as in thyroidectomy and laparoscopic colon and bariatric surgery.",
            "When electrical current through the patient is a concern, since no grounding pad or current path is involved.",
        ],
        safetyPoints: [
            "The active blade stays hot for a while after activation and can burn bowel or other tissue it touches.",
            "Heat still spreads beyond the jaws, so the device is kept away from critical structures.",
            "It produces a vapor/mist rather than the dense smoke of electrosurgery, but it isn't smoke-free.",
        ],
        questions: [
            QAPair(
                question: "How is an ultrasonic device different from electrosurgery?",
                answer: "It uses mechanical vibration to cut and coagulate rather than electrical current, so no current passes through the patient and no grounding pad is needed."
            ),
            QAPair(
                question: "Why be careful with the blade right after it's used?",
                answer: "The active blade stays hot after activation and can burn adjacent tissue, such as bowel, if it touches it."
            ),
        ]
    ),
    EnergyDevice(
        name: "Argon beam coagulator",
        brandNames: nil,
        summary: "Sprays current across a stream of argon gas to coagulate large oozing surfaces.",
        howItWorks: "A form of monopolar electrosurgery: a stream of argon gas carries current from the tip to the tissue without touching it, spreading energy evenly across a surface. The gas also blows blood off the surface, and the resulting coagulation is shallow.",
        whenUsed: [
            "Diffuse oozing from large raw surfaces, such as the liver or spleen after resection or trauma.",
        ],
        safetyPoints: [
            "Because it's monopolar, a grounding pad is still required.",
            "Argon gas can enter open vessels and cause a gas embolism, which can be fatal — a particular concern in laparoscopy, where the gas also adds to abdominal pressure.",
        ],
        questions: [
            QAPair(
                question: "When would the surgeon use the argon beam?",
                answer: "For diffuse surface bleeding over a large area, like oozing from the cut surface of the liver, where pinpoint coagulation isn't practical."
            ),
            QAPair(
                question: "What serious complication is associated with the argon beam?",
                answer: "Gas embolism — argon entering open blood vessels, which is especially a risk during laparoscopy."
            ),
        ]
    ),
]

/// Hazards common to all energy devices, shown below the device list.
let energySafetyTopics: [LearnTopic] = [
    LearnTopic(
        title: "OR fire",
        systemImage: "flame",
        items: [
            "Fire needs three things: an ignition source (energy devices), fuel (drapes, gauze, hair, alcohol prep), and an oxidizer (oxygen, nitrous oxide).",
            "Alcohol-based skin prep must dry completely before draping — commonly at least 3 minutes on hairless skin, and longer in hair. Pooled prep and trapped vapors are a fire risk.",
            "Oxygen near the airway is the highest-risk setting — head, neck, and face surgery with a mask or nasal cannula. Anesthesia lowers supplemental oxygen when possible.",
            "Fire risk is reviewed during the time-out.",
        ]
    ),
    LearnTopic(
        title: "Pacemakers and implanted devices",
        systemImage: "heart.circle",
        items: [
            "Monopolar current can be sensed by a pacemaker or ICD as heart activity, which can stop pacing or trigger an inappropriate shock.",
            "The team plans ahead — the device may be checked or reprogrammed before surgery.",
            "Bipolar or ultrasonic devices are often preferred, and the grounding pad is placed so current doesn't cross the device.",
            "Other implanted electronics, such as neurostimulators, need similar planning.",
        ]
    ),
    LearnTopic(
        title: "Surgical smoke",
        systemImage: "smoke",
        items: [
            "Smoke from energy devices contains chemicals and fine particles, and can carry viral material.",
            "Smoke evacuators capture it at the source; masks alone don't filter it well.",
        ]
    ),
    LearnTopic(
        title: "Lateral thermal spread",
        systemImage: "dot.radiowaves.left.and.right",
        items: [
            "Heat travels beyond the tip or jaws into nearby tissue — how far depends on the device, setting, and activation time.",
            "Structures at risk include bowel, ureter, bile duct, and nerves.",
            "Thermal injury may not be visible at the time and can show up days later, such as a delayed bowel perforation.",
        ]
    ),
]
