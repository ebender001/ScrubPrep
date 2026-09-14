import Foundation

/// The four bundled mock OR Preps (spec §22). Content mirrors what the real backend
/// generates, at the same student level and length.
extension ORPrep {
    static let mockLapChole = ORPrep(
        title: "Laparoscopic Cholecystectomy",
        caseSummary: "A patient with symptomatic gallstones or acute cholecystitis undergoing removal of the gallbladder.",
        whyOperating: [
            "Recurrent biliary colic from gallstones.",
            "Acute cholecystitis unresponsive to medical management.",
            "Prevent complications like gallstone pancreatitis or empyema.",
        ],
        anatomy: [
            "Gallbladder (fundus, body, infundibulum).",
            "Cystic duct and cystic artery.",
            "Common bile duct.",
            "Hepatocystic (Calot's) triangle.",
            "Liver edge and hepatic hilum.",
        ],
        operationOverview: [
            "Establish pneumoperitoneum and place trocars.",
            "Retract the gallbladder to expose Calot's triangle.",
            "Dissect to achieve the critical view of safety.",
            "Clip and divide the cystic duct and artery.",
            "Dissect the gallbladder off the liver bed.",
            "Remove the gallbladder in a retrieval bag.",
        ],
        thingsToWatch: [
            "Confirm the critical view of safety before clipping anything.",
            "Watch for aberrant biliary or vascular anatomy.",
            "Control bleeding from the cystic artery or liver bed.",
        ],
        complications: [
            "Bile duct injury from misidentified anatomy.",
            "Bleeding from the cystic artery.",
            "Bile leak from the cystic duct stump.",
        ],
        mustKnow: [
            "The critical view of safety prevents bile duct injury.",
            "The hepatocystic triangle is bounded by the cystic duct, common hepatic duct, and liver edge.",
            "Cystic artery usually arises from the right hepatic artery.",
            "Acute cholecystitis is usually from cystic duct obstruction by a stone.",
            "Bile duct injury is the most feared complication.",
        ],
        likelyQuestions: [
            QAPair(question: "What structures define the hepatocystic triangle?", answer: "Cystic duct, common hepatic duct, and the inferior liver edge."),
            QAPair(question: "What is the critical view of safety?", answer: "Clear identification of the cystic duct and artery before dividing them, with the gallbladder's lower third freed from the liver bed."),
            QAPair(question: "What artery supplies the gallbladder?", answer: "The cystic artery, typically a branch of the right hepatic artery."),
            QAPair(question: "What's the most feared complication?", answer: "Common bile duct injury from misidentified anatomy."),
        ]
    )

    static let mockAppendectomy = ORPrep(
        title: "Appendectomy",
        caseSummary: "A patient with acute appendicitis undergoing surgical removal of the appendix.",
        whyOperating: [
            "Definitive treatment for acute appendicitis.",
            "Prevent perforation, abscess, and peritonitis.",
        ],
        anatomy: [
            "Appendix and mesoappendix.",
            "Cecum and the convergence of the taeniae coli.",
            "Appendiceal artery (branch of the ileocolic artery).",
            "Terminal ileum and ileocecal valve.",
        ],
        operationOverview: [
            "Obtain access (laparoscopic ports or open incision).",
            "Identify the cecum and trace the taeniae to the appendiceal base.",
            "Divide the mesoappendix, controlling the appendiceal artery.",
            "Ligate and divide the appendiceal base.",
            "Remove the appendix and irrigate if contaminated.",
        ],
        thingsToWatch: [
            "Confirm the appendiceal base is completely resected.",
            "Look for perforation or abscess before closing.",
            "Control the appendiceal artery before it retracts.",
        ],
        complications: [
            "Intra-abdominal abscess.",
            "Wound infection.",
            "Stump leak.",
        ],
        mustKnow: [
            "The appendiceal base is always found where the three taeniae coli converge.",
            "Appendicitis presents with periumbilical pain migrating to the RLQ.",
            "The appendiceal artery runs in the mesoappendix.",
            "Perforation is the main risk of delayed treatment.",
            "Early appendectomy reduces complication rates.",
        ],
        likelyQuestions: [
            QAPair(question: "Where is the base of the appendix found?", answer: "At the cecum, where the three taeniae coli converge."),
            QAPair(question: "What artery supplies the appendix?", answer: "The appendiceal artery, a branch of the ileocolic artery."),
            QAPair(question: "What's the classic symptom progression?", answer: "Periumbilical pain migrating to the right lower quadrant, with fever and anorexia."),
            QAPair(question: "What's the main risk of untreated appendicitis?", answer: "Perforation leading to peritonitis or abscess."),
        ]
    )

    static let mockInguinalHernia = ORPrep(
        title: "Inguinal Hernia Repair",
        caseSummary: "A patient with a symptomatic or enlarging inguinal hernia undergoing surgical repair, often with mesh.",
        whyOperating: [
            "Symptomatic hernia (pain, discomfort with activity).",
            "Risk of incarceration or strangulation.",
            "Enlarging or reducible-but-bothersome hernia.",
        ],
        anatomy: [
            "Inguinal canal and floor.",
            "Spermatic cord (or round ligament) structures.",
            "Ilioinguinal and iliohypogastric nerves.",
            "Hesselbach's triangle for direct hernias.",
            "Deep and superficial inguinal rings.",
        ],
        operationOverview: [
            "Expose the inguinal canal (open) or the preperitoneal space (laparoscopic).",
            "Identify and preserve the spermatic cord structures and nerves.",
            "Reduce the hernia sac.",
            "Place and secure mesh to reinforce the floor.",
            "Close in layers.",
        ],
        thingsToWatch: [
            "Identify and protect the ilioinguinal and iliohypogastric nerves.",
            "Distinguish direct from indirect hernias relative to the inferior epigastric vessels.",
            "Avoid injury to the spermatic cord structures.",
        ],
        complications: [
            "Chronic groin pain (nerve injury or entrapment).",
            "Recurrence.",
            "Injury to the spermatic cord or vas deferens.",
        ],
        mustKnow: [
            "Indirect hernias pass lateral to the inferior epigastric vessels; direct hernias pass medial.",
            "Chronic pain from nerve injury is a major long-term complication.",
            "Mesh reinforces the floor and reduces recurrence.",
            "The spermatic cord must be identified and protected throughout.",
            "Hesselbach's triangle defines the location of direct hernias.",
        ],
        likelyQuestions: [
            QAPair(question: "How do you distinguish a direct from an indirect hernia intraoperatively?", answer: "Indirect hernias are lateral to the inferior epigastric vessels; direct hernias are medial."),
            QAPair(question: "What nerves are at risk during this repair?", answer: "The ilioinguinal and iliohypogastric nerves."),
            QAPair(question: "What are the borders of Hesselbach's triangle?", answer: "Inferior epigastric vessels, rectus sheath, and inguinal ligament."),
            QAPair(question: "What's the most common long-term complication?", answer: "Chronic groin pain from nerve injury or entrapment."),
        ]
    )

    static let mockRightColectomy = ORPrep(
        title: "Right Colectomy",
        caseSummary: "A patient with ascending colon cancer (or other right-sided colonic pathology) undergoing resection of the right colon.",
        whyOperating: [
            "Resection of colon cancer with oncologic margins.",
            "Management of complicated diverticulitis or other right-sided pathology.",
            "Obtain adequate lymph node harvest for staging.",
        ],
        anatomy: [
            "Ileocolic, right colic, and middle colic vessels.",
            "Right ureter and gonadal vessels (retroperitoneal structures at risk).",
            "Duodenum, adjacent to the mesentery of the right colon.",
            "Terminal ileum and ileocecal region.",
        ],
        operationOverview: [
            "Mobilize the right colon from lateral attachments.",
            "Identify and protect the duodenum and right ureter.",
            "Ligate the ileocolic and right colic vessels at their origin.",
            "Resect the specimen with adequate margins and lymph nodes.",
            "Perform an ileocolic anastomosis.",
        ],
        thingsToWatch: [
            "Identify the duodenum before dividing mesenteric vessels.",
            "Protect the right ureter and gonadal vessels during mobilization.",
            "Ensure adequate margins and lymph node harvest for cancer cases.",
        ],
        complications: [
            "Anastomotic leak.",
            "Injury to the duodenum or ureter.",
            "Bleeding from mesenteric vessels.",
        ],
        mustKnow: [
            "The ileocolic artery is the primary vessel supplying the right colon.",
            "The duodenum lies close to the mesentery and must be protected.",
            "Anastomotic leak is the most feared postoperative complication.",
            "Oncologic resection requires adequate margins and lymph node harvest.",
            "The right ureter is at risk during retroperitoneal mobilization.",
        ],
        likelyQuestions: [
            QAPair(question: "What vessel is ligated first in a right colectomy?", answer: "The ileocolic artery, typically ligated at its origin."),
            QAPair(question: "What structure is at risk near the mesentery during mobilization?", answer: "The duodenum."),
            QAPair(question: "What's the most feared postoperative complication?", answer: "Anastomotic leak."),
            QAPair(question: "What retroperitoneal structure must be identified to avoid injury?", answer: "The right ureter."),
        ]
    )
}
