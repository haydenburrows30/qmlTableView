import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import VoltageDrop 1.0

WaveCard {
    id: voltageDropCard
    title: 'Voltage Drop Calculator'

    property VoltageDropCalculator calculator: VoltageDropCalculator {}

    RowLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.maximumWidth: 300

            Label {
                text: "Cable Parameters"
            }

            GridLayout {
                id: cableParamsLayout
                columns: 2
                rowSpacing: 10
                columnSpacing: 15

                Label { text: "Cable Size (mm²):" }
                ComboBox {
                    id: cableSizeCombo
                    model: [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]
                    onCurrentTextChanged: calculator.cableSize = parseFloat(currentText)
                    Layout.fillWidth: true
                }

                Label { text: "Length (m):" }
                TextField {
                    id: lengthInput
                    placeholderText: "Enter length"
                    validator: DoubleValidator { bottom: 0 }
                    onTextChanged: if(text) calculator.length = parseFloat(text)
                    Layout.fillWidth: true
                }

                Label { text: "Current (A):" }
                TextField {
                    id: currentInput
                    placeholderText: "Enter current"
                    validator: DoubleValidator { bottom: 0 }
                    onTextChanged: if(text) calculator.current = parseFloat(text)
                    Layout.fillWidth: true
                }

                Label { text: "Conductor Material:" }
                ComboBox {
                    id: conductorMaterial
                    model: ["Copper", "Aluminum"]
                    onCurrentTextChanged: calculator.conductorMaterial = currentText
                    Layout.fillWidth: true
                }

                Label { text: "System Voltage (V):" }
                TextField {
                    id: systemVoltage
                    text: "230"
                    onTextChanged: if(text) calculator.setSystemVoltage(parseFloat(text))
                    Layout.fillWidth: true
                }
            }

            Label {
                text: "Results"
            }

            GridLayout {
                id: resultsLayout
                columns: 2
                rowSpacing: 5
                columnSpacing: 10

                Label { text: "Voltage Drop:" }
                Label { 
                    text: calculator.voltageDrop.toFixed(2) + " V"
                    font.bold: true 
                }

                Label { text: "Drop Percentage:" }
                Label { 
                    text: calculator.dropPercentage.toFixed(2) + "%"
                    font.bold: true 
                    color: calculator.dropPercentage > 3 ? "red" : "green"
                }
            }

            Item { Layout.fillHeight: true } // Spacer
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            border.color: "gray"
            border.width: 1
            radius: 5

            Canvas {
                id: dropVizCanvas
                anchors.fill: parent
                anchors.margins: 10
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Define dimensions
                    var width = dropVizCanvas.width;
                    var height = dropVizCanvas.height;
                    
                    // Calculate values
                    var dropPercentage = calculator.dropPercentage;
                    var dropRatio = Math.min(dropPercentage / 10, 1.0); // Cap at 10%
                    
                    // Draw voltage bar
                    var barHeight = height * 0.4;
                    var barY = height * 0.3;
                    var barWidth = width * 0.8;
                    var barX = width * 0.1;
                    
                    // Draw source voltage (100%)
                    ctx.fillStyle = "#88c0ff";
                    ctx.fillRect(barX, barY, barWidth, barHeight);
                    
                    // Draw voltage drop
                    ctx.fillStyle = "#ff8888";
                    ctx.fillRect(barX + barWidth * (1 - dropRatio), barY, barWidth * dropRatio, barHeight);
                    
                    // Draw separator line
                    ctx.strokeStyle = "black";
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(barX + barWidth * (1 - dropRatio), barY);
                    ctx.lineTo(barX + barWidth * (1 - dropRatio), barY + barHeight);
                    ctx.stroke();
                    
                    // Labels
                    ctx.fillStyle = "black";
                    ctx.font = "12px sans-serif";
                    ctx.textAlign = "center";
                    
                    // Source voltage
                    ctx.fillText("Source", barX + barWidth * 0.5 * (1 - dropRatio), barY - 10);
                    
                    // Load voltage
                    ctx.fillText("Load", barX + barWidth - barWidth * 0.5 * dropRatio, barY - 10);
                    
                    // Drop percentage
                    ctx.fillText(dropPercentage.toFixed(2) + "% drop", barX + barWidth * (1 - dropRatio * 0.5), barY + barHeight + 20);
                }
            }
        }
    }

    Connections {
        target: calculator
        function onVoltageDropChanged() { dropVizCanvas.requestPaint() }
        function onDropPercentageChanged() { dropVizCanvas.requestPaint() }
    }
}
