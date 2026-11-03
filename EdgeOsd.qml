import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import "nihil" as Nihil

// edge: OSD со шкалой (громкость, яркость, микрофон) — вертикальный слайдер у края экрана
// (идея caelestia, написано с нуля). Вид — BarStyle (style):
//   attached — выезжает из края / рамки бара, вогнутые углы сверху и снизу переходят в край;
//   floating — карточка с отступом от края, рамкой и тенью.
// Окно встаёт у края внутри зарезервированных зон (с рамкой frame — прямо из неё). Клики не перехватывает.
PanelWindow {
  id: edge

  required property var osd          // корень Osd.qml: opened, icon, value, maxValue, message
  required property var style        // BarStyle.qml
  property bool nihil: false
  property string side: "right"      // right | left
  property string align: "center"    // center | top | bottom — вдоль края
  property string size: "normal"     // compact | normal | large
  property bool showValue: true

  readonly property bool attached: style.attached
  readonly property real k: size === "compact" ? 0.8 : size === "large" ? 1.25 : 1
  readonly property int thickness: Math.round((nihil ? 64 : 54) * k)
  readonly property int length: Math.round((nihil ? 300 : 250) * k)
  readonly property int flare: attached ? style.flare : 0
  readonly property int bodyRadius: nihil ? 18 : style.cornerRadius
  // NIHIL: the drawer erases the frame's side hairline — only a framed bar has one.
  readonly property int seamOverlap: nihil && attached && style.shape === "frame" ? 2 : 0
  readonly property color hairline: style.borderWidth > 0 ? style.borderColor : Nihil.Palette.line
  readonly property int edgeGap: attached ? 0 : 12
  readonly property int shadowPad: attached ? 0 : 20
  readonly property int outer: Math.max(flare, shadowPad)   // поле над и под телом
  readonly property bool isMuted: osd.iconKey.indexOf("mute") !== -1 || osd.value <= 0
  readonly property real ratio: isMuted ? 0 : Math.max(0, Math.min(1, osd.value / Math.max(1, osd.maxValue)))

  property bool shown: osd.opened
  property real progress: shown ? 1 : 0
  Behavior on progress { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
  readonly property real w: Math.round(thickness * progress)
  readonly property bool right: side !== "left"

  visible: progress > 0.001
  anchors.right: right
  anchors.left: !right
  anchors.top: align === "top"
  anchors.bottom: align === "bottom"
  margins.right: right ? -seamOverlap : 0
  margins.left: !right ? -seamOverlap : 0
  margins.top: align === "top" ? 40 : 0
  margins.bottom: align === "bottom" ? 40 : 0
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  implicitWidth: thickness + edgeGap + shadowPad + seamOverlap
  implicitHeight: length + 2 * outer
  color: "transparent"
  surfaceFormat.opaque: false
  WlrLayershell.namespace: "omarchy-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  // Тело в координатах окна: для правого края — у правой стороны, для левого — зеркально.
  readonly property real bodyX: right ? width - seamOverlap - edgeGap - w : seamOverlap + edgeGap
  readonly property real bodyY: outer

  // floating: карточка.
  Rectangle {
    visible: !edge.attached
    x: edge.bodyX
    y: edge.bodyY
    width: edge.w
    height: edge.length
    radius: Math.min(edge.bodyRadius, width / 2)
    color: edge.style.color
    border.width: edge.nihil ? 1 : edge.style.borderWidth
    border.color: edge.nihil ? edge.hairline : edge.style.borderColor
    layer.enabled: width > 1
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.4; shadowBlur: 0.8 }
  }

  // attached: контур рисуется для правого края, у левого — зеркально.
  Shape {
    id: osdShape
    visible: edge.attached
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { origin.x: edge.width / 2; xScale: edge.right ? 1 : -1 }

    readonly property real ww: edge.width
    readonly property real baseX: ww - edge.seamOverlap + (edge.seamOverlap > 0 ? 0.5 : 0)
    readonly property real x0: ww - edge.seamOverlap - edge.w
    readonly property real fx: Math.min(edge.flare, edge.w)
    readonly property real br: Math.max(0, Math.min(edge.bodyRadius, (edge.w - fx) / 2, edge.length / 2))
    readonly property real yTop: edge.flare
    readonly property real yBot: edge.height - edge.flare

    ShapePath {
      fillColor: edge.style.color
      strokeWidth: -1
      startX: osdShape.ww
      startY: 0

      PathLine { x: osdShape.baseX; y: 0 }
      PathArc { x: osdShape.baseX - osdShape.fx; y: osdShape.yTop; radiusX: Math.max(0.01, osdShape.fx); radiusY: Math.max(0.01, edge.flare); direction: PathArc.Clockwise }
      PathLine { x: osdShape.x0 + osdShape.br; y: osdShape.yTop }
      PathArc { x: osdShape.x0; y: osdShape.yTop + osdShape.br; radiusX: Math.max(0.01, osdShape.br); radiusY: Math.max(0.01, osdShape.br); direction: PathArc.Counterclockwise }
      PathLine { x: osdShape.x0; y: osdShape.yBot - osdShape.br }
      PathArc { x: osdShape.x0 + osdShape.br; y: osdShape.yBot; radiusX: Math.max(0.01, osdShape.br); radiusY: Math.max(0.01, osdShape.br); direction: PathArc.Counterclockwise }
      PathLine { x: osdShape.baseX - osdShape.fx; y: osdShape.yBot }
      PathArc { x: osdShape.baseX; y: edge.height; radiusX: Math.max(0.01, osdShape.fx); radiusY: Math.max(0.01, edge.flare); direction: PathArc.Clockwise }
      PathLine { x: osdShape.ww; y: edge.height }
      PathLine { x: osdShape.ww; y: 0 }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: edge.nihil ? edge.hairline : "transparent"
      strokeWidth: edge.nihil && edge.w > 1 ? 1 : -1
      startX: osdShape.baseX
      startY: 0

      PathArc { x: osdShape.baseX - osdShape.fx; y: osdShape.yTop; radiusX: Math.max(0.01, osdShape.fx); radiusY: Math.max(0.01, edge.flare); direction: PathArc.Clockwise }
      PathLine { x: osdShape.x0 + osdShape.br; y: osdShape.yTop }
      PathArc { x: osdShape.x0; y: osdShape.yTop + osdShape.br; radiusX: Math.max(0.01, osdShape.br); radiusY: Math.max(0.01, osdShape.br); direction: PathArc.Counterclockwise }
      PathLine { x: osdShape.x0; y: osdShape.yBot - osdShape.br }
      PathArc { x: osdShape.x0 + osdShape.br; y: osdShape.yBot; radiusX: Math.max(0.01, osdShape.br); radiusY: Math.max(0.01, osdShape.br); direction: PathArc.Counterclockwise }
      PathLine { x: osdShape.baseX - osdShape.fx; y: osdShape.yBot }
      PathArc { x: osdShape.baseX; y: edge.height; radiusX: Math.max(0.01, osdShape.fx); radiusY: Math.max(0.01, edge.flare); direction: PathArc.Clockwise }
    }
  }

  Item {
    x: edge.bodyX
    y: edge.bodyY
    width: edge.w
    height: edge.length
    clip: true
    opacity: Math.max(0, (edge.progress - 0.4) / 0.6)

    // NIHIL 16-LED vertical hardware meter + Doto Bold value
    Column {
      visible: edge.nihil
      width: edge.thickness
      anchors.centerIn: parent
      spacing: Math.round(14 * edge.k)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        textFormat: Text.PlainText
        text: edge.osd.icon
        font.family: Nihil.Palette.fontIcon
        font.pixelSize: Math.round(18 * edge.k)
        color: edge.isMuted ? Nihil.Palette.signal : Nihil.Palette.fg
      }

      Column {
        id: ledColumn
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property int dotCount: 16
        readonly property int litDots: Math.round(edge.ratio * dotCount)
        spacing: Math.max(2, Math.round(5 * edge.k))

        Repeater {
          model: ledColumn.dotCount

          Rectangle {
            required property int index
            width: Math.max(4, Math.round(6 * edge.k))
            height: width
            radius: width / 2
            color: (ledColumn.dotCount - 1 - index) < ledColumn.litDots ? Nihil.Palette.lit : Nihil.Palette.unlit
            Behavior on color { ColorAnimation { duration: 110 } }
          }
        }
      }

      Text {
        visible: edge.showValue
        anchors.horizontalCenter: parent.horizontalCenter
        textFormat: Text.PlainText
        text: edge.isMuted ? "--" : String(Math.round(edge.ratio * 100))
        font.family: Nihil.Palette.fontDot
        font.weight: Font.Bold
        font.pixelSize: Math.round(20 * edge.k)
        color: edge.isMuted ? Nihil.Palette.muted : Nihil.Palette.fg
      }
    }

    Column {
      visible: !edge.nihil
      width: edge.thickness
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      spacing: Math.round(12 * edge.k)

      Text {
        visible: edge.showValue
        anchors.horizontalCenter: parent.horizontalCenter
        text: edge.osd.message
        font.family: Style.font.family
        font.pixelSize: Math.round(12 * edge.k)
        font.bold: true
        color: Commons.Color.popups.text
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(8 * edge.k)
        height: edge.length - Math.round((edge.showValue ? 100 : 70) * edge.k)
        radius: width / 2
        color: Util.alpha(Commons.Color.popups.text, 0.18)
        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          radius: width / 2
          height: parent.height * Math.max(0, Math.min(1, edge.osd.value / Math.max(1, edge.osd.maxValue)))
          color: Commons.Color.accent
          Behavior on height { enabled: edge.shown; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: edge.osd.icon
        font.family: Style.font.family
        font.pixelSize: Math.round(22 * edge.k)
        color: Commons.Color.popups.text
      }
    }
  }
}
