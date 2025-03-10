import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import "../components"

Page {
    id: home

    property var powerTriangleModel
    property var impedanceVectorModel

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5
            
            ColumnLayout {
                id: mainLayout
                width: scrollView.width
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 5

                RowLayout {

                    WaveCard {
                        id: power_current
                        title: 'Power -> Current'
                        Layout.minimumHeight: 200
                        Layout.minimumWidth: 300

                        info: "../../media/powercalc.png"
                        righticon: "Info"

                        ColumnLayout {

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Phase:"
                                    Layout.preferredWidth: 80
                                }

                                ComboBox {
                                    id: phaseSelector
                                    model: ["Single Phase", "Three Phase"]
                                    onCurrentTextChanged: powerCalculator.setPhase(currentText)
                                    currentIndex: 1

                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "kVA:"
                                    Layout.preferredWidth: 80
                                }

                                TextField {
                                    id: kvaInput
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                    placeholderText: "Enter kVA"
                                    onTextChanged: powerCalculator.setKva(parseFloat(text))
                                }
                            }

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Voltage:"
                                    Layout.preferredWidth: 80
                                }

                                TextField {
                                    id: voltageInput
                                    placeholderText: "Enter Voltage"
                                    onTextChanged: {
                                        powerCalculator.setVoltage(parseFloat(text))
                                    }
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
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
                                    id: currentOutput
                                    text: powerCalculator.current.toFixed(2) + "A"
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                }
                            }
                        }
                    }

                    WaveCard {
                        id: conversionCalculator
                        title: 'Conversion Calculator'
                        Layout.minimumWidth: 300
                        Layout.minimumHeight: 200

                        ColumnLayout {

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Input Value:"
                                    Layout.preferredWidth: 110
                                }

                                TextField {
                                    id: inputValue
                                    placeholderText: "Enter Value"
                                    onTextChanged: {
                                        conversionCalc.setInputValue(parseFloat(text))
                                    }
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Conversion Type:"
                                    Layout.preferredWidth: 110
                                }

                                ComboBox {
                                    id: conversionType
                                    model: ["watts_to_dbmw", "dbmw_to_watts", "rad_to_hz", "hp_to_watts", "rpm_to_hz", "radians_to_hz", "hz_to_rpm", "watts_to_hp"]
                                    onCurrentTextChanged: conversionCalc.setConversionType(currentText)
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            RowLayout {
                                spacing: 10
                                Layout.topMargin: 5

                                Label {
                                    text: "Result:"
                                    Layout.preferredWidth: 110
                                }

                                Text {
                                    id: conversionResult
                                    text: conversionCalc.result.toFixed(2)
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }
                            }
                        }
                    }
                }

                WaveCard {
                    id: charging_current
                    title: 'Cable Charging Current'
                    Layout.minimumWidth: 600
                    Layout.minimumHeight: 230

                    info: "../../media/ccc.png"

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
                                    onTextChanged: {
                                        chargingCalc.setVoltage(parseFloat(text))
                                    }
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
                                    onTextChanged: chargingCalc.setCapacitance(parseFloat(text))
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
                                    onTextChanged: chargingCalc.setFrequency(parseFloat(text))
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
                                    onTextChanged: chargingCalc.setLength(parseFloat(text))
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
                                    text: chargingCalc.chargingCurrent.toFixed(2) + "A"
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
                            current: chargingCalc.chargingCurrent
                        }
                    }
                }

                WaveCard {
                    id: fault_current
                    title: 'Impedance'
                    Layout.minimumWidth: 600
                    Layout.minimumHeight: 250

                    info: "../../media/Formel-Impedanz.gif"

                    RowLayout {
                        anchors.fill: parent

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop

                            RowLayout {
                                spacing: 5

                                Label {
                                    text: "Resistance(R):"
                                    Layout.preferredWidth: 100
                                }

                                TextField {
                                    id: rInput
                                    placeholderText: "Enter Resistance"
                                    onTextChanged: {
                                        faultCalc.setResistance(parseFloat(text)) + "Ω"
                                    }
                                    Layout.preferredWidth: 130
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            RowLayout {
                                spacing: 5

                                Label {
                                    text: "Reactance (X):"
                                    Layout.preferredWidth: 100
                                }

                                TextField {
                                    id: reactanceInput
                                    Layout.preferredWidth: 130
                                    Layout.alignment: Qt.AlignRight
                                    placeholderText: "Enter Reactance"
                                    onTextChanged: faultCalc.setReactance(parseFloat(text)) + "Ω"
                                }
                            }

                            RowLayout {
                                spacing: 5
                                Layout.topMargin: 5

                                Label {
                                    text: "Impedance (Z):"
                                    Layout.preferredWidth: 110
                                }

                                Text {
                                    id: impedanceOutput
                                    text: faultCalc.impedance.toFixed(2) + "Ω"
                                    Layout.preferredWidth: 130
                                    Layout.alignment: Qt.AlignRight
                                }
                            }
                        }

                        ImpedanceVectorViz {
                            id: impedanceViz
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: -50

                            resistance: parseFloat(rInput.text || "3")
                            reactance: parseFloat(reactanceInput.text || "4")
                            impedance: parseFloat(faultCalc.impedance.toFixed(2))
                            phaseAngle: parseFloat(faultCalc.phaseAngle.toFixed(2))
                        }
                    }
                }

                WaveCard {
                    id: electricPy
                    title: 'Frequency'
                    Layout.minimumWidth: 600
                    Layout.minimumHeight: 250

                    info: "../../media/FormelXC.gif"

                    RowLayout {
                        anchors.fill: parent

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Capacitance(uF):"
                                    Layout.preferredWidth: 110
                                }

                                TextField {
                                    id: cInput
                                    placeholderText: "Enter Capacitance"
                                    onTextChanged: {
                                        resonantFreq.setCapacitance(parseFloat(text))
                                    }
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Inductance (mH):"
                                    Layout.preferredWidth: 110
                                }

                                TextField {
                                    id: inductanceInput
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                    placeholderText: "Enter Inductance"
                                    onTextChanged: resonantFreq.setInductance(parseFloat(text))
                                }
                            }

                            RowLayout {
                                spacing: 10

                                Label {
                                    text: "Frequency (Hz):"
                                    Layout.preferredWidth: 110
                                }

                                Text {
                                    id: freqOutput
                                    text: resonantFreq.frequency.toFixed(2) + "Hz"
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }
                            }
                        }

                    // Sine wave visualization
                        SineWaveViz {
                            id: sineWaveViz
                            Layout.fillWidth: true
                            Layout.minimumHeight: 200
                            Layout.minimumWidth: 200
                            Layout.topMargin: -50
                            // Layout.alignment: Qt.AlignTop
                            frequency: resonantFreq ? resonantFreq.frequency : 0
                            
                            // Initialize with default values
                            Component.onCompleted: {
                                if (sineCalc) {
                                    amplitude = 330;
                                    frequency = parseFloat(freqOutput.text.replace("Hz", "") || "0");
                                    sineCalc.setFrequency(frequency);
                                    yValues = sineCalc.yValues;
                                    rms = sineCalc.rms;
                                    peak = sineCalc.peak;
                                }
                            }
                            
                            // Connect to frequency changes
                            Connections {
                                target: resonantFreq
                                function onFrequencyCalculated() {
                                    if (sineCalc) {
                                        sineCalc.setFrequency(resonantFreq.frequency);
                                        sineWaveViz.frequency = resonantFreq.frequency;
                                        sineWaveViz.yValues = sineCalc.yValues;
                                        sineWaveViz.rms = sineCalc.rms;
                                        sineWaveViz.peak = sineCalc.peak;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}