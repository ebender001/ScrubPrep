package dev.benderapps.scrubprep.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Login
import androidx.compose.material.icons.outlined.AccessibilityNew
import androidx.compose.material.icons.outlined.Air
import androidx.compose.material.icons.automirrored.outlined.AltRoute
import androidx.compose.material.icons.outlined.Bed
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.CellTower
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.CleanHands
import androidx.compose.material.icons.outlined.Cloud
import androidx.compose.material.icons.outlined.ContentCut
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.automirrored.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.ElectricBolt
import androidx.compose.material.icons.outlined.Favorite
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Healing
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Layers
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.MedicalServices
import androidx.compose.material.icons.outlined.MonitorHeart
import androidx.compose.material.icons.outlined.PanTool
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.QuestionAnswer
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material.icons.outlined.RecordVoiceOver
import androidx.compose.material.icons.outlined.Balance
import androidx.compose.material.icons.outlined.UnfoldMore
import androidx.compose.material.icons.outlined.Warning
import androidx.compose.material.icons.outlined.WbTwilight
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Maps the iOS SF Symbol names the Learn content was authored with onto Material icons, so
 * the shared content needn't change. Unknown names fall back to a neutral icon.
 */
fun iconForSymbol(name: String): ImageVector = when (name) {
    "sunrise" -> Icons.Outlined.WbTwilight
    "person.wave.2" -> Icons.Outlined.RecordVoiceOver
    "arrow.right.square" -> Icons.AutoMirrored.Outlined.Login
    "hands.and.sparkles" -> Icons.Outlined.CleanHands
    "person.2.badge.gearshape" -> Icons.Outlined.Groups
    "questionmark.bubble" -> Icons.Outlined.QuestionAnswer
    "list.clipboard", "list.bullet.clipboard" -> Icons.Outlined.Checklist
    "waveform.path.ecg" -> Icons.Outlined.MonitorHeart
    "clock.arrow.circlepath" -> Icons.Outlined.History
    "doc.text" -> Icons.Outlined.Description
    "stethoscope", "cross.case" -> Icons.Outlined.MedicalServices
    "scissors" -> Icons.Outlined.ContentCut
    "hand.raised" -> Icons.Outlined.PanTool
    "exclamationmark.triangle" -> Icons.Outlined.Warning
    "scalemass" -> Icons.Outlined.Balance
    "figure.stand" -> Icons.Outlined.AccessibilityNew
    "figure.walk" -> Icons.AutoMirrored.Outlined.DirectionsWalk
    "flame" -> Icons.Outlined.LocalFireDepartment
    "bolt" -> Icons.Outlined.Bolt
    "bolt.horizontal" -> Icons.Outlined.ElectricBolt
    "bolt.heart" -> Icons.Outlined.MonitorHeart
    "heart", "heart.circle" -> Icons.Outlined.Favorite
    "link" -> Icons.Outlined.Link
    "dot.radiowaves.left.and.right" -> Icons.Outlined.CellTower
    "smoke" -> Icons.Outlined.Cloud
    "arrow.triangle.branch" -> Icons.AutoMirrored.Outlined.AltRoute
    "rectangle.expand.vertical" -> Icons.Outlined.UnfoldMore
    "square.stack.3d.down.right" -> Icons.Outlined.Layers
    "person.bust" -> Icons.Outlined.Person
    "lungs" -> Icons.Outlined.Air
    "bed.double" -> Icons.Outlined.Bed
    "bandage" -> Icons.Outlined.Healing
    "circle.dotted" -> Icons.Outlined.RadioButtonUnchecked
    else -> Icons.Outlined.Description
}
