import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    
    property real voltageDropValue: 0
    property string selectedVoltage: "415V" 
    property real diversityFactor: 1.0
    property string combinedRatingInfo: "N/A"
    property real totalLoad: 0.0
    property real current: 0.0
    property bool darkMode: false
    
    // Calculated properties
    property real dropPercentage: voltageDropValue / (parseFloat(selectedVoltage.slice(0, -1)) || 1) * 100
    
    // Signals
    signal saveResultsClicked()
    signal viewDetailsClicked()
    signal viewChartClicked()
    
    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 18

        Label { text: "Voltage Drop: " }

        Label {
            text: root.voltageDropValue.toFixed(2) + " V"
            font.weight: Font.Medium
        }

        Label { text: "Percentage Drop: " }

        Label {
            text: root.dropPercentage.toFixed(2) + "%"
            color: root.dropPercentage > 5 ? "red" : "green"
        }

        Label { text: "Diversity Factor Applied: " }

        Label {
            text: root.diversityFactor.toFixed(2)
        }

        Label { text: "Network Fuse / Rating:" }
        Text {
            id: networkFuseSizeText
            text: root.combinedRatingInfo
            color: text !== "N/A" && text !== "Not specified" && text !== "Error" ? 
                   "blue" : (text === "Error" ? "red" : root.darkMode ? "#ffffff" : "#000000")
            font.bold: text !== "N/A" && text !== "Not specified" && text !== "Error"
            Layout.fillWidth: true
        }

        Label { text: "Total Load (kVA):" }
        Text {
            text: root.totalLoad.toFixed(1)
            font.bold: true
            Layout.fillWidth: true
            color: root.darkMode ? "#ffffff" : "#000000"
        }

        Label { text: "Current (A):" }
        Text {
            text: root.current.toFixed(1)
            font.bold: true
            color: root.darkMode ? "#ffffff" : "#000000"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4

            Rectangle {
                width: parent.width * Math.min((root.voltageDropValue / parseFloat(root.selectedVoltage.slice(0, -1)) * 100) / 10, 1)
                height: parent.height
                radius: 4
                color: root.dropPercentage > 5 ? "red" : "green"
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        RowLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.topMargin: 10
            spacing: 10
            uniformCellSizes: true

            Button {
                text: "Save Results"
                icon.name: "document-save"
                enabled: root.voltageDropValue > 0
                Layout.fillWidth: true
                onClicked: root.saveResultsClicked()
            }

            Button {
                text: "Details"
                icon.name: "Info"
                enabled: root.voltageDropValue > 0
                Layout.fillWidth: true
                onClicked: root.viewDetailsClicked()
            }

            Button {
                text: "View Chart"
                icon.name: "Chart"
                enabled: root.voltageDropValue > 0
                Layout.fillWidth: true
                onClicked: root.viewChartClicked()
            }
        }
    }
}
