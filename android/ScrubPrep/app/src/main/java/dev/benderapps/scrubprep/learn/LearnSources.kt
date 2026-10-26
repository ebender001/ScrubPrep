package dev.benderapps.scrubprep.learn

/**
 * Sources for each Learn screen, shown in that screen's sources card and all together in the
 * Sources & References screen. Every link was checked to open and to cover the screen's topics.
 */
object LearnSources {
    /** Shown with every source list and on the AI-content note. */
    const val REVIEW_STATEMENT = "Reviewed by Edward M. Bender, MD, FACS. For education only — confirm with these sources and your clinical team."

    val firstDay: List<LearnSource> = listOf(
            source(
                "Student-Informed Guidelines on Preparing for the Core Surgery Clerkship",
                "American College of Surgeons, RISE",
                "https://www.facs.org/for-medical-professionals/news-publications/journals/rise/articles/student-informed-guidelines-on-preparing-for-the-core-surgery-clerkship/"
            ),
            source(
                "Expectations for Oral Case Presentations for Clinical Clerks",
                "J Gen Intern Med, 2009",
                "https://pmc.ncbi.nlm.nih.gov/articles/PMC2642568/"
            ),
            source("Sterile Technique", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK459175/"),
            source("Hand Hygiene in Clinical Practice", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK470254/"),
            source(
                "Prevention of Surgical Errors (Universal Protocol and time-out)",
                "StatPearls, NCBI Bookshelf",
                "https://www.ncbi.nlm.nih.gov/books/NBK592394/"
            ),
        )

    val instruments: List<LearnSource> = listOf(
            source("Surgical instrument catalog", "Scanlan International", "https://www.scanlaninternational.com"),
        )

    val abbreviations: List<LearnSource> = listOf(
            source("Appendix B: Some Common Abbreviations", "MedlinePlus, National Library of Medicine", "https://medlineplus.gov/appendixb.html"),
            source(
                "Do Not Use List of Abbreviations",
                "The Joint Commission",
                "https://www.jointcommission.org/en-us/knowledge-library/support-center/standards-interpretation/do-not-use-list-of-abbreviations"
            ),
        )

    val energyDevices: List<LearnSource> = listOf(
            source(
                "Principles and Safety Measures of Electrosurgery in Laparoscopy",
                "JSLS, 2012",
                "https://pmc.ncbi.nlm.nih.gov/articles/PMC3407433/"
            ),
            source("Electrosurgery", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK482380/"),
            source(
                "Practice Advisory for the Prevention and Management of Operating Room Fires",
                "American Society of Anesthesiologists, Anesthesiology, 2013",
                "https://doi.org/10.1097/ALN.0b013e31827773d2"
            ),
            source("Surgical Fire Safety", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK544303/"),
            source(
                "Practice Advisory for the Perioperative Management of Patients with Cardiac Implantable Electronic Devices",
                "American Society of Anesthesiologists, Anesthesiology, 2020",
                "https://doi.org/10.1097/ALN.0000000000003217"
            ),
            source(
                "Surgical Smoke Inhalation: Dangerous Consequences for the Surgical Team",
                "NIOSH, Centers for Disease Control and Prevention, 2020",
                "https://www.cdc.gov/niosh/bulletin/2020/surgical-smoke.html"
            ),
            source(
                "Venous Gas Embolism Associated with Argon-Enhanced Coagulation of the Liver",
                "J Invest Surg, 1993",
                "https://pubmed.ncbi.nlm.nih.gov/8292567/"
            ),
        )

    val positioning: List<LearnSource> = listOf(
            source("Anatomy, Patient Positioning", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK513320/"),
            source(
                "Practice Advisory for the Prevention of Perioperative Peripheral Neuropathies",
                "American Society of Anesthesiologists, Anesthesiology, 2018",
                "https://doi.org/10.1097/ALN.0000000000001937"
            ),
            source(
                "Patient Positioning During Minimally Invasive Surgery: What Is Current Best Practice?",
                "Robotic Surgery: Research and Reviews, 2017",
                "https://pmc.ncbi.nlm.nih.gov/articles/PMC6193419/"
            ),
        )

    val incisions: List<LearnSource> = listOf(
            source("Surgical Access Incisions", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK541018/"),
            source("Anatomy, Abdomen and Pelvis: Abdominal Wall", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK551649/"),
            source("Laparotomy", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK525961/"),
            source("Wound Classification", "StatPearls, NCBI Bookshelf", "https://www.ncbi.nlm.nih.gov/books/NBK554456/"),
        )

    /** Every screen's sources, in Learn tab order, for the Sources & References screen. */
    val all: List<Pair<String, List<LearnSource>>> = listOf(
        "First Day in the OR" to firstDay,
        "Instruments 101" to instruments,
        "Abbreviations" to abbreviations,
        "Energy Devices" to energyDevices,
        "Positioning" to positioning,
        "Incisions" to incisions,
    )

    private fun source(title: String, detail: String, url: String) = LearnSource(title, detail, url)
}
