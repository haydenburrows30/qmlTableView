import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Controls.Material
import QtQuick.Effects
import Qt.labs.settings 1.0  // Change this import

import 'components'
import 'components/calculators'

ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true

    SeriesRLCChart {id: seriesRLCChart}
    SineWaveModel {id: sineModel}
    VoltageDrop {id: voltageDrop}
    ResultsManager {id: resultsManager}

    // Add splash screen
    Popup {
        id: splashScreen
        modal: true
        visible: true
        closePolicy: Popup.NoAutoClose
        anchors.centerIn: parent
        width: 300
        height: 300
        
        background: Rectangle {
            color: Universal.background
            radius: 10
            border.width: 1
            border.color: Universal.foreground
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                // Add app logo/icon here
                Image {
                    source: "qrc:/icons/gallery/24x24/Calculator.svg"
                    width: 64
                    height: 64
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                BusyIndicator {
                    running: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                ProgressBar {
                    width: 200
                    value: loadingManager.progress
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Label {
                    text: loadingManager.loading ? "Loading..." : "Ready!"
                    color: Universal.foreground
                    font.pixelSize: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
    
    // Modified timer to close only when loading is complete
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!loadingManager.loading) {
                splashScreen.close()
            }
        }
    }

    // Add parent container for proper z-ordering
    Item {
        anchors.fill: parent

        StackView {
            id: stackView
            objectName: "stackView"
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                leftMargin: 0
                right: parent.right
            }
            z: 1
            Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/Home.qml"),StackView.Immediate)

            states: [State {
                name: "closed"; when: sideBar.hide
                PropertyChanges { target: stackView; anchors.leftMargin: 0;}
            },
            State {
                name: "open"; when: sideBar.show
                PropertyChanges { target: stackView; anchors.leftMargin: sideBar.width}
            }]

            transitions: Transition {
                NumberAnimation { properties: "anchors.leftMargin"; easing.type: Easing.InOutQuad; duration: 200  }
            }
        }

        // Menu button and sidebar as separate elements
        CButton {
            id: menu
            icon_name: "Menu"
            width: 60
            height: 60
            z: 1000  // Much higher z-index to ensure it's always on top
            visible: true
            
            // Position flush with left and bottom edges
            x: 0  // Flush with left edge
            y: parent.height - height  // Flush with bottom edge
            
            tooltip_text: sideBar.open_closed ? "Close Menu" : "Open Menu"

            MouseArea {
                id: dragArea
                anchors.fill: parent
                drag.target: menu
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0 
                drag.maximumX: parent.parent.width - menu.width
                drag.minimumY: 0
                drag.maximumY: parent.parent.height - menu.height
                
                property bool isDragging: false
                property point startPos
                
                function handlePressed(mouseX, mouseY) {
                    startPos = Qt.point(mouseX, mouseY)
                }
                
                function handlePositionChanged(mouseX, mouseY) {
                    if (!isDragging) {
                        let dx = mouseX - startPos.x
                        let dy = mouseY - startPos.y
                        isDragging = Math.sqrt(dx * dx + dy * dy) > 5
                    }
                    
                    if (isDragging) {
                        settings.menuX = menu.x
                        settings.menuY = menu.y
                        let isOriginalPosition = menu.x === 0 && menu.y === parent.parent.height - menu.height
                        
                        if (isOriginalPosition) {
                            sideBar.menuMoved = false
                            if (!menu.inOriginalPosition) {
                                sideBar.open()
                            }
                        } else {
                            sideBar.menuMoved = true
                            if (menu.inOriginalPosition && sideBar.position === 1) {
                                sideBar.close()
                            }
                        }
                    }
                }
                
                onPressed: (mouse) => {
                     handlePressed(mouse.x, mouse.y)
                }
                onPositionChanged: (mouse) => {
                    handlePositionChanged(mouse.x, mouse.y)
                }
                
                onReleased: {
                    if (!isDragging) {
                        menu.clicked()
                    }
                    isDragging = false
                    settings.menuX = menu.x
                    settings.menuY = menu.y
                }
                
                onClicked: if (!isDragging) menu.clicked()
            }

            // Add property to track original position
            property bool inOriginalPosition: x === 0 && y === parent.height - height
            
            onXChanged: sideBar.menuMoved = !inOriginalPosition
            onYChanged: sideBar.menuMoved = !inOriginalPosition

            onClicked: { 
                sideBar.react()
                forceActiveFocus()
            }
        }

        SideBar {
            id: sideBar
            edge: Qt.LeftEdge
            width: 60
            height: menuMoved ? parent.height : parent.height - menu.height
            y: 0  // Start from top
            property bool menuMoved: false
        }
    }

    Settings {
        id: settings
        property real menuX
        property real menuY
    }

    Universal.theme: sideBar.toggle1 ? Universal.Dark : Universal.Light
    Universal.accent: sideBar.toggle1 ? Universal.Red : Universal.Cyan
}
