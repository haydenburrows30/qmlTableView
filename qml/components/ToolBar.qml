import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ToolBar {
    id:toolBar
    property bool toggle : action.checked //{darkModeToggle.checked}

    background: Rectangle {
        implicitHeight: 60
        opacity: 0
    }

    signal mySignal()

    RowLayout {
        anchors.fill: parent

        RoundButton {
            id: menu

            icon.name: 'Menu'
            implicitWidth: 50
            implicitHeight: 50
            icon.width: 30
            icon.height: 30
            Layout.leftMargin: 5
            ToolTip {
                id: sidebar_tooltip
                text: sideBar.open_closed ? "Close Menu":"Open Menu"
                visible: parent.hovered
                x: parent.width
                y: parent.height
                delay: 500
                timeout: 2000
            }
            // Layout.alignment: Qt.AlignVCenter

            background: Rectangle {
                radius: menu.radius
                visible: !menu.flat || menu.down || menu.checked || menu.highlighted
                color: menu.down ? menu.Universal.baseMediumLowColor :
                    menu.enabled && (menu.highlighted || menu.checked) ? menu.Universal.accent :
                                                                                    "transparent"

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: menu.radius
                    color: "transparent"
                    visible: enabled && menu.hovered
                    border.width: 2
                    border.color: menu.Universal.baseMediumLowColor
                }
            }

            onClicked: {
                sidebar_tooltip.hide()
                mySignal()
            }
        }

        Label {
            text: "Electrical Calculators"
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: menu.width
        }

        RoundButton {
            id: action
            implicitWidth: 40
            implicitHeight: 40
            icon.width: 30
            icon.height: 30
            checkable: true
            icon.name: action.checked ? "Dark":"Light"

            ToolTip {
                id: mode_tooltip
                text: action.checked ? "Light Mode":"Dark Mode"
                visible: parent.hovered
                x: parent.width
                y: parent.height
                delay: 500
                timeout: 2000
            }

            onClicked: {
                mode_tooltip.hide()
            }

            background: Rectangle {
                radius: action.radius
                visible: !action.flat || action.down || action.checked || action.highlighted
                color: action.down ? action.Universal.baseMediumLowColor :
                    action.enabled && (action.highlighted || action.checked) ? action.Universal.accent :
                                                                                    "transparent"

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: action.radius
                    color: "transparent"
                    visible: enabled && action.hovered
                    border.width: 2
                    border.color: action.Universal.baseMediumLowColor
                }
            }
        }

        // Switch {
        //     id: darkModeToggle
        //     Layout.alignment: Qt.AlignVCenter
        // }

        RoundButton {
            id: control

            icon.name: 'Setting'
            implicitWidth: 50
            implicitHeight: 50
            icon.width: 30
            icon.height: 30
            Layout.rightMargin: 10
            ToolTip {
                text: "Settings"
            }

            ToolTip {
                text: "Settings"
                visible: parent.hovered
                x: parent.width
                y: parent.height
                delay: 500
                timeout: 2000
            }
            
            background: Rectangle {
                radius: control.radius
                visible: !control.flat || control.down || control.checked || control.highlighted
                color: control.down ? control.Universal.baseMediumLowColor :
                    control.enabled && (control.highlighted || control.checked) ? control.Universal.accent :
                                                                                    "transparent"

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: control.radius
                    color: "transparent"
                    visible: enabled && control.hovered
                    border.width: 2
                    border.color: control.Universal.baseMediumLowColor
                }
            }

            onClicked: {
                settings.open()
            }
        }
    }
}