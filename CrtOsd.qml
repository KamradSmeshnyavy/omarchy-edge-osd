import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons

// crt: OSD райса Retro CRT (по мотивам shared/OsdShared.qml из github.com/elifouts/Dotfiles, GPL-3.0, с его темой
// Retro; облик — retro/osd-default.png; код свой). Внизу по центру плашка 300 × 50 на фоне темы (86 %), рамка 1 px
// цветом трубки на 45 %; значок слева тускло, шкала из клеток █ (горит — акцент, остальное — ░ на 18 %) с квадратным
// бегунком, показание справа («70%», MUTE). Без шкалы (Caps Lock, раскладка, медиа) — подпись капсом. Появляется как
// трубка: черта по центру → раскрытие по вертикали (его Tube.qml). Клики не перехватывает.
PanelWindow {
  id: so
  required property var osd   // корень Osd.qml: opened, icon, iconKey, value, maxValue, message, hasProgress
  property bool shown: false

  readonly property color acc: Commons.Color.accent
  readonly property color fg: Commons.Color.foreground
  readonly property color bg: Commons.Color.background
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }
  // шрифт и размер — свои из панели настроек (crt.json → ui, его retro.font / retro.size), иначе Terminess 14
  property string uiFont: ""
  property int uiSize: 0
  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/crt.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { try { var u = JSON.parse(text()).ui || {}; so.uiFont = String(u.font || ""); so.uiSize = Number(u.size) || 0 } catch (e) {} }
  }
  readonly property string term: uiFont !== "" ? uiFont : Qt.fontFamilies().indexOf("Terminess Nerd Font Mono") !== -1 ? "Terminess Nerd Font Mono" : "monospace"

  readonly property real full: osd.hasProgress ? 300 : Math.min(440, Math.max(220, 80 + label.implicitWidth))
  readonly property bool muted: /mute|off/.test(osd.iconKey)
  readonly property real frac: osd.hasProgress ? Math.max(0, Math.min(1, osd.value / Math.max(1, osd.maxValue))) : 0
  readonly property string readout: !osd.hasProgress ? "" : muted ? "MUTE" : String(osd.message || (Math.round(frac * 100) + "%")).toUpperCase()

  // t: 0 — нет, 1 — раскрыта (его Tube: 0..0.25 — черта растёт по ширине, дальше — раскрытие по высоте)
  property real t: 0
  readonly property real ys: Math.max(0.02, Math.min(1, (t - 0.25) / 0.75))
  readonly property real xs: Math.min(1, t * 4)
  onShownChanged: {
    if (shown) { closing.stop(); opening.from = t; opening.restart() }
    else { opening.stop(); closing.from = t; closing.restart() }
  }
  NumberAnimation { id: opening; target: so; property: "t"; to: 1; duration: 220; easing.type: Easing.OutCubic }
  NumberAnimation { id: closing; target: so; property: "t"; to: 0; duration: 160; easing.type: Easing.InCubic }

  visible: t > 0
  anchors { left: true; right: true; bottom: true }
  implicitHeight: 140
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  Item {
    id: card
    width: so.full
    height: 50
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 70

    Item {
      anchors.fill: parent
      opacity: so.t > 0.25 ? 1 : 0
      transform: Scale { origin.x: card.width / 2; origin.y: card.height / 2; yScale: so.ys }

      Rectangle {
        anchors.fill: parent
        color: so.a(so.bg, 0.86)
        border.width: 1
        border.color: so.a(so.acc, 0.45)
      }
      Text {
        id: icon
        anchors.left: parent.left; anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        horizontalAlignment: Text.AlignHCenter
        text: so.osd.icon
        font.family: so.term
        font.pixelSize: 14
        color: so.muted ? so.a(so.fg, 0.4) : so.a(so.acc, 0.8)
      }
      Text {
        id: value
        visible: so.osd.hasProgress
        anchors.right: parent.right; anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        horizontalAlignment: Text.AlignRight
        text: so.readout
        font.family: so.term
        font.pixelSize: 14
        font.letterSpacing: 1
        color: so.muted ? so.a(so.fg, 0.4) : so.acc
      }
      // шкала из клеток: горящие — акцент, бегунок — квадрат выше шкалы
      Item {
        id: track
        visible: so.osd.hasProgress
        anchors.left: icon.right; anchors.leftMargin: 16
        anchors.right: value.left; anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        height: 14
        readonly property int cells: Math.max(8, Math.floor(width / 5))
        readonly property int lit: Math.round(so.frac * cells)
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1
          Repeater {
            model: track.cells
            Rectangle {
              required property int index
              width: 4; height: 6
              color: index < track.lit ? (so.muted ? so.a(so.fg, 0.4) : so.acc) : so.a(so.acc, 0.18)
            }
          }
        }
        Rectangle {
          visible: track.lit > 0 && !so.muted
          x: Math.max(0, track.lit * 5 - 6)
          anchors.verticalCenter: parent.verticalCenter
          width: 8; height: 14
          color: so.acc
        }
      }
      Text {
        id: label
        visible: !so.osd.hasProgress
        anchors.left: icon.right; anchors.leftMargin: 16
        anchors.right: parent.right; anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: String(so.osd.message || "").toUpperCase()
        elide: Text.ElideRight
        font.family: so.term
        font.pixelSize: 14
        font.letterSpacing: 1
        color: so.fg
      }
    }
    // черта включения трубки
    Rectangle {
      visible: so.t < 0.999
      anchors.centerIn: parent
      width: parent.width * so.xs
      height: Math.max(2, parent.height * so.ys)
      color: so.acc
      opacity: Math.max(0, 1 - so.ys) * 0.9
    }
  }
}
