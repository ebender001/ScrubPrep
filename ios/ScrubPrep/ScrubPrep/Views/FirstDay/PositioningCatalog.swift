// CLINICAL REVIEW NEEDED: every nerve-injury, pressure-point, and physiologic statement
// below should be checked by someone with surgical training before release.

import Foundation

/// One patient position in the Positioning reference (Learn tab). `alternateNames` are
/// other names you'll hear for it (`nil` if none). Written for recognition and
/// discussion — deliberately not step-by-step positioning protocols.
struct PatientPosition: Identifiable {
    let id = UUID()
    let name: String
    let alternateNames: String?
    /// One-line summary shown in the list row.
    let summary: String
    /// Plain-language description of the position.
    let description: String
    let commonlyUsedFor: [String]
    let pressurePointsAndNerves: [String]
    /// Only effects that are commonly taught; empty when there's nothing notable.
    let physiologicEffects: [String]
    let howYouCanHelp: [String]
    let questions: [QAPair]
    /// Assets.xcassets image set name for a diagram — `nil` until one has been added.
    let diagramAssetName: String?
}

let patientPositions: [PatientPosition] = [
    PatientPosition(
        name: "Supine",
        alternateNames: "dorsal decubitus",
        summary: "Flat on the back — the most common surgical position.",
        description: "The patient lies flat on their back with the head in a neutral position. Arms are either out on padded armboards or tucked at the sides.",
        commonlyUsedFor: [
            "Most abdominal operations (open and laparoscopic).",
            "Neck, chest (sternotomy), breast, and many extremity procedures.",
        ],
        pressurePointsAndNerves: [
            "Pressure points: back of the head, shoulder blades, elbows, sacrum, and heels.",
            "Ulnar nerve at the elbow — the most commonly injured nerve from positioning. Pressure on the inside of the elbow is the usual cause.",
            "Brachial plexus — stretched if an arm on an armboard is abducted beyond 90 degrees.",
        ],
        physiologicEffects: [
            "Under general anesthesia, the abdominal contents push the diaphragm up, reducing lung volume (functional residual capacity).",
            "In late pregnancy, the uterus can compress the inferior vena cava and aorta, lowering blood pressure — the patient is tilted slightly to the left to relieve it.",
        ],
        howYouCanHelp: [
            "Armboards stay below 90 degrees, with palms up or facing the body.",
            "Heels are padded or floated off the table.",
            "The safety strap goes across the thighs, snug but not tight.",
            "Tucked arms sit at the sides with palms facing the body and fingers clear of the table's edges.",
        ],
        questions: [
            QAPair(
                question: "What's the most commonly injured nerve from positioning?",
                answer: "The ulnar nerve, usually from pressure on the inside of the elbow."
            ),
            QAPair(
                question: "Why keep armboards below 90 degrees?",
                answer: "Abducting the arm further stretches the brachial plexus, which can cause a nerve injury."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Trendelenburg",
        alternateNames: "head-down",
        summary: "Supine with the table tilted head-down.",
        description: "The patient is supine and the whole table is tilted so the head is lower than the feet. \u{201C}Steep\u{201D} Trendelenburg is a pronounced tilt used in some robotic pelvic cases.",
        commonlyUsedFor: [
            "Pelvic and lower abdominal laparoscopy — gravity moves the bowel out of the pelvis.",
            "Robotic prostatectomy and gynecologic surgery (often steep Trendelenburg).",
            "Central line placement in the neck, to fill the veins and lower the risk of air embolism.",
        ],
        pressurePointsAndNerves: [
            "The patient can slide toward the head. Shoulder braces used to prevent this can compress or stretch the brachial plexus.",
            "Swelling of the face, eyes, and airway during long, steep cases.",
        ],
        physiologicEffects: [
            "Abdominal contents push against the diaphragm, reducing lung compliance and raising airway pressures.",
            "Raises intracranial and intraocular pressure.",
            "The endotracheal tube can shift deeper into one main bronchus as the lungs move up.",
        ],
        howYouCanHelp: [
            "Before the table tilts, the team confirms the patient is secured against sliding.",
            "Arms are usually tucked. Keep fingers clear of the table's edges and breaks.",
            "Speak up if you notice the patient shifting once the table is tilted.",
        ],
        questions: [
            QAPair(
                question: "Why use Trendelenburg for pelvic laparoscopy?",
                answer: "Gravity pulls the bowel up out of the pelvis, improving the view of pelvic organs."
            ),
            QAPair(
                question: "What does steep Trendelenburg do to ventilation?",
                answer: "The abdominal contents push the diaphragm up, so the lungs are stiffer and airway pressures rise."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Reverse Trendelenburg",
        alternateNames: "head-up",
        summary: "Supine with the table tilted head-up.",
        description: "The patient is supine and the table is tilted so the head is higher than the feet. A footboard is often used so the patient doesn't slide down.",
        commonlyUsedFor: [
            "Upper abdominal laparoscopy — lap chole, foregut, and bariatric surgery — so the bowel falls away from the operative field.",
            "Head and neck surgery, such as thyroidectomy, to reduce venous congestion.",
        ],
        pressurePointsAndNerves: [
            "The patient can slide toward the feet, putting pressure on the heels and soles against a footboard.",
        ],
        physiologicEffects: [
            "Blood pools in the legs, reducing venous return and lowering blood pressure — more so with pneumoperitoneum.",
            "The diaphragm moves down, which can make ventilation easier, especially in patients with obesity.",
            "When the operative site is above the heart, an open vein can draw in air (venous air embolism).",
        ],
        howYouCanHelp: [
            "Sequential compression devices on the legs are usually on and running before the case starts.",
            "The team confirms the feet are supported before the table tilts.",
        ],
        questions: [
            QAPair(
                question: "Why use reverse Trendelenburg for a lap chole?",
                answer: "Gravity moves the bowel and omentum down and away from the gallbladder, improving exposure."
            ),
            QAPair(
                question: "What happens to blood pressure in reverse Trendelenburg?",
                answer: "It tends to fall, because blood pools in the legs and less returns to the heart."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Lithotomy",
        alternateNames: "low lithotomy (legs less elevated)",
        summary: "On the back with hips and knees flexed and legs up in stirrups.",
        description: "The patient is supine with the hips and knees flexed and the legs raised and apart, supported in stirrups — either \u{201C}candy-cane\u{201D} stirrups or padded boot stirrups. The buttocks sit at the edge of the table.",
        commonlyUsedFor: [
            "Gynecologic procedures, such as hysteroscopy and vaginal hysterectomy.",
            "Urologic procedures, such as cystoscopy and TURP.",
            "Anorectal surgery, and low lithotomy for colorectal cases like low anterior resection.",
        ],
        pressurePointsAndNerves: [
            "Common peroneal (fibular) nerve — compressed where it wraps around the fibular head against the stirrup, causing foot drop.",
            "Saphenous nerve along the inner knee, and the femoral and obturator nerves with excessive hip flexion or abduction.",
            "Sciatic nerve — stretched when the hip is flexed with the knee straight.",
            "Compartment syndrome of the lower legs in prolonged cases with the legs elevated.",
            "Fingers can be crushed in the table break when the foot of the bed is raised if the hands are at the sides.",
        ],
        physiologicEffects: [
            "Raising the legs returns blood to the central circulation; lowering them at the end can cause a sudden drop in blood pressure.",
            "The abdominal contents push up on the diaphragm, reducing lung volume.",
        ],
        howYouCanHelp: [
            "The legs are raised and lowered together, slowly, by two people — never one leg at a time.",
            "The outside of the knee is padded where it could rest against the stirrup.",
            "Keep the patient's hands and fingers clear of the table break.",
        ],
        questions: [
            QAPair(
                question: "Which nerve is at risk from stirrups, and what's the deficit?",
                answer: "The common peroneal nerve at the fibular head. Injury causes foot drop and numbness over the top of the foot."
            ),
            QAPair(
                question: "Why raise and lower the legs together?",
                answer: "Moving them separately can strain the hips and lower back, and lowering them quickly can drop the blood pressure suddenly."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Lateral decubitus",
        alternateNames: "lateral, \u{201C}right/left side down\u{201D}",
        summary: "Lying on one side with the operative side up.",
        description: "The patient lies on their side with the operative side facing up. The position is named for the side that's down — left lateral decubitus means lying on the left side. A beanbag or supports keep the patient stable, and the table may be flexed to open the space between the ribs and hip.",
        commonlyUsedFor: [
            "Thoracotomy and VATS (thoracoscopic) lung surgery.",
            "Kidney surgery, such as nephrectomy.",
            "Hip arthroplasty and some spine procedures.",
        ],
        pressurePointsAndNerves: [
            "Down-side brachial plexus and axillary vessels — protected by an axillary roll placed under the upper chest, just below the armpit (not in it).",
            "Down-side ear, shoulder, hip, outer knee, and ankle.",
            "Common peroneal nerve on the down-side leg at the fibular head.",
            "The down-side eye must be free of pressure.",
        ],
        physiologicEffects: [
            "Under general anesthesia with positive-pressure ventilation, the upper lung gets more ventilation while the lower lung gets more blood flow — a ventilation-perfusion mismatch.",
        ],
        howYouCanHelp: [
            "Help roll the patient as a unit when the team asks, following anesthesia's lead.",
            "A pillow or padding goes between the legs, with the head kept in line with the spine.",
            "Check that the down-side ear and eye aren't folded or pressed.",
        ],
        questions: [
            QAPair(
                question: "What's the axillary roll for, and where does it go?",
                answer: "It takes the patient's weight off the down-side shoulder to protect the brachial plexus and axillary vessels. It goes under the upper chest, just below the armpit — not in the armpit."
            ),
            QAPair(
                question: "In lateral decubitus under general anesthesia, which lung is better ventilated?",
                answer: "The upper (non-dependent) lung, while the lower lung gets more blood flow, creating a ventilation-perfusion mismatch."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Prone",
        alternateNames: "ventral decubitus",
        summary: "Face down, supported on chest and hip pads.",
        description: "The patient lies face down, with the chest and hips on padded supports or a spine frame so the abdomen hangs free. The face rests in a padded headrest or the head is held in pins, and the arms are either at the sides or up beside the head.",
        commonlyUsedFor: [
            "Spine surgery.",
            "Posterior fossa (back of the skull) neurosurgery.",
            "Procedures on the back of the body, such as Achilles tendon repair.",
        ],
        pressurePointsAndNerves: [
            "Eyes — direct pressure can cause blindness. Vision loss after long spine cases can also happen without direct pressure (ischemic optic neuropathy).",
            "Face, chin, nose, breasts, genitalia, iliac crests, and knees.",
            "Brachial plexus and ulnar nerves when the arms are up — the shoulders are kept below 90 degrees of abduction.",
        ],
        physiologicEffects: [
            "If the abdomen is compressed, pressure in the inferior vena cava rises — reducing venous return and increasing bleeding from spinal veins during spine surgery.",
            "With the abdomen hanging free, oxygenation is often as good or better than supine.",
            "The airway is hard to reach once the patient is prone, so the breathing tube is secured before turning.",
        ],
        howYouCanHelp: [
            "Help roll the patient from the stretcher to the table as a unit when asked, with anesthesia controlling the head and airway.",
            "Check that the abdomen hangs free and the eyes, breasts, and genitalia aren't compressed.",
            "Watch that lines and tubes don't catch or pull during the turn.",
        ],
        questions: [
            QAPair(
                question: "Why must the abdomen hang free in the prone position?",
                answer: "Compression raises pressure in the inferior vena cava, which lowers venous return and increases bleeding from the spinal veins."
            ),
            QAPair(
                question: "What serious eye complication is associated with prone spine surgery?",
                answer: "Postoperative vision loss — from direct pressure on the eye or from ischemic optic neuropathy in long cases."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Fowler's",
        alternateNames: "sitting position (its most upright form)",
        summary: "Sitting up with the head of the table raised about 45\u{2013}60 degrees.",
        description: "The patient sits up with the back of the table raised about 45\u{2013}60 degrees and the knees slightly bent. The fully upright \u{201C}sitting position\u{201D} used in some neurosurgery is its most extreme form, and beach chair is a variant used for shoulder surgery.",
        commonlyUsedFor: [
            "Sitting craniotomy for posterior fossa (back of the skull) lesions, and some cervical spine surgery \u{2014} less common today.",
            "Shoulder surgery, in its beach chair form.",
        ],
        pressurePointsAndNerves: [
            "Sacrum, buttocks, and heels bear the weight, and sliding down adds shearing force on the skin.",
            "Sciatic nerve \u{2014} stretched if the hips are flexed with the knees straight.",
            "In the sitting craniotomy, too much neck flexion can compromise blood flow to the cervical spinal cord and cause swelling of the tongue and airway.",
        ],
        physiologicEffects: [
            "Blood pools in the legs, reducing venous return and lowering blood pressure.",
            "The brain sits above the heart, so the pressure reaching it is lower than what's measured at the arm.",
            "The sitting craniotomy carries the classic highest risk of venous air embolism \u{2014} open veins in the surgical field sit well above the heart.",
            "The diaphragm moves down, which makes breathing easier.",
        ],
        howYouCanHelp: [
            "Supports under the knees and at the feet keep the patient from sliding down.",
            "The heels and buttocks are padded.",
            "The arms rest supported on pillows or the lap rather than hanging.",
        ],
        questions: [
            QAPair(
                question: "Which surgical position carries the classic highest risk of venous air embolism?",
                answer: "The sitting position for posterior fossa craniotomy \u{2014} open veins in the field are well above the heart, so air can be drawn in."
            ),
            QAPair(
                question: "What happens to blood pressure when a patient is sat up?",
                answer: "It tends to fall, because blood pools in the legs and less returns to the heart."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Semi-Fowler's",
        alternateNames: "head of bed up",
        summary: "Head of the table raised about 30\u{2013}45 degrees.",
        description: "A partly upright position: the back of the table is raised about 30\u{2013}45 degrees with the knees slightly bent. It's gentler than Fowler's and common both in and outside the OR.",
        commonlyUsedFor: [
            "Patients who can't lie flat, such as those with heart failure or obesity, during procedures under sedation.",
            "Breast reconstruction, when the patient is sat up during surgery to check symmetry.",
            "After surgery and in ventilated ICU patients, to reduce aspiration.",
        ],
        pressurePointsAndNerves: [
            "Sacrum and heels \u{2014} the patient tends to slide down, causing pressure and shearing on the skin.",
        ],
        physiologicEffects: [
            "Breathing is easier than lying flat, because the diaphragm moves down.",
            "Raising the head of the bed at least 30 degrees reduces aspiration and ventilator-associated pneumonia.",
            "Some blood pools in the legs, but less than in full Fowler's.",
        ],
        howYouCanHelp: [
            "A slight bend at the knees helps keep the patient from sliding down.",
            "The heels are padded or floated.",
        ],
        questions: [
            QAPair(
                question: "Why is the head of the bed kept up at least 30 degrees for ventilated patients?",
                answer: "It reduces the risk of aspiration and ventilator-associated pneumonia."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Beach chair",
        alternateNames: "semi-sitting, Fowler's variant",
        summary: "Sitting semi-upright, like in a lounge chair.",
        description: "The patient sits semi-upright with the hips and knees slightly flexed, and the head is held in a headrest. The operative shoulder hangs free off the side of the table.",
        commonlyUsedFor: [
            "Shoulder surgery, such as arthroscopy and rotator cuff repair.",
        ],
        pressurePointsAndNerves: [
            "Neck flexed or rotated too far in the headrest can stretch nerves in the neck and cause strain.",
            "Sciatic nerve if the hips are flexed with the knees straight.",
            "Sacrum, buttocks, and heels bear the weight.",
        ],
        physiologicEffects: [
            "Blood pools in the legs, which can lower blood pressure.",
            "The brain sits above the heart, so a blood pressure cuff on the arm overestimates the pressure reaching the brain — low blood pressure is especially dangerous in this position.",
            "With the operative site above the heart, an open vein can draw in air (venous air embolism).",
        ],
        howYouCanHelp: [
            "The head stays in a neutral position, not turned or flexed.",
            "The safety strap and supports keep the patient from sliding down.",
        ],
        questions: [
            QAPair(
                question: "Why is low blood pressure a particular concern in beach chair?",
                answer: "The brain is above the heart, so the pressure reaching it is lower than what's measured at the arm — hypotension can cause stroke or vision loss."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Jackknife",
        alternateNames: "prone jackknife, Kraske",
        summary: "Prone with the table flexed so the hips are the highest point.",
        description: "The patient is prone and the table is bent at the hips, so the hips are the highest point and the head and legs are lower. The buttocks are often taped apart for exposure.",
        commonlyUsedFor: [
            "Anorectal surgery, such as hemorrhoidectomy, fistula repair, and pilonidal cyst excision.",
        ],
        pressurePointsAndNerves: [
            "All the prone risks — eyes, face, breasts, genitalia, and knees.",
            "Lateral femoral cutaneous nerve at the front of the hip, where the hips rest on the table break, causing numbness of the outer thigh.",
        ],
        physiologicEffects: [
            "Like prone, abdominal compression reduces venous return.",
            "With the legs and head lower than the hips, blood can pool and blood pressure can fall.",
        ],
        howYouCanHelp: [
            "Help with the prone turn when asked, following anesthesia's lead.",
            "You may be asked to help tape the buttocks apart for exposure.",
            "Check the hips and knees are padded where they meet the table.",
        ],
        questions: [
            QAPair(
                question: "What kind of procedures use the jackknife position?",
                answer: "Anorectal procedures — it lifts and opens the buttocks for exposure of the anus and perianal area."
            ),
        ],
        diagramAssetName: nil
    ),
    PatientPosition(
        name: "Frog-leg",
        alternateNames: nil,
        summary: "On the back with knees bent and hips turned out.",
        description: "The patient is supine with the hips flexed and rotated outward and the knees bent, so the legs fall open like a frog's.",
        commonlyUsedFor: [
            "Harvesting the great saphenous vein for bypass surgery, since it exposes the inner thigh and leg.",
            "Perineal and genital procedures, and some pediatric urologic cases.",
        ],
        pressurePointsAndNerves: [
            "The outer knees need support — pressure there can affect the common peroneal nerve.",
            "The hips can be strained, especially in patients with hip disease or a hip replacement.",
        ],
        physiologicEffects: [],
        howYouCanHelp: [
            "Padding goes under the outer knees so the legs rest supported, not hanging.",
            "The legs are opened gently, without forcing the hips.",
        ],
        questions: [
            QAPair(
                question: "When might you see the frog-leg position in the OR?",
                answer: "During saphenous vein harvest for coronary bypass, and for perineal or genital procedures."
            ),
        ],
        diagramAssetName: nil
    ),
]

/// Positioning safety topics common to every position, shown below the position list.
let positioningSafetyTopics: [LearnTopic] = [
    LearnTopic(
        title: "Why positioning injuries happen",
        systemImage: "exclamationmark.triangle",
        items: [
            "Anesthetized patients can't feel discomfort or shift their weight, so pressure and stretch go unnoticed.",
            "Nerves are injured by compression and stretch; skin and muscle by prolonged pressure over bony prominences.",
            "Risk rises with long cases, very thin or heavy patients, and pre-existing conditions like diabetes or neuropathy.",
            "Injuries are often discovered only after the patient wakes up.",
        ]
    ),
    LearnTopic(
        title: "Nerves most often at risk",
        systemImage: "bolt.horizontal",
        items: [
            "Ulnar nerve — at the elbow.",
            "Brachial plexus — from arm abduction beyond 90 degrees, shoulder braces, or poor head position.",
            "Common peroneal nerve — at the fibular head, as in lithotomy or lateral positions.",
            "Sciatic, femoral, and lateral femoral cutaneous nerves — in lithotomy, prone, and jackknife positions.",
        ]
    ),
    LearnTopic(
        title: "Your role",
        systemImage: "hand.raised",
        items: [
            "Help with transfers and turns when asked — anesthesia controls the head and airway and calls the move.",
            "Keep the patient's hands and fingers clear of table breaks and edges.",
            "Watch that lines, catheters, and the breathing tube don't pull during moves.",
            "Before draping, look for padding at pressure points, arms at safe angles, the safety strap on, and eyes protected.",
            "Don't lean on the patient once they're draped — your weight is a pressure point too.",
            "If something looks wrong, say so. Positioning is everyone's responsibility.",
        ]
    ),
]
