import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as Commons

// vitreus: OSD райса Vitreus (по pages/osd_drawer.plm из github.com/natepayn3/Vitreus, MIT; код свой). Капля-ящик
// растёт влево из правой кромки рамки, на 24 px выше низа рабочей области, одним куском стекла с рамкой (у пластиковых
// основ — сплошная заливка с контуром и вогнутыми изгибами у кромки). В нём плашка 316 px: вуаль 8 % и волосяной контур,
// слева плитка 44 px со значком, «карандашный» слайдер 170 px (контур-пилюля, уровень заштрихован акцентом, кольцо-бегунок),
// справа процент Space Grotesk 21/700 («Muted» — блёкло). Без шкалы — подпись. Пружины и рябь — DripMotion.
PanelWindow {
  id: vo
  required property var osd
  required property var style          // BarStyle.qml
  property bool shown: false

  readonly property color ink: Commons.Color.foreground
  readonly property color mint: Commons.Color.accent
  readonly property color bg: Commons.Color.background
  readonly property color faint: Qt.rgba(ink.r, ink.g, ink.b, 0.5)
  function a(c, k) { return Qt.rgba(c.r, c.g, c.b, k) }
  readonly property string font: Qt.fontFamilies().indexOf("Space Grotesk") !== -1 ? "Space Grotesk" : Commons.Style.font.family
  readonly property bool muted: /mute|off/.test(osd.iconKey) || (osd.hasProgress && osd.value <= 0 && /volume|audio|sink/.test(osd.iconKey))
  readonly property real frac: osd.hasProgress ? Math.max(0, Math.min(1, osd.value / Math.max(1, osd.maxValue))) : 0
  readonly property string readout: muted ? "Muted" : String(osd.message || (Math.round(frac * 100) + "%"))
  readonly property bool plastic: style.plastic
  readonly property real sq: style.squareness

  // ── кромка: правая сторона рабочей области (рамка или бар справа) ──
  MergeInfo { id: mi }
  readonly property real sw: screen ? screen.width : width
  readonly property real sh: screen ? screen.height : height
  readonly property real insetR: String(mi.g.position) === "right" ? Number(mi.g.barSize) || 0 : mi.framed ? Number(mi.g.frameWidth) || 0 : 0
  readonly property real insetB: String(mi.g.position) === "bottom" ? Number(mi.g.barSize) || 0 : mi.framed ? Number(mi.g.frameWidth) || 0 : 0
  readonly property bool merge: mi.has("right")
  readonly property real inner: sw - insetR
  readonly property real gapR: merge ? 0 : 12

  // ── размеры (как у него: плашка 316 × 64, ящик на 12 больше со всех сторон) ──
  readonly property real plateW: 316
  readonly property real plateH: 64
  readonly property real bodyW: plateW + 24
  readonly property real bodyH: plateH + 24
  readonly property real bodyR: 26 * (1 - 0.73 * sq)
  readonly property rect endRect: Qt.rect(inner - gapR - bodyW, sh - insetB - 24 - bodyH, bodyW, bodyH)

  DripMotion {
    id: drop
    active: true
    motion: Math.max(0.05, vo.style.motion)
    revealDelay: 140
    revealDuration: 220
    screenName: vo.screen ? String(vo.screen.name) : ""
    rippleOrigin: Qt.point(vo.inner + vo.insetR / 2, vo.endRect.y + vo.bodyH / 2)
  }
  Component.onCompleted: drop.open = Qt.binding(function() { return vo.shown })

  readonly property real dd: Math.max(0, drop.d)
  readonly property real bell: Math.max(0, 4 * dd * (1 - dd))
  // растёт поперёк кромки (влево), вдоль — почти сразу во всю высоту, в середине пути на 7 % уже
  readonly property real crossNow: Math.max(0, (bodyW * dd + Math.max(0, drop.sag)) * (1 - 0.002 * drop.wobble))
  readonly property real alongNow: Math.max(0, bodyH * (Math.min(1, 0.55 + 1.2 * dd) + Math.max(0, dd - 1) * 0.6) * (1 - 0.07 * bell + 0.003 * drop.wobble))
  readonly property rect body: Qt.rect(inner - gapR - crossNow, endRect.y + (bodyH - alongNow) / 2, crossNow, alongNow)
  readonly property real radiusNow: {
    var pill = Math.min(body.width, body.height) / 2
    return pill + (Math.min(bodyR, pill) - pill) * Math.max(0, Math.min(1, 1.6 * dd - 0.1))
  }
  readonly property real neckK: merge ? (26 + 20 * bell) * Math.min(1, 4 * dd) * (1 - 0.85 * sq) : 0
  readonly property rect neck: Qt.rect(inner + 3, body.y - neckK - 6, 5, body.height + 2 * neckK + 12)

  visible: drop.d > 0.002
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  // ── тело: стекло одним куском с рамкой ──
  LiquidGlass {
    visible: !vo.plastic
    x: vo.body.x; y: vo.body.y
    width: vo.body.width; height: vo.body.height
    radius: vo.radiusNow
    screenOrigin: Qt.point(x, y)
    tintColor: vo.bg
    bleed: vo.neckK + 60
    joinRect: vo.neckK > 0 ? Qt.rect(vo.neck.x - x, vo.neck.y - y, vo.neck.width, vo.neck.height) : Qt.rect(0, 0, 0, 0)
    joinRadius: 2.5
    joinK: vo.neckK
    cutRect: vo.merge ? Qt.rect(vo.inner + 3 - x, -4000, 4000, 8000) : Qt.rect(0, 0, 0, 0)
  }
  // ── пластик: заливка, контур, правая кромка слита с рамкой ──
  Item {
    visible: vo.plastic
    x: vo.body.x; y: vo.body.y
    width: vo.body.width + (vo.merge ? 3 : 0); height: vo.body.height
    clip: vo.merge
    Rectangle {
      width: vo.body.width + (vo.merge ? 20 : 0); height: parent.height
      radius: vo.radiusNow
      color: vo.bg
      border.width: vo.style.base === "milk" ? 0 : vo.style.base === "uwu" ? 3 : 2
      border.color: vo.style.base === "uwu" ? Qt.darker(vo.ink, 1.45) : vo.ink
      // UwU — его «конфетный пластик»
      gradient: vo.style.base === "uwu" ? candy : null
      Gradient {
        id: candy
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: "#ffb3dc" }
        GradientStop { position: 0.38; color: "#cfc4ff" }
        GradientStop { position: 0.68; color: "#aab4ff" }
        GradientStop { position: 1; color: "#ffd0ea" }
      }
    }
  }
  Repeater {
    model: vo.plastic && vo.merge && vo.dd > 0.6 ? [-1, 1] : []
    MergeFillet {
      required property var modelData
      x: vo.body.x; y: vo.body.y
      edge: "right"; side: modelData
      w: vo.body.width; h: vo.body.height
      f: 22; bw: vo.style.base === "milk" ? 0 : 2; ext: 3
      fill: vo.bg; line: vo.ink
    }
  }

  // ── плашка: растёт от кромки вместе с ящиком, проявляется после формы ──
  Item {
    id: plate
    x: vo.endRect.x + 12; y: vo.endRect.y + 12 + (1 - drop.reveal) * 12
    width: vo.plateW; height: vo.plateH
    opacity: drop.reveal
    transform: Scale { origin.x: plate.width + 12; origin.y: plate.height / 2; xScale: Math.max(0.05, Math.min(1, vo.dd)); yScale: Math.max(0.05, Math.min(1, vo.dd)) }

    Rectangle { anchors.fill: parent; radius: 14; color: vo.ink; opacity: 0.08 }
    Rectangle { anchors.fill: parent; radius: 14; color: "transparent"; border.width: 1; border.color: vo.a(vo.ink, 0.16) }

    // плитка со значком (у него: x − 128 от середины плашки)
    Rectangle {
      id: tile
      x: plate.width / 2 - 128 - 22; anchors.verticalCenter: parent.verticalCenter
      width: 44; height: 44; radius: 12
      color: vo.a(vo.muted ? vo.ink : vo.ink, 0.06)
      Text {
        anchors.centerIn: parent
        text: vo.osd.icon
        color: vo.muted ? vo.faint : vo.ink
        font.family: Commons.Style.font.family
        font.pixelSize: 20
      }
    }

    // карандашный слайдер (PSlider): контур-пилюля, уровень заштрихован акцентом, кольцо-бегунок
    Item {
      id: slider
      visible: vo.osd.hasProgress
      readonly property real h: 16
      readonly property real lv: vo.muted ? 0 : vo.shownFrac
      x: plate.width / 2 - 96; anchors.verticalCenter: parent.verticalCenter
      width: 170; height: h
      Rectangle { anchors.fill: parent; radius: height / 2; color: "transparent"; border.width: 1.5; border.color: vo.a(vo.ink, 0.65) }
      Repeater {
        model: 40
        Rectangle {
          required property int index
          readonly property real sp: Math.max(2.5, (slider.width - slider.h) / 39)
          readonly property real cx: slider.h * 0.5 + index * sp
          visible: cx < Math.max(slider.width * slider.lv - slider.h * 0.1, slider.h * 0.5)
          x: cx - width / 2; y: slider.h * 0.12
          width: 1.1; height: slider.h * 0.76
          rotation: 15
          antialiasing: true
          color: vo.a(vo.mint, 0.62)
        }
      }
      Rectangle {
        readonly property real kx: Math.max(slider.h * 0.6, Math.min(slider.width - slider.h * 0.6, slider.width * slider.lv))
        x: kx - width / 2; anchors.verticalCenter: parent.verticalCenter
        width: slider.h * 1.7; height: width; radius: width / 2
        color: vo.a(vo.ink, 0.14)
        border.width: 1.5; border.color: vo.a(vo.ink, 0.9)
      }
    }
    Text {
      visible: vo.osd.hasProgress
      anchors.horizontalCenter: parent.left; anchors.horizontalCenterOffset: plate.width / 2 + 116
      anchors.verticalCenter: parent.verticalCenter
      text: vo.readout
      color: vo.muted ? vo.faint : vo.ink
      font { family: vo.font; pixelSize: 21; weight: Font.Bold }
    }
    // без шкалы (Caps Lock, раскладка, сообщения) — подпись
    Text {
      visible: !vo.osd.hasProgress
      x: plate.width / 2 - 96; anchors.verticalCenter: parent.verticalCenter
      width: plate.width / 2 + 96 - 16
      elide: Text.ElideRight
      text: String(vo.osd.message || "")
      color: vo.ink
      font { family: vo.font; pixelSize: 19; weight: Font.Bold }
    }
  }
  property real shownFrac: frac
  Behavior on shownFrac { enabled: drop.reveal > 0.5; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
}
