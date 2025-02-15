import QtQuick
import QtQuick.Controls

ToolTip {
    id: control
    visible: parent.hovered
    text: qsTr("A descriptive tool tip of what the button does")
    delay: 1500

    x: parent.width
    y: parent.height

    contentItem: Text {
        text: control.text
        font: control.font
        color: "#21be2b"
    }

    background: Rectangle {
        border.color: "#21be2b"
    }
}