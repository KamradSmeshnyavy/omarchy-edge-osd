import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as Commons

// space: OSD райса Space (по мотивам shared/OsdShared.qml из github.com/elifouts/Dotfiles, GPL-3.0, с его темой Space:
// прямые углы, рамка акцентом 35 %, капс вразрядку; код свой). Внизу по центру квадратная «точка» 52 px поднимается
// снизу и раскрывается в плашку 300 px: значок акцентом, тонкая шкала с квадратным бегунком, показание справа
// («72%», MUTE). Без шкалы (Caps Lock, раскладка, медиа) — подпись вместо шкалы. Уголки 7 px акцентом, как у бара.
// Клики не перехватывает.
PanelWindow {
  id: so
  required property var osd   // корень Osd.qml: opened, icon, iconKey, value, maxValue, message, hasProgress
  property bool shown: false

  readonly property color acc: Commons.Color.accent
  readonly property color fg: Commons.Color.foreground
  readonly property color bg: Commons.Color.background
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }
  readonly property string mono: Qt.fontFamilies().indexOf("JetBrainsMono Nerd Font") !== -1 ? "JetBrainsMono Nerd Font" : "monospace"

  readonly property real dot: 52
  readonly property real full: osd.hasProgress ? 300 : Math.min(420, Math.max(240, 110 + label.implicitWidth))
  readonly property bool muted: /mute|off/.test(osd.iconKey)
  readonly property real frac: osd.hasProgress ? Math.max(0, Math.min(1, osd.value / Math.max(1, osd.maxValue))) : 0
  readonly property string readout: !osd.hasProgress ? "" : muted ? "MUTE" : String(osd.message || (Math.round(frac * 100) + "%")).toUpperCase()

  // t: 0 — спрятана под краем, 1 — раскрыта (его MorphShared: открытие 480 мс, закрытие 340)
  property real t: 0
  readonly property real w: Math.max(0, (t - 0.2) / 0.8)
  function stage(from) { return Math.max(0, Math.min(1, (t - from) / (1 - from))) }
  onShownChanged: {
    if (shown) { closing.stop(); opening.from = t; opening.restart() }
    else { opening.stop(); closing.from = t; closing.restart() }
  }
  NumberAnimation { id: opening; target: so; property: "t"; to: 1; duration: 480; easing.type: Easing.OutCubic }
  NumberAnimation { id: closing; target: so; property: "t"; to: 0; duration: 340; easing.type: Easing.InCubic }
  property real shownFrac: frac
  Behavior on shownFrac { enabled: so.t > 0.5; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

  visible: t > 0
  anchors { left: true; right: true; bottom: true }
  implicitHeight: 160
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  Item {
    id: card
    width: so.dot + (so.full - so.dot) * so.w
    height: so.dot
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 76 - 132 * (1 - so.t)
    opacity: Math.min(1, so.t * 8)

    Rectangle {
      anchors.fill: parent
      color: so.a(so.bg, 0.82)
      border.width: 1
      border.color: so.a(so.acc, 0.35)
    }
    // уголки 7 px акцентом
    Repeater {
      model: 4
      Item {
        required property int index
        x: index % 2 ? card.width - 7 : 0
        y: index > 1 ? card.height - 7 : 0
        width: 7; height: 7
        Rectangle { width: 7; height: 1; y: parent.index > 1 ? 6 : 0; color: so.acc }
        Rectangle { width: 1; height: 7; x: parent.index % 2 ? 6 : 0; color: so.acc }
      }
    }

    Text {
      id: icon
      anchors.left: parent.left
      anchors.leftMargin: 15
      anchors.verticalCenter: parent.verticalCenter
      width: 22
      horizontalAlignment: Text.AlignHCenter
      text: so.osd.icon
      font.family: so.mono
      font.pixelSize: 18
      color: so.muted ? so.a(so.fg, 0.4) : so.acc
      scale: 0.75 + 0.25 * so.stage(0.1)
    }

    Text {
      id: value
      visible: so.osd.hasProgress && so.stage(0.55) > 0
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      width: 48
      horizontalAlignment: Text.AlignRight
      text: so.readout
      font.family: so.mono
      font.pixelSize: 13
      font.letterSpacing: 1.6
      color: so.muted ? so.a(so.fg, 0.4) : so.fg
      opacity: so.stage(0.55)
      transform: Translate { x: 6 * (1 - so.stage(0.55)) }
    }

    // шкала: 3 px, бегунок — квадрат 9 px
    Rectangle {
      visible: so.osd.hasProgress && so.stage(0.5) > 0
      anchors.left: icon.right
      anchors.leftMargin: 14
      anchors.right: value.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      height: 3
      color: so.a(so.fg, 0.16)
      opacity: so.stage(0.5)
      Rectangle {
        height: parent.height
        width: parent.width * so.shownFrac
        color: so.muted ? so.a(so.fg, 0.4) : so.acc
        Rectangle {
          visible: so.shownFrac > 0.01 && !so.muted
          anchors.verticalCenter: parent.verticalCenter
          width: 9; height: 9
          x: parent.width - width / 2
          color: so.acc
        }
      }
    }

    Text {
      id: label
      visible: !so.osd.hasProgress && so.stage(0.5) > 0
      anchors.left: icon.right
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      text: String(so.osd.message || "").toUpperCase()
      elide: Text.ElideRight
      font.family: so.mono
      font.pixelSize: 13
      font.letterSpacing: 1.6
      color: so.fg
      opacity: so.stage(0.5)
      transform: Translate { x: -6 * (1 - so.stage(0.5)) }
    }
  }
}
