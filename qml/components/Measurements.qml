import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import components 1.0

Item {
    id: root
    property var model
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        width: parent.width
        spacing: 10

        GridLayout {
            columns: 6
            columnSpacing: 20
            rowSpacing: 10
            Layout.fillWidth: true

            Label { text: "Phase" }
            Label { text: "RMS (V)" }
            Label { text: "Current (A)" }
            Label { text: "PF" }
            Label { text: "Current Angle" }
            Label { text: "Power (kW)" }

            Label { text: "A"; color: "red" }
            Label { text: model.rmsA.toFixed(1) }
            
            // Fixed SpinBox for Current A
            SpinBox {
                id: currentSpinA
                from: 0
                to: 1000
                value: model ? model.currentA : 10
                stepSize: 1
                editable: true
                onValueModified: {
                    if (model) {
                        model.setCurrentA(value)
                    }
                }
                
                textFromValue: function(value, locale) {
                    return Number(value).toLocaleString(locale, 'f', 1)
                }

                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text)
                }
            }
            
            Label { text: model.powerFactorA.toFixed(3) }
            
            SpinBox {
                from: -90
                to: 90
                value: model && model.currentAngleA ? model.currentAngleA : 30
                stepSize: 1
                editable: true
                onValueModified: if (model) model.setCurrentAngleA(value)
            }
            
            Label { 
                text: (model.rmsA * model.currentA * model.powerFactorA / 1000).toFixed(2) 
            }

            Label { text: "B"; color: "green" }
            Label { text: model.rmsB.toFixed(1) }
            
            // Fixed SpinBox for Current B
            SpinBox {
                id: currentSpinB
                from: 0
                to: 1000
                value: model ? model.currentB : 10
                stepSize: 1
                editable: true
                onValueModified: {
                    if (model) {
                        model.setCurrentB(value)
                    }
                }
                
                textFromValue: function(value, locale) {
                    return Number(value).toLocaleString(locale, 'f', 1)
                }

                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text)
                }
            }
            
            Label { text: model.powerFactorB.toFixed(3) }
            
            SpinBox {
                from: -90
                to: 90
                value: model && model.currentAngleB ? model.currentAngleB : -90
                stepSize: 1
                editable: true
                onValueModified: if (model) model.setCurrentAngleB(value)
            }
            
            Label { 
                text: (model.rmsB * model.currentB * model.powerFactorB / 1000).toFixed(2) 
            }

            Label { text: "C"; color: "blue" }
            Label { text: model.rmsC.toFixed(1) }
            
            // Fixed SpinBox for Current C
            SpinBox {
                id: currentSpinC
                from: 0
                to: 1000
                value: model ? model.currentC : 10
                stepSize: 1
                editable: true
                onValueModified: {
                    if (model) {
                        model.setCurrentC(value)
                    }
                }
                
                textFromValue: function(value, locale) {
                    return Number(value).toLocaleString(locale, 'f', 1)
                }

                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text)
                }
            }
            
            Label { text: model.powerFactorC.toFixed(3) }
            
            SpinBox {
                from: -90
                to: 90
                value: model && model.currentAngleC ? model.currentAngleC : 150
                stepSize: 1
                editable: true
                onValueModified: if (model) model.setCurrentAngleC(value)
            }
            
            Label { 
                text: (model.rmsC * model.currentC * model.powerFactorC / 1000).toFixed(2) 
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "gray"
            opacity: 0.3
        }

        PowerTriangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            Layout.minimumHeight: 150
            activePower: model.activePower
            reactivePower: model.reactivePower
            apparentPower: model.apparentPower
            powerFactor: model.averagePowerFactor
            triangleScale: 100  // Use renamed property
        }

        GridLayout {
            columns: 2
            columnSpacing: 20
            Layout.fillWidth: true

            Label { text: "Line-to-Line RMS" }
            Label { text: "Voltage (V)" }

            Label { text: "VAB" }
            Label { text: model.rmsAB.toFixed(1) }

            Label { text: "VBC" }
            Label { text: model.rmsBC.toFixed(1) }

            Label { text: "VCA" }
            Label { text: model.rmsCA.toFixed(1) }
            
            Label { text: "Average Power Factor" }
            Label { 
                text: model.averagePowerFactor.toFixed(3)
                font.bold: true 
            }
        }

        GridLayout {
            columns: 2
            Layout.fillWidth: true
            
            Label { text: "Total Apparent Power (S):" }
            Label { text: model.apparentPower.toFixed(2) + " kVA" }
            
            Label { text: "Total Active Power (P):" }
            Label { text: model.activePower.toFixed(2) + " kW" }
            
            Label { text: "Total Reactive Power (Q):" }
            Label { text: model.reactivePower.toFixed(2) + " kVAR" }
            
            Label { text: "System Power Factor:" }
            Label { text: model.averagePowerFactor.toFixed(3) }
        }
    }
}
