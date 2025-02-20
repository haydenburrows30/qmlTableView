import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import '../components'

import Python 1.0
    
Page {
    id: voltage_drop

    DialogOnTop {
        id: chart
        visible:false
    }

    function updateChart() {

        barSeries.clear()
        let categories = []
        let maxPercentVoltageDrop = 0  // Track highest voltage drop

        for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
            let entry = pythonModel.chart_data_qml[i]
            // create new barset for each cable type
            let example = barSeries.append(entry.cable, [entry.percentage_drop])
            // set label font and colour
            example.labelFont = Qt.font({pointSize: 12}); //bold:true
            example.labelColor = "black"

            // Track the highest voltage drop to set the Y-axis max value
            if (entry.percentage_drop > maxPercentVoltageDrop) {
                maxPercentVoltageDrop = entry.percentage_drop
            }
        }

        axisX.categories = ["Aluminium"] // ,"Copper"

        // Dynamically adjust Y-axis scale
        axisY.max = maxPercentVoltageDrop * 1.4  // Add 20% buffer for visibility
        axisY.min = 0
    }

    MouseArea {
        id: area
        anchors.fill: parent

        onClicked:  {
            sideBar.close()
            }
    }

    MenuPanel {
        id: draggablePanel
        x: Math.round((window.width - width) / 2)
        y: Math.round(window.height / 6)
        width: 200
        height: 400
        z: 99
        visible: false
        DragHandler {
            xAxis.minimum: 0
            yAxis.minimum: 0
            xAxis.maximum: voltage_drop.width - draggablePanel.width
            yAxis.maximum: voltage_drop.height - draggablePanel.height
        }

        DesignEffect {
            backgroundBlurRadius: 500
            backgroundLayer: parent
            effects: [
                DesignDropShadow {}
            ]
        }
    }

    GroupBox {
        id: settings
        title: 'Settings'
        width: 250
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        Component.onCompleted: {
            settings.width = columnLayout.width + 25
        }
        
        ColumnLayout {
            id: columnLayout

            Label {
                text: "Voltage Drop Threshold (%):"
            }
            TextField {
                id: voltageDropThresholdField
                text: "5"
                onTextChanged: pythonModel.voltageDropThreshold = text
                Layout.fillWidth: true
            }

            Label {
                text: "Power Factor:"
            }
            Row {
                Layout.fillWidth : true

                Slider {
                    // width: parent.width / 0.9
                    id: powerFactorSlider
                    from: 0.5
                    to: 1.0
                    value: 0.8
                    stepSize: 0.01
                    onValueChanged: {
                        pythonModel.powerFactor = value
                        pythonModel.update_chart(0)
                        updateChart()
                        pythonModel.calculateResistance(0)
                    }
                }
            }
            Label {
                text: "Current:"
            }
            TextField {
                id: currentField
                text: "0"
                onTextChanged: pythonModel.current = text
                Layout.fillWidth: true
            }
            Button {
                text: "Options"
                Layout.fillWidth: true

                ToolTip {
                    text: "Options"
                }
                onClicked: {
                    draggablePanel.visible == false ? draggablePanel.visible = true:draggablePanel.visible = false
                    // chart.visible = true

                }
            }
        }
    }

    GroupBox {
        id: table
        title: 'Table'
        width: 960
        height: 180
        anchors {
            left: settings.right
            top: parent.top
            leftMargin: 20
            topMargin: 10
        }
        
        RowLayout {
            id: buttons
            width: parent.width
            anchors.bottomMargin: 10

            Button {
                text: qsTr("Add Row")
                Layout.fillWidth: true
                onClicked: {
                    tableView.closeEditor()
                    pythonModel.appendRow()
                    rect.height = rect.height + 51
                    table.height = table.height + 51
                }
            }
            Button {
                text: qsTr("Remove Row")
                onClicked: {
                    if (pythonModel.rowCount() > 1) {
                        pythonModel.removeRows(pythonModel.rowCount() - 1)
                        rect.height = rect.height - 51
                        table.height = table.height - 51
                    }
                }
                 Layout.fillWidth: true
            }
            Button {
                text: qsTr("Clear Rows")
                onClicked: {
                    rect.height = 85
                    table.height = 180
                    pythonModel.clearAllRows()
                }
                Layout.fillWidth: true
            }
            Button {
                text: qsTr("Load CSV")
                onClicked: fileDialog.open()
                Layout.fillWidth: true
            }
        }

        Rectangle {
            id: rect
            anchors.top: buttons.bottom
            anchors.topMargin: 10
            width: 930
            height: 85

            color: palette.dark

            HorizontalHeaderView {
                id: horizontalHeader
                anchors.left: tableView.left
                anchors.top: parent.top
                syncView: tableView
                clip: true
            }

            VerticalHeaderView {
                id: verticalHeader
                anchors.top: tableView.top
                anchors.left: parent.left
                syncView: tableView
                clip: true
            }

            TableView {
                id: tableView
                anchors {
                    left: verticalHeader.right
                    top: horizontalHeader.bottom
                    right: parent.right
                    bottom: parent.bottom
                }
                
                clip: true
                interactive: true
                model: pythonModel
                selectionModel: ItemSelectionModel {}

                columnSpacing: 1
                rowSpacing: 1

                delegate: DelegateChooser {
                    role: "roleValue"

                    DelegateChoice {
                        roleValue: "dropdown"
                        delegate: ComboBox {
                            id: comboBox
                            implicitWidth: 100
                            implicitHeight: 50
                            model: pythonModel ? pythonModel.cable_types : []

                            currentIndex: {
                                var modelData = TableView.view.model ? TableView.view.model.data(TableView.view.index(row, column)).toString() : ""
                                var index = model.indexOf(modelData)
                                return index !== -1 ? index : 0
                            }
                            onCurrentIndexChanged: {
                                if (TableView.view.model) {
                                    TableView.view.model.setData(TableView.view.index(row, column), model[currentIndex])
                                    for (var r = 0; r < TableView.view.model.rowCount(); r++) {
                                        var rowData = []
                                        for (var c = 0; c < TableView.view.model.columnCount(); c++) {
                                            rowData.push(TableView.view.model.data(TableView.view.model.index(r, c)))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "number"
                        delegate: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 50
                            color: TableView.view.model && parseFloat(TableView.view.model.data(TableView.view.index(row, 6))) > pythonModel.voltageDropThreshold ? "red" : palette.base

                            Text {
                                anchors.centerIn: parent
                                text: display
                            }

                            TableView.editDelegate: TextField {
                                anchors.fill: parent
                                text: display

                                onTextChanged: {
                                    if (text !== display) {
                                        if (TableView.view.model) {
                                            TableView.view.model.setData(TableView.view.index(row, column), text)
                                            display = text
                                        }
                                    }
                                }

                                TableView.onCommit: {
                                    display = text
                                    focus = false
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "button"
                        delegate: Button {
                            text: "Calculate"
                            onClicked: {
                                tableView.closeEditor()
                                pythonModel.calculateResistance(row)
                                pythonModel.update_chart(row)
                                updateChart()
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "resistance"
                        delegate: TextField {
                            implicitWidth: 100
                            implicitHeight: 50
                            text: display
                            readOnly: true
                        }
                    }

                    DelegateChoice {
                        roleValue: "length"
                        delegate: TextField {
                            implicitWidth: 100
                            implicitHeight: 50
                            text: display
                            // selectByMouse: true

                            onTextChanged: {
                                if (text !== display) {
                                    if (TableView.view.model) {
                                        TableView.view.model.setData(TableView.view.index(row, column), text)
                                        display = text
                                    }
                                }
                            }

                            TableView.onCommit: {
                                display = text
                                focus = false
                            }
                        }
                    }
                }
            }
        }
    }

    ChartView {
        id: barChart
        anchors.top: table.bottom
        anchors.bottom: parent.bottom
        // anchors.right: parent.right
        anchors.left: settings.right
        width: table.width
        // height: 350
        // anchors.fill: parent
        Layout.rowSpan: 10
        title: "% Voltage Drop vs Cable Type"
        antialiasing: true
        legend.alignment: Qt.AlignBottom
        titleFont {
            pointSize: 13
            bold: true
        }

        BarCategoryAxis {
            id: axisX
            // titleText: "Cable Type"
        }

        ValueAxis {
            id: axisY
            titleText: "Voltage Drop (%)"
            min: 0
            max: 10
        }

        HoverHandler {
            id: stylus
            acceptedPointerTypes: PointerDevice.AllPointerTypes
        }

        BarSeries {
            id: barSeries
            axisX: axisX
            axisY: axisY
            labelsVisible: true
            labelsPosition: AbstractBarSeries.LabelsOutsideEnd
            labelsPrecision: 2
            labelsAngle: 90
            labelsFormat: "@value %"
            barWidth: 0.9

            onHovered: (status, index, barset) => {
                if (status) {
                    tooltiptext.text = barset.label + ": " + barset.at(index).toFixed(2) + " V"
                    tooltip.visible = true
                    tooltip.x = stylus.point.position.x
                    tooltip.y = stylus.point.position.y - 20
                    tooltip.visible = true
                } else {
                    tooltip.visible = false
                }
            }
        }

        Rectangle {
            id: tooltip
            visible: false
            color: "#333"
            radius: 5
            opacity: 0.8
            width: 100
            height: 40
            Text {
                id: tooltiptext
                anchors.fill: parent
                text: ""
                font.pixelSize: 14
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}