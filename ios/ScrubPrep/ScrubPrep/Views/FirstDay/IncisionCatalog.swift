// CLINICAL REVIEW NEEDED: every anatomic landmark, nerve/structure-at-risk, measurement,
// and complication statement below should be checked by someone with surgical training
// before release.

import Foundation

/// One incision in the Incisions reference (Learn tab). `alternateNames` are other names
/// you'll hear for it (`nil` if none). Written for recognition and discussion —
/// deliberately not operative technique.
struct Incision: Identifiable {
    let id = UUID()
    let name: String
    let alternateNames: String?
    /// One-line summary shown in the list row.
    let summary: String
    /// Plain-language description of where the incision runs.
    let description: String
    let commonlyUsedFor: [String]
    /// Layers, landmarks, and structures at risk.
    let anatomy: [String]
    /// Advantages and drawbacks compared with other approaches.
    let tradeoffs: [String]
    let questions: [QAPair]
    /// Empty until diagrams have been added for the incision.
    let diagrams: [LearnDiagram]
}

/// A body region grouping incisions on the Incisions screen, like `InstrumentCategory`.
struct IncisionRegion: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let incisions: [Incision]
}

let incisionRegions: [IncisionRegion] = [
    IncisionRegion(
        title: "Neck",
        systemImage: "person.bust",
        incisions: [
            Incision(
                name: "Collar incision",
                alternateNames: "transverse cervical, Kocher collar",
                summary: "A curved transverse incision in a low neck skin crease.",
                description: "A gently curved horizontal incision placed in a natural skin crease, about two fingerbreadths above the sternal notch.",
                commonlyUsedFor: [
                    "Thyroidectomy.",
                    "Parathyroidectomy.",
                ],
                anatomy: [
                    "The platysma is divided just under the skin, and flaps are raised above and below.",
                    "The strap muscles are separated in the midline to reach the thyroid, rather than cut.",
                    "The recurrent laryngeal nerves and the parathyroid glands lie close to the thyroid and are at risk.",
                ],
                tradeoffs: [
                    "Placed in a skin crease, so the scar is usually inconspicuous.",
                    "Exposure is limited for a goiter that extends down behind the sternum.",
                ],
                questions: [
                    QAPair(
                        question: "Which nerve is at risk in thyroidectomy, and what does injury cause?",
                        answer: "The recurrent laryngeal nerve. Injury to one causes hoarseness; injury to both can paralyze the vocal cords and obstruct the airway."
                    ),
                    QAPair(
                        question: "What muscle layer is divided just under the skin?",
                        answer: "The platysma."
                    ),
                ],
                diagrams: [LearnDiagram("incision-collar-neck")]
            ),
            Incision(
                name: "Carotid incision",
                alternateNames: "anterior sternocleidomastoid incision",
                summary: "Along the front edge of the sternocleidomastoid to expose the carotid.",
                description: "An oblique incision along the front (anterior) border of the sternocleidomastoid muscle on the side of the neck, centered over the carotid bifurcation.",
                commonlyUsedFor: [
                    "Carotid endarterectomy.",
                ],
                anatomy: [
                    "The facial vein is commonly divided to expose the carotid bifurcation beneath it.",
                    "The internal jugular vein and vagus nerve lie alongside the carotid in the carotid sheath.",
                    "Hypoglossal nerve — injury makes the tongue deviate toward the injured side.",
                    "Vagus and recurrent laryngeal nerve — injury causes hoarseness.",
                    "Marginal mandibular branch of the facial nerve — injury causes a drooping lower lip.",
                ],
                tradeoffs: [
                    "Gives direct, extendable exposure of the common, internal, and external carotid arteries.",
                    "Several cranial nerves are close by, so nerve injury is a key risk.",
                ],
                questions: [
                    QAPair(
                        question: "Which cranial nerve injury makes the tongue deviate, and to which side?",
                        answer: "The hypoglossal nerve (CN XII). The tongue deviates toward the side of the injury."
                    ),
                    QAPair(
                        question: "Which vein is usually divided to expose the carotid bifurcation?",
                        answer: "The facial vein."
                    ),
                ],
                diagrams: [LearnDiagram("incision-carotid")]
            ),
        ]
    ),
    IncisionRegion(
        title: "Chest",
        systemImage: "heart",
        incisions: [
            Incision(
                name: "Median sternotomy",
                alternateNames: "sternotomy",
                summary: "A vertical midline incision with the sternum divided.",
                description: "A vertical midline incision from just below the sternal notch to below the xiphoid. The sternum is divided lengthwise with a saw and spread with a retractor.",
                commonlyUsedFor: [
                    "Coronary artery bypass grafting (CABG) and valve surgery.",
                    "Anterior mediastinal surgery, such as thymectomy.",
                    "Heart and lung transplantation.",
                ],
                anatomy: [
                    "Beneath the sternum lie the thymus (or its fatty remnant), pericardium, and great vessels.",
                    "The internal thoracic (mammary) arteries run just beside the sternal edges and are commonly harvested for bypass grafts.",
                    "The sternum is closed with steel wires.",
                ],
                tradeoffs: [
                    "Excellent exposure of the heart and great vessels, and generally less painful than a thoracotomy.",
                    "Deep sternal wound infection (mediastinitis) is a serious complication; diabetes, obesity, and harvesting both internal thoracic arteries raise the risk.",
                ],
                questions: [
                    QAPair(
                        question: "How is the sternum closed after sternotomy?",
                        answer: "With steel wires."
                    ),
                    QAPair(
                        question: "What serious wound complication is associated with sternotomy?",
                        answer: "Deep sternal wound infection (mediastinitis), with a higher risk in patients with diabetes or obesity and when both internal thoracic arteries are harvested."
                    ),
                ],
                diagrams: [LearnDiagram("incision-median-sternotomy")]
            ),
            Incision(
                name: "Posterolateral thoracotomy",
                alternateNames: nil,
                summary: "A curved incision below the shoulder blade, with the patient on their side.",
                description: "With the patient in lateral decubitus, the incision curves from the front of the armpit area around below the tip of the shoulder blade and up between the shoulder blade and the spine. The chest is entered between two ribs.",
                commonlyUsedFor: [
                    "Open lung resection, such as lobectomy and pneumonectomy.",
                    "Esophageal and descending thoracic aortic surgery.",
                ],
                anatomy: [
                    "The latissimus dorsi is divided; the serratus anterior is often spared.",
                    "The chest is entered through an intercostal space — the fifth is common for lung resection.",
                    "The intercostal vein, artery, and nerve run along the lower border of each rib, so the chest is entered along the top of the rib below.",
                ],
                tradeoffs: [
                    "Excellent exposure of the lung, hilum, and posterior mediastinum.",
                    "One of the most painful incisions — epidurals or nerve blocks are commonly used — and it can affect shoulder function.",
                ],
                questions: [
                    QAPair(
                        question: "Why is the chest entered along the top of a rib?",
                        answer: "The intercostal vein, artery, and nerve run along the lower border of each rib, so staying on top of the rib below avoids them."
                    ),
                    QAPair(
                        question: "Which large back muscle is divided in a posterolateral thoracotomy?",
                        answer: "The latissimus dorsi."
                    ),
                ],
                diagrams: [LearnDiagram("incision-posterolateral-thoracotomy", caption: "Back view")]
            ),
            Incision(
                name: "Lateral thoracotomy",
                alternateNames: "muscle-sparing thoracotomy",
                summary: "A shorter incision on the side of the chest that spares the back muscles.",
                description: "With the patient in lateral decubitus, a shorter incision on the side of the chest, in front of the tip of the shoulder blade and roughly along the ribs. The chest is entered between two ribs, often the fourth or fifth intercostal space.",
                commonlyUsedFor: [
                    "Lung resection, such as lobectomy and wedge resection.",
                    "Converting a thoracoscopic (VATS) operation to an open one.",
                ],
                anatomy: [
                    "The latissimus dorsi is retracted rather than divided, and the serratus anterior is split along its fibers or retracted \u{2014} hence \u{201C}muscle-sparing.\u{201D}",
                    "The intercostal vein, artery, and nerve run along the lower border of each rib, so the chest is entered along the top of the rib below.",
                    "The long thoracic nerve runs down the side of the chest on the serratus anterior; injury causes a winged scapula.",
                ],
                tradeoffs: [
                    "Less pain and better shoulder function afterward than a posterolateral thoracotomy.",
                    "More limited exposure, especially of the back of the chest.",
                ],
                questions: [
                    QAPair(
                        question: "What makes a lateral thoracotomy \u{201C}muscle-sparing\u{201D}?",
                        answer: "The latissimus dorsi and serratus anterior are retracted or split along their fibers instead of being cut."
                    ),
                    QAPair(
                        question: "Which nerve on the side of the chest can be injured, and what's the sign?",
                        answer: "The long thoracic nerve, which supplies the serratus anterior. Injury causes a winged scapula."
                    ),
                ],
                diagrams: [LearnDiagram("incision-lateral-thoracotomy", caption: "Side view")]
            ),
            Incision(
                name: "Anterolateral thoracotomy",
                alternateNames: "resuscitative thoracotomy (in trauma)",
                summary: "A curved incision below the nipple line, with the patient on their back.",
                description: "A curved incision along the fourth or fifth intercostal space, below the nipple or in the fold under the breast, running from the edge of the sternum toward the side of the chest. The patient can stay supine.",
                commonlyUsedFor: [
                    "Resuscitative (emergency department) thoracotomy in trauma — on the left side.",
                    "Some minimally invasive valve and lung procedures.",
                ],
                anatomy: [
                    "The internal thoracic (mammary) artery runs just beside the sternal edge and must be controlled if divided.",
                    "The intercostal vessels and nerve run along the lower border of each rib.",
                    "It can be extended across the sternum to the other side (a \u{201C}clamshell\u{201D} incision) for wider exposure.",
                ],
                tradeoffs: [
                    "Fast, and doesn't require turning the patient — important in trauma.",
                    "More limited exposure than a posterolateral thoracotomy.",
                ],
                questions: [
                    QAPair(
                        question: "Why is a left anterolateral thoracotomy used for resuscitative thoracotomy?",
                        answer: "It's fast with the patient supine, and gives access to the heart to relieve tamponade and do cardiac massage, and to the descending aorta for cross-clamping."
                    ),
                    QAPair(
                        question: "What vessel runs just beside the sternal edge?",
                        answer: "The internal thoracic (internal mammary) artery."
                    ),
                ],
                diagrams: [LearnDiagram("incision-anterolateral-thoracotomy")]
            ),
        ]
    ),
    IncisionRegion(
        title: "Abdomen",
        systemImage: "figure.stand",
        incisions: [
            Incision(
                name: "Midline laparotomy",
                alternateNames: "full midline, exploratory laparotomy",
                summary: "A vertical midline incision through the linea alba.",
                description: "A vertical incision in the midline of the abdomen from near the xiphoid to near the pubis, curving around the umbilicus. It can be made shorter as an upper or lower midline.",
                commonlyUsedFor: [
                    "Trauma and emergency laparotomy.",
                    "Most major open abdominal surgery when wide exposure is needed.",
                ],
                anatomy: [
                    "Layers: skin, subcutaneous fat, linea alba, preperitoneal fat, and peritoneum.",
                    "The linea alba is where the aponeuroses of the abdominal wall muscles meet in the midline — it has few blood vessels.",
                ],
                tradeoffs: [
                    "Fast, nearly bloodless, gives access to the whole abdomen, and can be extended in either direction.",
                    "Compared with transverse incisions, it tends to cause more pain and breathing problems after surgery and has a higher risk of incisional hernia.",
                ],
                questions: [
                    QAPair(
                        question: "Why is a midline laparotomy used for trauma?",
                        answer: "It's fast, relatively bloodless, reaches every part of the abdomen, and can be extended as needed."
                    ),
                    QAPair(
                        question: "What layer is divided in the midline?",
                        answer: "The linea alba, where the abdominal wall aponeuroses meet."
                    ),
                ],
                diagrams: [LearnDiagram("incision-midline-laparotomy")]
            ),
            Incision(
                name: "Upper midline",
                alternateNames: nil,
                summary: "Midline from the xiphoid to the umbilicus.",
                description: "The upper portion of a midline laparotomy, running from the xiphoid down toward the umbilicus.",
                commonlyUsedFor: [
                    "Open surgery on the stomach, duodenum, pancreas, spleen, and liver.",
                ],
                anatomy: [
                    "Divides the linea alba between the two rectus muscles.",
                    "The xiphoid and costal margins limit exposure at the top.",
                ],
                tradeoffs: [
                    "Good exposure of the upper abdomen, and extendable downward.",
                    "Shares the midline's higher incisional hernia risk.",
                ],
                questions: [
                    QAPair(
                        question: "Which organs does an upper midline incision give access to?",
                        answer: "The upper abdominal organs — stomach, duodenum, pancreas, spleen, and liver."
                    ),
                ],
                diagrams: [LearnDiagram("incision-upper-midline")]
            ),
            Incision(
                name: "Lower midline",
                alternateNames: nil,
                summary: "Midline from the umbilicus toward the pubis.",
                description: "The lower portion of a midline laparotomy, running from the umbilicus down toward the pubic symphysis.",
                commonlyUsedFor: [
                    "Pelvic surgery — sigmoid colon and rectum, gynecologic, and bladder operations.",
                ],
                anatomy: [
                    "The bladder sits just behind the lower end, so it's emptied with a urinary catheter before surgery.",
                    "Below the arcuate line, the posterior rectus sheath is absent — only transversalis fascia and peritoneum lie behind the rectus muscles.",
                ],
                tradeoffs: [
                    "Good pelvic exposure, and extendable upward.",
                    "Shares the midline's higher incisional hernia risk.",
                ],
                questions: [
                    QAPair(
                        question: "Why does the patient have a urinary catheter for a lower midline incision?",
                        answer: "An empty bladder is less likely to be injured when entering the abdomen near the pubis."
                    ),
                ],
                diagrams: [LearnDiagram("incision-lower-midline")]
            ),
            Incision(
                name: "Kocher incision",
                alternateNames: "right subcostal",
                summary: "An oblique incision below and parallel to the right rib margin.",
                description: "An oblique incision about two fingerbreadths below the right costal margin, running parallel to it.",
                commonlyUsedFor: [
                    "Open cholecystectomy and bile duct surgery.",
                    "Liver surgery.",
                ],
                anatomy: [
                    "Divides the rectus and lateral abdominal wall muscles.",
                    "Intercostal nerves supplying the rectus cross the incision; dividing them can weaken or numb part of the abdominal wall.",
                ],
                tradeoffs: [
                    "Direct exposure of the gallbladder, bile ducts, and liver.",
                    "Cutting muscle and nerves can leave a weak, bulging area of the abdominal wall.",
                ],
                questions: [
                    QAPair(
                        question: "What is a Kocher incision used for?",
                        answer: "Right upper quadrant surgery — classically open cholecystectomy, as well as biliary and liver operations."
                    ),
                ],
                diagrams: [LearnDiagram("incision-kocher-subcostal")]
            ),
            Incision(
                name: "Chevron incision",
                alternateNames: "rooftop, bilateral subcostal",
                summary: "Right and left subcostal incisions joined in the midline.",
                description: "Two subcostal incisions below the right and left costal margins, joined across the midline in an inverted V, like a roof. Adding a vertical midline extension up toward the xiphoid makes a \u{201C}Mercedes\u{201D} incision.",
                commonlyUsedFor: [
                    "Major liver resection and liver transplantation.",
                    "Some pancreatic and bilateral adrenal operations.",
                ],
                anatomy: [
                    "Divides both rectus muscles and the lateral abdominal wall muscles on both sides.",
                ],
                tradeoffs: [
                    "Wide exposure of the entire upper abdomen.",
                    "A large, muscle-cutting incision, with more pain and wound complications.",
                ],
                questions: [
                    QAPair(
                        question: "What is a Mercedes incision?",
                        answer: "A chevron incision with an added vertical midline extension up toward the xiphoid, used for maximal upper abdominal exposure such as in liver transplantation."
                    ),
                ],
                diagrams: [LearnDiagram("incision-chevron")]
            ),
            Incision(
                name: "McBurney incision",
                alternateNames: "gridiron",
                summary: "An oblique right lower quadrant incision for open appendectomy.",
                description: "An oblique incision in the right lower quadrant through McBurney's point — one-third of the way from the anterior superior iliac spine to the umbilicus.",
                commonlyUsedFor: [
                    "Open appendectomy.",
                ],
                anatomy: [
                    "A muscle-splitting approach: the external oblique, internal oblique, and transversus abdominis are each separated along the direction of their fibers rather than cut.",
                ],
                tradeoffs: [
                    "Splitting rather than cutting muscle means less pain and a low hernia risk.",
                    "Limited exposure if the diagnosis turns out to be something other than appendicitis.",
                ],
                questions: [
                    QAPair(
                        question: "Where is McBurney's point?",
                        answer: "One-third of the way along a line from the anterior superior iliac spine to the umbilicus."
                    ),
                    QAPair(
                        question: "What does \u{201C}muscle-splitting\u{201D} mean here?",
                        answer: "Each abdominal wall muscle is separated along the direction of its fibers instead of being cut, which reduces pain and hernia risk."
                    ),
                ],
                diagrams: [LearnDiagram("incision-mcburney")]
            ),
            Incision(
                name: "Lanz incision",
                alternateNames: nil,
                summary: "A transverse right lower quadrant incision in a skin crease.",
                description: "A transverse incision in the right lower quadrant, placed lower and more horizontally than a McBurney incision, along a natural skin crease.",
                commonlyUsedFor: [
                    "Open appendectomy.",
                ],
                anatomy: [
                    "The same muscle-splitting approach as McBurney, through the external oblique, internal oblique, and transversus abdominis.",
                ],
                tradeoffs: [
                    "Follows a skin crease, so the scar is usually less noticeable than a McBurney scar.",
                    "Similar limited exposure to McBurney.",
                ],
                questions: [
                    QAPair(
                        question: "How does a Lanz incision differ from a McBurney incision?",
                        answer: "Lanz is transverse and placed in a skin crease, for a less visible scar; McBurney is oblique. Both split the muscles the same way."
                    ),
                ],
                diagrams: [LearnDiagram("incision-lanz")]
            ),
            Incision(
                name: "Pfannenstiel incision",
                alternateNames: "\u{201C}bikini\u{201D} incision",
                summary: "A curved transverse incision just above the pubic bone.",
                description: "A curved transverse incision about two fingerbreadths above the pubic symphysis, usually within the pubic hairline. The anterior rectus sheath is opened transversely and the rectus muscles are separated in the midline, not cut.",
                commonlyUsedFor: [
                    "Cesarean section and abdominal hysterectomy.",
                    "Bladder and prostate surgery.",
                    "Specimen extraction in laparoscopic colorectal surgery.",
                ],
                anatomy: [
                    "Ilioinguinal and iliohypogastric nerves near the lateral ends — injury can cause chronic pain or numbness.",
                    "The inferior epigastric vessels run behind the rectus muscles, toward the lateral ends.",
                    "The bladder lies just behind the lower end.",
                ],
                tradeoffs: [
                    "Well hidden cosmetically, strong when closed, and a low hernia risk.",
                    "Limited exposure of the upper abdomen.",
                ],
                questions: [
                    QAPair(
                        question: "Are the rectus muscles cut in a Pfannenstiel incision?",
                        answer: "No. The anterior rectus sheath is opened transversely and the rectus muscles are separated in the midline."
                    ),
                    QAPair(
                        question: "Which nerves can be injured at the lateral ends?",
                        answer: "The ilioinguinal and iliohypogastric nerves, which can cause chronic pain or numbness."
                    ),
                ],
                diagrams: [LearnDiagram("incision-pfannenstiel")]
            ),
        ]
    ),
    IncisionRegion(
        title: "Groin",
        systemImage: "figure.walk",
        incisions: [
            Incision(
                name: "Inguinal incision",
                alternateNames: "groin incision (hernia)",
                summary: "An oblique incision above and parallel to the inguinal ligament.",
                description: "An oblique incision a little above and parallel to the inguinal ligament, over the inguinal canal.",
                commonlyUsedFor: [
                    "Open inguinal hernia repair.",
                    "Radical orchiectomy for testicular cancer.",
                ],
                anatomy: [
                    "The external oblique aponeurosis is opened to reach the inguinal canal and spermatic cord (or round ligament).",
                    "Ilioinguinal nerve (running with the spermatic cord), iliohypogastric nerve, and the genital branch of the genitofemoral nerve — injury can cause chronic groin pain.",
                ],
                tradeoffs: [
                    "Direct access to the inguinal canal.",
                    "Chronic postoperative groin pain from nerve injury is a recognized complication.",
                ],
                questions: [
                    QAPair(
                        question: "Which nerve runs with the spermatic cord in the inguinal canal?",
                        answer: "The ilioinguinal nerve."
                    ),
                    QAPair(
                        question: "Why is testicular cancer removed through an inguinal rather than a scrotal incision?",
                        answer: "To avoid disrupting the scrotal skin and its lymphatic drainage, which could spread tumor to a different set of lymph nodes."
                    ),
                ],
                diagrams: [LearnDiagram("incision-inguinal")]
            ),
            Incision(
                name: "Longitudinal groin incision",
                alternateNames: "femoral cutdown, vertical groin incision",
                summary: "A vertical incision over the femoral artery below the inguinal ligament.",
                description: "A vertical incision over the femoral pulse, starting just above or at the inguinal ligament and extending down the upper thigh. The femoral artery lies at about the midpoint between the anterior superior iliac spine and the pubic symphysis.",
                commonlyUsedFor: [
                    "Femoral endarterectomy and bypass surgery.",
                    "Femoral artery exposure for embolectomy or large-bore devices.",
                ],
                anatomy: [
                    "From lateral to medial: femoral nerve, artery, vein, empty space, and lymphatics \u{2014} \u{201C}NAVEL.\u{201D}",
                    "Many lymph nodes and lymphatic channels cross this area.",
                ],
                tradeoffs: [
                    "Direct, extendable exposure of the common, superficial, and deep femoral arteries.",
                    "Groin wounds are prone to infection, seroma, and lymphatic leaks (lymphocele).",
                ],
                questions: [
                    QAPair(
                        question: "What is the order of structures in the femoral triangle?",
                        answer: "From lateral to medial: nerve, artery, vein, then empty space and lymphatics — \u{201C}NAVEL.\u{201D}"
                    ),
                    QAPair(
                        question: "What wound complications are common after groin incisions?",
                        answer: "Infection, seroma, and lymphatic leaks (lymphocele)."
                    ),
                ],
                diagrams: [LearnDiagram("incision-femoral-groin")]
            ),
        ]
    ),
    IncisionRegion(
        title: "Minimally invasive",
        systemImage: "circle.dotted",
        incisions: [
            Incision(
                name: "Laparoscopic port sites",
                alternateNames: "trocar sites (shown for cholecystectomy)",
                summary: "Several small incisions for a camera and instruments.",
                description: "Instead of one large incision, several small incisions let the surgeon place ports (trocars) for a camera and instruments. For a lap chole, there's typically one at the umbilicus for the camera, one in the upper midline, and two small ones below the right rib margin.",
                commonlyUsedFor: [
                    "Laparoscopic cholecystectomy (shown), appendectomy, hernia repair, colectomy, and many other abdominal operations.",
                ],
                anatomy: [
                    "The first port is placed by an open (Hasson) technique or with a Veress needle, then the abdomen is inflated with carbon dioxide.",
                    "Entry is the moment of highest risk for injury to bowel or major blood vessels.",
                    "The fascia at larger port sites (usually 10 mm or more) is often closed to prevent port-site hernias.",
                ],
                tradeoffs: [
                    "Less pain, smaller scars, shorter hospital stay, and faster recovery than open surgery.",
                    "Pneumoperitoneum affects breathing and blood pressure, and some patients can't tolerate it.",
                ],
                questions: [
                    QAPair(
                        question: "Why is carbon dioxide used to inflate the abdomen?",
                        answer: "It doesn't support combustion, and it's absorbed quickly by the blood, which lowers the risk of a dangerous gas embolism."
                    ),
                    QAPair(
                        question: "Which port sites usually have their fascia closed?",
                        answer: "Larger ports — usually 10 mm or more — to reduce the risk of a port-site hernia."
                    ),
                ],
                diagrams: [LearnDiagram("incision-laparoscopic-ports")]
            ),
            Incision(
                name: "VATS (three-port)",
                alternateNames: "video-assisted thoracoscopic surgery, anterior approach",
                summary: "Three small chest incisions for a camera and instruments.",
                description: "Video-assisted thoracoscopic surgery uses a camera and long instruments through small incisions between the ribs, with the patient in lateral decubitus. In the three-port anterior approach shown on the left chest: (a) a larger utility incision, higher and toward the front, for instruments and removing the specimen; (b) a camera port lower down; and (c) a posterior port for another instrument. Port number and placement vary by surgeon, procedure, and patient \u{2014} some surgeons use one or two ports, others more.",
                commonlyUsedFor: [
                    "Lung resection \u{2014} lobectomy, segmentectomy, and wedge resection or biopsy.",
                    "Pleural procedures, such as pleurodesis, decortication, and draining an effusion or empyema.",
                    "Some mediastinal operations, such as removing a mediastinal mass.",
                ],
                anatomy: [
                    "Each port goes through an intercostal space, along the top of the rib below, to avoid the intercostal vessels and nerve.",
                    "The lung on the operative side is collapsed with one-lung ventilation (a double-lumen tube or bronchial blocker), which creates room to work.",
                    "Pressure on the intercostal nerves at the port sites can cause chest wall pain or numbness afterward.",
                    "A chest tube is often placed through one of the port sites at the end.",
                ],
                tradeoffs: [
                    "Less pain, a shorter hospital stay, and a faster recovery than open thoracotomy.",
                    "Major bleeding or difficult anatomy may require converting to an open thoracotomy.",
                ],
                questions: [
                    QAPair(
                        question: "How does the surgeon get room to see inside the chest during VATS?",
                        answer: "One-lung ventilation collapses the lung on the operative side, using a double-lumen endotracheal tube or a bronchial blocker."
                    ),
                    QAPair(
                        question: "What happens if there's major bleeding during VATS?",
                        answer: "The surgeon converts to an open thoracotomy to control it."
                    ),
                ],
                diagrams: [LearnDiagram("incision-vats-three-port-ribs", caption: "Side view \u{2014} left chest")]
            ),
        ]
    ),
]

/// Incision topics common to all incisions, shown below the incision list.
let incisionGeneralTopics: [LearnTopic] = [
    LearnTopic(
        title: "Choosing an incision",
        systemImage: "arrow.triangle.branch",
        items: [
            "The surgeon weighs exposure, the ability to extend it, speed, pain, cosmetic result, and hernia risk.",
            "Vertical (midline) incisions are fast and extendable — the choice for emergencies and uncertain diagnoses.",
            "Transverse and oblique incisions tend to hurt less, affect breathing less, and follow skin tension lines for a better scar.",
        ]
    ),
    LearnTopic(
        title: "Abdominal wall layers",
        systemImage: "square.stack.3d.down.right",
        items: [
            "Skin, then subcutaneous fat (with Camper's and Scarpa's fascia).",
            "The anterior rectus sheath, rectus muscle, and posterior rectus sheath — or the external oblique, internal oblique, and transversus abdominis laterally.",
            "Transversalis fascia, preperitoneal fat, then peritoneum.",
            "Below the arcuate line, the posterior rectus sheath is absent.",
        ]
    ),
    LearnTopic(
        title: "Wound classification",
        systemImage: "cross.case",
        items: [
            "Clean — no entry into the respiratory, GI, or genitourinary tract (e.g., hernia repair).",
            "Clean-contaminated — controlled entry into those tracts (e.g., elective cholecystectomy).",
            "Contaminated — major spillage, or a fresh traumatic wound (e.g., gross spillage from the bowel).",
            "Dirty — established infection or perforation (e.g., perforated diverticulitis with abscess).",
            "Infection risk rises with each class.",
        ]
    ),
    LearnTopic(
        title: "Your role",
        systemImage: "hand.raised",
        items: [
            "Know the planned incision and the layers you'll go through before the case — it's a favorite pimp question.",
            "Check that the site is marked and confirmed during the time-out.",
            "Help with retraction and suction to keep the field visible.",
            "Learn the closure for each layer — students are often asked to help close the skin.",
        ]
    ),
]
