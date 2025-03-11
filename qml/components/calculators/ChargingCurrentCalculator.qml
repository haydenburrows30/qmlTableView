import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import Charging 1.0  // Import the Charging namespace for our calculator

WaveCard {
    id: charging_current
    title: 'Cable Charging Current'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 230

    info: ""

    // Create a local instance of our calculator
    property ChargingCalculator calculator: ChargingCalculator {}

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            
            RowLayout {
                spacing: 10
                Label {
                    text: "Voltage (kV):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: voltage_input
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Voltage"
                    onTextChanged: chargingCurrentCalc.setVoltage(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "uF/km (1ph):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: capacitanceInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Capacitance"
                    onTextChanged: chargingCurrentCalc.setCapacitance(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Freq (Hz):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: frequencyInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Frequency"
                    onTextChanged: chargingCurrentCalc.setFrequency(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Length (km):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: lengthInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Length"
                    onTextChanged: chargingCurrentCalc.setLength(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10
                Layout.topMargin: 5
                Label {
                    text: "Current:"
                    Layout.preferredWidth: 80
                }
                Text {
                    id: chargingCurrentOutput
                    text: calculator && !isNaN(calculator.chargingCurrent) ? 
                          calculator.chargingCurrent.toFixed(2) + "A" : "0.00A"
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        ChargingCurrentViz {
            id: chargingCurrentViz
            Layout.fillWidth: true
            Layout.minimumHeight: 150
            voltage: parseFloat(voltage_input.text || "0") 
            capacitance: parseFloat(capacitanceInput.text || "0")
            frequency: parseFloat(frequencyInput.text || "50")
            length: parseFloat(lengthInput.text || "1")
            current: calculator ? calculator.chargingCurrent : 0.0
        }
    }
}
