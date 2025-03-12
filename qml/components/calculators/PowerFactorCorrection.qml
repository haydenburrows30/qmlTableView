import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import PFCorrection 1.0

WaveCard {
    id: pfCorrectionCard
    title: 'Power Factor Correction'
    property PowerFactorCorrectionCalculator calculator: PowerFactorCorrectionCalculator {}

    RowLayout {
        spacing: 10
        anchors.centerIn: parent

        // Input Section
        ColumnLayout {
            Layout.minimumWidth: 300

            GroupBox {
                title: "System Parameters"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Active Power (kW):" }
                    TextField {
                        id: activePowerInput
                        placeholderText: "Enter power"
                        onTextChanged: if(text) calculator.activePower = parseFloat(text)
                        Layout.minimumWidth: 150
                        // Layout.fillWidth: true
                    }

                    Label { text: "Current PF:" }
                    TextField {
                        id: currentPFInput
                        placeholderText: "Enter current PF"
                        onTextChanged: if(text) calculator.currentPF = parseFloat(text)
                        Layout.minimumWidth: 150
                        // Layout.fillWidth: true
                    }

                    Label { text: "Target PF:" }
                    TextField {
                        id: targetPFInput
                        placeholderText: "Enter target PF"
                        text: "0.95"
                        onTextChanged: if(text) calculator.targetPF = parseFloat(text)
                        Layout.minimumWidth: 150
                        // Layout.fillWidth: true
                    }
                }
            }

            // Results Section
            GroupBox {
                title: "Results"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 10

                    Label { text: "Required Capacitor:" }
                    Label { 
                        text: calculator.capacitorSize.toFixed(2) + " kVAR"
                        font.bold: true 
                    }

                    Label { text: "Capacitance Required:" }
                    Label { 
                        text: calculator.capacitance.toFixed(2) + " μF"
                        font.bold: true 
                    }

                    Label { text: "Annual Savings:" }
                    Label { 
                        text: "$" + calculator.annualSavings.toFixed(2)
                        font.bold: true 
                        color: "green"
                    }
                }
            }
        }

        // Power Triangle Visualization    
        Canvas {
            id: powerTriangle
            Layout.minimumHeight: 300
            Layout.minimumWidth: 300

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                
                // Get values with safety checks
                var p = calculator.activePower || 0
                var pf = calculator.currentPF || 0
                
                // Prevent division by zero and invalid PF
                if (p <= 0 || pf <= 0 || pf >= 1) return
                
                // Calculate triangle dimensions
                var q = p * Math.tan(Math.acos(pf))
                var s = p / pf
                
                // Set up scaling
                var margin = 40
                var maxDim = Math.max(p, q, s)
                var scale = (Math.min(width, height) - 2 * margin) / maxDim
                
                // Center the triangle
                var centerX = width/2
                var centerY = height/2
                
                // Draw triangle with thicker lines
                ctx.strokeStyle = "#2196F3"
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(centerX - p*scale/2, centerY)
                ctx.lineTo(centerX + p*scale/2, centerY)
                ctx.lineTo(centerX + p*scale/2, centerY - q*scale)
                ctx.closePath()
                ctx.stroke()
                
                // Add labels
                ctx.fillStyle = "black"
                ctx.font = "12px sans-serif"
                ctx.textAlign = "center"
                
                // Active Power (P)
                ctx.fillText(p.toFixed(1) + " kW", centerX, centerY + 20)
                
                // Reactive Power (Q)
                ctx.fillText(q.toFixed(1) + " kVAR", 
                    centerX + p*scale/2 + 20, 
                    centerY - q*scale/2)
                
                // Apparent Power (S)
                ctx.fillText(s.toFixed(1) + " kVA",
                    centerX, centerY - q*scale - 20)
                
                // Power Factor Angle
                ctx.fillText("φ = " + (Math.acos(pf) * 180/Math.PI).toFixed(1) + "°",
                    centerX + p*scale/4,
                    centerY - q*scale/4)
            }

            Connections {
                target: calculator
                function onActivePowerChanged() { powerTriangle.requestPaint() }
                function onCurrentPFChanged() { powerTriangle.requestPaint() }
            }
        }
    }
}
