import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import components 1.0
import "../components"

Page {
    id: root
    padding: 0
    
    // Move model to top level and create explicit binding
    property real currentVoltageDropValue: voltageDrop.voltageDrop || 0
    
    // Add connections to ensure property updates when signal is emitted
    Connections {
        target: voltageDrop
        function onVoltageDropCalculated(value) {
            console.log("Voltage drop updated:", value)
            root.currentVoltageDropValue = value
        }
    }

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {
                    WaveCard {
                        title: "Cable Selection"
                        Layout.minimumHeight: 560
                        Layout.minimumWidth: 400

                        CableSelectionSettings {
                            id: cableSettings
                            anchors.fill: parent

                            onResetRequested: {
                                console.log("Reset requested")
                            }

                            onResetCompleted: {
                                console.log("Reset completed, updating UI")

                                root.currentVoltageDropValue = voltageDrop.voltageDrop || 0

                                console.log("After reset - voltage drop:", voltageDrop.voltageDrop)
                                console.log("After reset - current:", voltageDrop.current)
                                console.log("After reset - fuse size:", voltageDrop.networkFuseSize)
                                console.log("After reset - combined rating:", voltageDrop.combinedRatingInfo)

                                resultsPanel.combinedRatingInfo = voltageDrop.combinedRatingInfo || "N/A"
                                resultsPanel.totalLoad = voltageDrop.totalKva || 0.0
                                resultsPanel.current = voltageDrop.current || 0.0
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Results"
                        Layout.minimumHeight: 350
                        Layout.minimumWidth: 400

                        ResultsPanel {
                            id: resultsPanel
                            anchors.fill: parent
                            darkMode: sideBar.toggle1
                            voltageDropValue: root.currentVoltageDropValue
                            selectedVoltage: voltageDrop.selectedVoltage
                            diversityFactor: voltageDrop.diversityFactor
                            combinedRatingInfo: voltageDrop.combinedRatingInfo || "N/A"
                            totalLoad: voltageDrop.totalKva || 0.0
                            current: voltageDrop.current || 0.0
                            
                            onSaveResultsClicked: {
                                resultsManager.save_calculation({
                                    "voltage_system": cableSettings.voltageSelect.currentText,
                                    "kva_per_house": parseFloat(cableSettings.kvaPerHouseInput.text),
                                    "num_houses": parseInt(cableSettings.numberOfHousesInput.text),
                                    "diversity_factor": voltageDrop.diversityFactor,
                                    "total_kva": voltageDrop.totalKva,
                                    "current": voltageDrop.current,
                                    "cable_size": cableSettings.cableSelect.currentText,
                                    "conductor": cableSettings.conductorSelect.currentText,
                                    "core_type": cableSettings.coreTypeSelect.currentText,
                                    "length": parseFloat(cableSettings.lengthInput.text),
                                    "voltage_drop": root.currentVoltageDropValue,
                                    "drop_percent": resultsPanel.dropPercentage,
                                    "admd_enabled": cableSettings.admdCheckBox.checked
                                });
                            }
                            
                            onViewDetailsClicked: {
                                detailsPopup.voltageSystem = voltageDrop.selectedVoltage
                                detailsPopup.admdEnabled = voltageDrop.admdEnabled
                                detailsPopup.kvaPerHouse = voltageDrop.totalKva / voltageDrop.numberOfHouses
                                detailsPopup.numHouses = voltageDrop.numberOfHouses
                                detailsPopup.diversityFactor = voltageDrop.diversityFactor
                                detailsPopup.totalKva = voltageDrop.totalKva
                                detailsPopup.current = voltageDrop.current
                                detailsPopup.cableSize = cableSettings.cableSelect.currentText
                                detailsPopup.conductorMaterial = voltageDrop.conductorMaterial
                                detailsPopup.coreType = voltageDrop.coreType
                                detailsPopup.length = cableSettings.lengthInput.text
                                detailsPopup.installationMethod = cableSettings.installationMethodCombo.currentText
                                detailsPopup.temperature = cableSettings.temperatureInput.text
                                detailsPopup.groupingFactor = cableSettings.groupingFactorInput.text
                                detailsPopup.combinedRatingInfo = voltageDrop.combinedRatingInfo
                                detailsPopup.voltageDropValue = root.currentVoltageDropValue
                                detailsPopup.dropPercentage = resultsPanel.dropPercentage
                                detailsPopup.open()
                            }
                            
                            onViewChartClicked: {
                                chartPopup.percentage = resultsPanel.dropPercentage
                                chartPopup.cableSize = cableSettings.cableSelect.currentText
                                chartPopup.currentValue = voltageDrop.current
                                chartPopup.prepareChart()
                                chartPopup.open()
                            }
                        }
                    }
                }

                ColumnLayout {
                    WaveCard {
                        title: "Cable Size Comparison"
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ComparisonTable {
                            id: comparisonTable
                            anchors.fill: parent
                            darkMode: sideBar.toggle1
                            tableModel: voltageDrop.tableModel
                            
                            onExportRequest: function(format) {
                                if (format === "csv") {
                                    loadingIndicator.show()
                                    voltageDrop.exportTableData(null)
                                } else if (format === "pdf") {
                                    loadingIndicator.show()
                                    voltageDrop.exportTableToPDF(null)
                                } else if (format === "menu") {
                                    exportFormatMenu.popup()
                                }
                            }
                        }
                    }
                    
                    SavedResults {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 300
                    }
                }
            }
        }
    }

    ChartPopup {
        id: chartPopup
        
        onSaveRequested: function(scale) {
            exportFileDialog.setup("Save Chart", "PNG files (*.png)", "png", 
                                  "voltage_drop_chart", exportFileDialog.chartExport)
            exportFileDialog.currentScale = scale
            exportFileDialog.open()
        }
    }
    
    MessagePopup {
        id: messagePopup
    }
    
    ExportFileDialog {
        id: exportFileDialog

        function handleExport(selectedFile) {
            switch(exportType) {
                case chartExport:
                    voltageDrop.saveChart(selectedFile, currentScale)
                    break
                case tableCsvExport:
                    voltageDrop.exportTableData(selectedFile)
                    break
                case tablePdfExport:
                    voltageDrop.exportTableToPDF(selectedFile)
                    break
                case detailsPdfExport:
                    voltageDrop.exportDetailsToPDF(selectedFile, details)
                    break
            }
        }
        
        Component.onCompleted: {
            handler = handleExport
        }
    }
    
    ExportFormatMenu {
        id: exportFormatMenu
        
        Component.onCompleted: {
            onCsvExport = function() {
                loadingIndicator.show()
                voltageDrop.exportTableData(null)
            }
            
            onPdfExport = function() {
                loadingIndicator.show()
                voltageDrop.exportTableToPDF(null)
            }
        }
    }
    
    LoadingIndicator {
        id: loadingIndicator
    }

    Connections {
        target: voltageDrop
        
        function onGrabRequested(filepath, scale) {
            loadingIndicator.show()
            console.log("Grabbing image to:", filepath, "with scale:", scale)
            chartPopup.grabImage(function(result) {
                loadingIndicator.hide()
                if (result) {
                    var saved = result.saveToFile(filepath)
                    if (saved) {
                        messagePopup.showSuccess("Chart saved successfully")
                    } else {
                        messagePopup.showError("Failed to save chart")
                    }
                } else {
                    messagePopup.showError("Failed to grab chart image")
                }
            }, scale)
        }

        function onTableExportStatusChanged(success, message) {
            loadingIndicator.hide()
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }

        function onTablePdfExportStatusChanged(success, message) {
            loadingIndicator.hide()
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
        
        function onPdfExportStatusChanged(success, message) {
            loadingIndicator.hide()
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
        
        function onSaveStatusChanged(success, message) {
            loadingIndicator.hide()
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }

    VoltageDropDetails {
        id: detailsPopup
        anchors.centerIn: Overlay.overlay
        
        onCloseRequested: detailsPopup.close()

        onSaveToPdfRequested: {
            loadingIndicator.show()
            voltageDrop.exportDetailsToPDF(null, {
                "voltage_system": detailsPopup.voltageSystem,
                "admd_enabled": detailsPopup.admdEnabled,
                "kva_per_house": detailsPopup.kvaPerHouse,
                "num_houses": detailsPopup.numHouses,
                "diversity_factor": detailsPopup.diversityFactor,
                "total_kva": detailsPopup.totalKva,
                "current": detailsPopup.current,
                "cable_size": detailsPopup.cableSize,
                "conductor_material": detailsPopup.conductorMaterial,
                "core_type": detailsPopup.coreType,
                "length": detailsPopup.length,
                "installation_method": detailsPopup.installationMethod,
                "temperature": detailsPopup.temperature,
                "grouping_factor": detailsPopup.groupingFactor,
                "combined_rating_info": detailsPopup.combinedRatingInfo,
                "voltage_drop": detailsPopup.voltageDropValue,
                "drop_percent": detailsPopup.dropPercentage
            })
        }
    }
}