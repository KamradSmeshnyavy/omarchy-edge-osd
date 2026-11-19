import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as Commons

// modern: OSD райса Modern (по мотивам shared/OsdShared.qml из github.com/elifouts/Dotfiles, GPL-3.0, с его темой
// Modern; облик — v2/osd-default.png; код свой). Внизу по центру скруглённая плашка 340 × 60 матового стекла (фон темы
// на 85 %, тонкая окантовка); значок акцентом, шкала 4 px акцентом с круглым бегунком, показание справа («90%», MUTE).
// Без шкалы — подпись. Появляется, поднимаясь снизу с затуханием. Клики не перехватывает.
PanelWindow {
  id: so
  required property var osd
  property bool shown: false

  readonly property color acc: Commons.Color.accent
  readonly property color fg: Commons.Color.foreground
  readonly property color bg: Commons.Color.background
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }
  readonly property string ui: Qt.fontFamilies().indexOf("CodeNewRoman Nerd Font Propo") !== -1 ? "CodeNewRoman Nerd Font Propo"
    : Qt.fontFamilies().indexOf("JetBrainsMono Nerd Font") !== -1 ? "JetBrainsMono Nerd Font" : "monospace"
  readonly property bool muted: /mute|off/.test(osd.iconKey)
  readonly property real frac: osd.hasProgress ? Math.max(0, Math.min(1, osd.value / Math.max(1, osd.maxValue))) : 0
  readonly property string readout: !osd.hasProgress ? "" : muted ? "MUTE" : String(osd.message || (Math.round(frac * 100) + "%"))

  property real t: 0
  onShownChanged: { if (shown) { closing.stop(); opening.from = t; opening.restart() } else { opening.stop(); closing.from = t; closing.restart() } }
  NumberAnimation { id: opening; target: so; property: "t"; to: 1; duration: 260; easing.type: Easing.OutCubic }
  NumberAnimation { id: closing; target: so; property: "t"; to: 0; duration: 200; easing.type: Easing.InCubic }
  property real shownFrac: frac
  Behavior on shownFrac { enabled: so.t > 0.5; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

  visible: t > 0
  anchors { left: true; right: true; bottom: true }
  implicitHeight: 140
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  Rectangle {
    id: card
    width: so.osd.hasProgress ? 340 : Math.min(460, Math.max(220, 90 + label.implicitWidth))
    height: 60
    radius: 14
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 50 - 24 * (1 - so.t)
    opacity: so.t
    color: so.a(so.bg, 0.85)
    border.width: 1
    border.color: so.a(so.fg, 0.08)

    Text {
      id: icon
      x: 22; anchors.verticalCenter: parent.verticalCenter
      text: so.osd.icon
      font.family: so.ui; font.pixelSize: 20
      color: so.muted ? so.a(so.fg, 0.4) : so.acc
    }
    Text {
      id: value
      visible: so.osd.hasProgress
      anchors.right: parent.right; anchors.rightMargin: 22
      anchors.verticalCenter: parent.verticalCenter
      text: so.readout
      font.family: so.ui; font.pixelSize: 15
      color: so.a(so.fg, 0.75)
    }
    Rectangle {
      visible: so.osd.hasProgress
      anchors.left: icon.right; anchors.leftMargin: 18
      anchors.right: value.left; anchors.rightMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      height: 4; radius: 2
      color: so.a(so.fg, 0.12)
      Rectangle {
        height: parent.height; radius: 2
        width: parent.width * so.shownFrac
        color: so.muted ? so.a(so.fg, 0.4) : so.acc
        Rectangle {
          visible: !so.muted
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - width / 2
          width: 12; height: 12; radius: 6
          color: so.acc
        }
      }
    }
    Text {
      id: label
      visible: !so.osd.hasProgress
      anchors.left: icon.right; anchors.leftMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      text: String(so.osd.message || "")
      font.family: so.ui; font.pixelSize: 14
      color: so.fg
    }
  }
}
