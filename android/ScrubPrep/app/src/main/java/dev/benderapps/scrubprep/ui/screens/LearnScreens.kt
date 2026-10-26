package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Bed
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.ContentCut
import androidx.compose.material.icons.outlined.Healing
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.vector.ImageVector
import dev.benderapps.scrubprep.learn.EnergyDevice
import dev.benderapps.scrubprep.learn.Incision
import dev.benderapps.scrubprep.learn.Instrument
import dev.benderapps.scrubprep.learn.LearnDiagram
import dev.benderapps.scrubprep.learn.LearnSources
import dev.benderapps.scrubprep.learn.LearnTopic
import dev.benderapps.scrubprep.learn.PatientPosition
import dev.benderapps.scrubprep.learn.abbreviationTopics
import dev.benderapps.scrubprep.learn.energyDevices
import dev.benderapps.scrubprep.learn.energySafetyTopics
import dev.benderapps.scrubprep.learn.firstDayTopics
import dev.benderapps.scrubprep.learn.incisionGeneralTopics
import dev.benderapps.scrubprep.learn.incisionRegions
import dev.benderapps.scrubprep.learn.instrumentCategories
import dev.benderapps.scrubprep.learn.patientPositions
import dev.benderapps.scrubprep.learn.positioningSafetyTopics
import dev.benderapps.scrubprep.ui.components.Bullet
import dev.benderapps.scrubprep.ui.components.CardSurface
import dev.benderapps.scrubprep.ui.components.CardTitle
import dev.benderapps.scrubprep.ui.components.LearnSourceRow
import dev.benderapps.scrubprep.ui.components.LearnSourcesCard
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.ui.components.ScrollColumn
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.components.SectionCard
import dev.benderapps.scrubprep.ui.components.SectionHeading
import dev.benderapps.scrubprep.ui.components.iconForSymbol
import dev.benderapps.scrubprep.ui.components.openUrl
import androidx.compose.material.icons.outlined.ListAlt
import androidx.compose.material.icons.outlined.AccessibilityNew
import androidx.compose.material.icons.outlined.Warning
import androidx.compose.material.icons.outlined.MedicalServices
import androidx.compose.material.icons.outlined.Balance
import androidx.compose.material.icons.outlined.Air
import androidx.compose.material.icons.outlined.PanTool

// ---- Resources -------------------------------------------------------------------------

/** Looks up a drawable by its asset name (hyphens in the shared content map to underscores). */
@Composable
private fun drawableId(assetName: String): Int {
    val context = LocalContext.current
    return remember(assetName) {
        context.resources.getIdentifier(assetName.replace('-', '_'), "drawable", context.packageName)
    }
}

// ---- Learn tab -------------------------------------------------------------------------

/** The Learn tab: First Day content plus quick-reference screens. */
@Composable
fun LearnScreen(onNavigate: (String) -> Unit) {
    ScreenScaffold(title = "Learn") {
        Column(Modifier.verticalScroll(rememberScrollState())) {
            LearnSectionHeader("Getting Started")
            LearnRow("First day in the OR", "Rounds, scrubbing, OR etiquette, and presentations.", Icons.Outlined.AutoAwesome) { onNavigate(LearnRoutes.FirstDay) }
            LearnSectionHeader("Reference")
            LearnRow("Instruments 101", "Common instruments and what they're used for.", Icons.Outlined.ContentCut) { onNavigate(LearnRoutes.Instruments) }
            LearnRow("Abbreviations", "Common OR and surgical shorthand.", Icons.Outlined.Translate) { onNavigate(LearnRoutes.Abbreviations) }
            LearnRow("Energy devices", "Bovie, bipolar, vessel sealers, and what each is for.", Icons.Outlined.Bolt) { onNavigate(LearnRoutes.Energy) }
            LearnRow("Positioning", "Common patient positions and what to watch for.", Icons.Outlined.Bed) { onNavigate(LearnRoutes.Positioning) }
            LearnRow("Incisions", "Common incisions, what they're for, and what's underneath.", Icons.Outlined.Healing) { onNavigate(LearnRoutes.Incisions) }
            LearnSectionHeader("About this content")
            LearnRow("Sources & References", "Where this content comes from, with links.", Icons.AutoMirrored.Outlined.LibraryBooks) { onNavigate(LearnRoutes.Sources) }
        }
    }
}

object LearnRoutes {
    const val FirstDay = "firstDay"
    const val Instruments = "instruments"
    const val Abbreviations = "abbreviations"
    const val Energy = "energy"
    const val Positioning = "positioning"
    const val Incisions = "incisions"
    const val Sources = "sources"
}

@Composable
private fun LearnSectionHeader(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 4.dp),
    )
}

/** One Learn tab row: an accent-tinted icon beside a title and one-line description. */
@Composable
private fun LearnRow(title: String, subtitle: String, icon: ImageVector, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

// ---- Simple topic screens --------------------------------------------------------------

@Composable
private fun TopicSections(topics: List<LearnTopic>) {
    topics.forEach { SectionCard(it.title, iconForSymbol(it.systemImage), it.items) }
}

/** Static onboarding content for students new to the surgery rotation. */
@Composable
fun FirstDayScreen(onBack: () -> Unit) {
    ScreenScaffold(title = "First Day", onBack = onBack) {
        ScrollColumn {
            SecondaryText("Practical answers to what medical students worry about most before their first day on surgery.")
            TopicSections(firstDayTopics)
            LearnSourcesCard(LearnSources.firstDay)
        }
    }
}

/** A glossary of common OR and surgical abbreviations/shorthand. */
@Composable
fun AbbreviationsScreen(onBack: () -> Unit) {
    ScreenScaffold(title = "Abbreviations", onBack = onBack) {
        ScrollColumn {
            SecondaryText("Shorthand you'll hear on rounds and in the OR — and see in notes and orders.")
            TopicSections(abbreviationTopics)
            LearnSourcesCard(LearnSources.abbreviations)
        }
    }
}

/** Every Learn source in one place, grouped by screen. */
@Composable
fun LearnSourcesScreen(onBack: () -> Unit) {
    ScreenScaffold(title = "Sources & References", onBack = onBack) {
        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            item {
                SecondaryText(
                    "Learn content is written for medical students and reviewed by a surgeon. Case preparations, Quiz Me, and Rapid Fire are generated by AI for study — check them against these references and your clinical team.",
                )
            }
            LearnSources.all.forEach { (screen, sources) ->
                item {
                    CardSurface {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text(screen, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                            sources.forEach { LearnSourceRow(it) }
                        }
                    }
                }
            }
            item { SecondaryText(LearnSources.REVIEW_STATEMENT) }
        }
    }
}

// ---- Detail sheets ---------------------------------------------------------------------

/** A bottom sheet that opens expanded, with an opaque background and a scrolling body. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DetailSheet(onDismiss: () -> Unit, content: @Composable () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false),
        containerColor = MaterialTheme.colorScheme.background,
    ) {
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(start = 16.dp, end = 16.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) { content() }
    }
}

@Composable
private fun SheetTitle(name: String, secondary: String?) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
        if (secondary != null) SecondaryText(secondary)
    }
}

/** A diagram on a Learn detail sheet: optional caption above line art on a rounded card. */
@Composable
private fun DiagramView(diagram: LearnDiagram, subject: String) {
    val id = drawableId(diagram.assetName)
    if (id == 0) return
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        diagram.caption?.let {
            Text(it, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Image(
            painter = painterResource(id),
            contentDescription = "${diagram.caption?.let { "$it diagram" } ?: "Diagram"} of $subject",
            // Template rendering: the line art follows the text color in light and dark mode.
            colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.onSurface),
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surfaceContainer, RoundedCornerShape(16.dp))
                .padding(16.dp)
                // Caps tall (portrait) art such as incision body outlines so it doesn't fill the sheet.
                .heightIn(max = 240.dp),
        )
    }
}

// ---- Instruments -----------------------------------------------------------------------

/** A quick reference for the instruments most often called for during a case. */
@Composable
fun InstrumentsScreen(onBack: () -> Unit) {
    var selected by remember { mutableStateOf<Instrument?>(null) }
    ScreenScaffold(title = "Instruments 101", onBack = onBack) {
        ScrollColumn {
            SecondaryText("A quick reference for the instruments you'll hear called for most often.")
            instrumentCategories.forEach { category ->
                CardSurface {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        CardTitle(category.title, iconForSymbol(category.systemImage))
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            category.instruments.forEach { instrument ->
                                // Tappable (opening the detail sheet) only if there's at least one photo.
                                val tappable = instrument.images.isNotEmpty()
                                Row(
                                    Modifier.fillMaxWidth().then(if (tappable) Modifier.clickable { selected = instrument } else Modifier),
                                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                                ) {
                                    Bullet("${instrument.name} — ${instrument.description}", Modifier.weight(1f))
                                    if (tappable) {
                                        Icon(Icons.Outlined.Image, contentDescription = "Has photo", modifier = Modifier.padding(top = 3.dp).size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            LearnSourcesCard(LearnSources.instruments)
        }
    }
    selected?.let { instrument ->
        DetailSheet(onDismiss = { selected = null }) { InstrumentDetail(instrument) }
    }
}

@Composable
private fun InstrumentDetail(instrument: Instrument) {
    instrument.images.forEach { image ->
        val id = drawableId(image.assetName)
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            image.caption?.let {
                Text(it, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (id != 0) {
                Image(
                    painter = painterResource(id),
                    contentDescription = image.caption?.let { "${instrument.name}, $it" } ?: instrument.name,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)),
                )
            }
        }
    }
    Text(instrument.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
    SecondaryText(instrument.description)

    instrument.attribution?.let { attribution ->
        val context = LocalContext.current
        HorizontalDivider()
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row {
                Text("Image courtesy of ", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(attribution.sourceName, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                if (attribution.usedWithPermission) {
                    Text("Used with permission", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (attribution.usedWithPermission && attribution.productURL != null) {
                    Text("·", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                attribution.productURL?.let { url ->
                    Row(Modifier.clickable { openUrl(context, url) }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text("View at ${attribution.sourceName}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
                        Icon(Icons.AutoMirrored.Outlined.OpenInNew, contentDescription = null, modifier = Modifier.size(12.dp), tint = MaterialTheme.colorScheme.primary)
                    }
                }
            }
        }
    }
}

// ---- Positioning / Incisions / Energy devices ------------------------------------------

/** A list row with a name, optional secondary names, a one-line summary, and a chevron. */
@Composable
private fun ReferenceRow(name: String, secondary: String?, summary: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(Modifier.padding(top = 8.dp).size(5.dp).background(MaterialTheme.colorScheme.primary, CircleShape))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            if (secondary != null) {
                Text(secondary, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(summary, style = MaterialTheme.typography.bodyMedium)
        }
        Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = null, modifier = Modifier.padding(top = 2.dp).size(18.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** An orientation reference for common patient positions — each opens a detail sheet. */
@Composable
fun PositioningScreen(onBack: () -> Unit) {
    var selected by remember { mutableStateOf<PatientPosition?>(null) }
    ScreenScaffold(title = "Positioning", onBack = onBack) {
        ScrollColumn {
            SecondaryText("The positions you'll see most, what each is for, and what can go wrong.")
            CardSurface {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    CardTitle("Positions", Icons.Outlined.Bed)
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        patientPositions.forEach { ReferenceRow(it.name, it.alternateNames, it.summary) { selected = it } }
                    }
                }
            }
            SectionHeading("Positioning safety")
            TopicSections(positioningSafetyTopics)
            LearnSourcesCard(LearnSources.positioning)
        }
    }
    selected?.let { position ->
        DetailSheet(onDismiss = { selected = null }) { PositionDetail(position) }
    }
}

@Composable
private fun PositionDetail(position: PatientPosition) {
    SheetTitle(position.name, position.alternateNames)
    position.diagrams.forEach { DiagramView(it, "the ${position.name} position") }
    Text(position.description, style = MaterialTheme.typography.bodyMedium)
    SectionCard("Commonly used for", iconForSymbol("list.bullet.clipboard"), position.commonlyUsedFor)
    SectionCard("Pressure points and nerve risks", Icons.Outlined.Warning, position.pressurePointsAndNerves)
    if (position.physiologicEffects.isNotEmpty()) {
        SectionCard("Physiologic effects", Icons.Outlined.Air, position.physiologicEffects)
    }
    SectionCard("How you can help", Icons.Outlined.PanTool, position.howYouCanHelp)
    if (position.questions.isNotEmpty()) PrepLikelyQuestionsCard(position.questions, title = "What you might be asked")
}

/** Common surgical incisions, grouped by body region — each opens a detail sheet. */
@Composable
fun IncisionsScreen(onBack: () -> Unit) {
    var selected by remember { mutableStateOf<Incision?>(null) }
    ScreenScaffold(title = "Incisions", onBack = onBack) {
        ScrollColumn {
            SecondaryText("Where common incisions go, what they're used for, and what lies underneath.")
            incisionRegions.forEach { region ->
                CardSurface {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        CardTitle(region.title, iconForSymbol(region.systemImage))
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            region.incisions.forEach { ReferenceRow(it.name, it.alternateNames, it.summary) { selected = it } }
                        }
                    }
                }
            }
            SectionHeading("Incision basics")
            TopicSections(incisionGeneralTopics)
            LearnSourcesCard(LearnSources.incisions)
        }
    }
    selected?.let { incision ->
        DetailSheet(onDismiss = { selected = null }) { IncisionDetail(incision) }
    }
}

@Composable
private fun IncisionDetail(incision: Incision) {
    SheetTitle(incision.name, incision.alternateNames)
    incision.diagrams.forEach { DiagramView(it, "the ${incision.name}") }
    Text(incision.description, style = MaterialTheme.typography.bodyMedium)
    SectionCard("Commonly used for", iconForSymbol("list.bullet.clipboard"), incision.commonlyUsedFor)
    SectionCard("Anatomy and structures at risk", Icons.Outlined.Warning, incision.anatomy)
    SectionCard("Tradeoffs", Icons.Outlined.Balance, incision.tradeoffs)
    if (incision.questions.isNotEmpty()) PrepLikelyQuestionsCard(incision.questions, title = "What you might be asked")
}

/** The energy devices used in the OR — each opens a detail sheet — then safety topics common to all. */
@Composable
fun EnergyDevicesScreen(onBack: () -> Unit) {
    var selected by remember { mutableStateOf<EnergyDevice?>(null) }
    ScreenScaffold(title = "Energy devices", onBack = onBack) {
        ScrollColumn {
            SecondaryText("What each device does and when you'll see it — plus the safety issues they all share.")
            CardSurface {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    CardTitle("Devices", Icons.Outlined.Bolt)
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        energyDevices.forEach { ReferenceRow(it.name, it.brandNames, it.summary) { selected = it } }
                    }
                }
            }
            SectionHeading("Safety for all energy devices")
            TopicSections(energySafetyTopics)
            LearnSourcesCard(LearnSources.energyDevices)
        }
    }
    selected?.let { device ->
        DetailSheet(onDismiss = { selected = null }) { EnergyDeviceDetail(device) }
    }
}

@Composable
private fun EnergyDeviceDetail(device: EnergyDevice) {
    SheetTitle(device.name, device.brandNames)
    Text(device.howItWorks, style = MaterialTheme.typography.bodyMedium)
    SectionCard("When it's used", Icons.Outlined.MedicalServices, device.whenUsed)
    SectionCard("Safety", Icons.Outlined.Warning, device.safetyPoints)
    if (device.questions.isNotEmpty()) PrepLikelyQuestionsCard(device.questions, title = "What you might be asked")
}
