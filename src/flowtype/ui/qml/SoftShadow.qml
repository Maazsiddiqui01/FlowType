import QtQuick

// A soft drop shadow built from layered translucent rounded rectangles. Uses no
// shaders/FBOs, so it renders identically on every backend (GPU and the software
// fallback) and can never blank-render the content it sits behind.
Item {
    id: root

    property int radius: 18
    property color shadowColor: Qt.rgba(0, 0, 0, 0.5)
    property real spread: 16        // how far the halo extends past the surface
    property real verticalOffset: 5 // downward shift for a "lit from above" feel
    property int layers: 7

    Repeater {
        model: root.layers

        Rectangle {
            // t in (0, 1]; outer layers are larger and, stacked, build a soft gradient
            // that is densest at the surface edge and fades outward.
            readonly property real t: (index + 1) / root.layers
            width: root.width + root.spread * 2 * t
            height: root.height + root.spread * 2 * t
            x: (root.width - width) / 2
            y: (root.height - height) / 2 + root.verticalOffset
            radius: root.radius + root.spread * t
            antialiasing: true
            color: Qt.rgba(root.shadowColor.r, root.shadowColor.g, root.shadowColor.b,
                           root.shadowColor.a / root.layers)
        }
    }
}
