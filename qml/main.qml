import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0

import QtQuick.Studio.DesignEffects

import Python 1.0
import Calculator 1.0
import Charging 1.0
import Fault 1.0
import Sine 1.0

import "../scripts/MaterialDesignRegular.js" as MD

import 'components'

ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true

    PythonModel {
        id: pythonModel
    }

    PowerCalculator {
        id: powerCalculator
    }

    ChargingCalc {
        id: chargingCalc
    }

    FaultCalculator {
        id: faultCalc
    }

    SineWaveModel {
        id: threePhaseSineModel
    }

    FontLoader {
        id: iconFont
        source: "../fonts/MaterialIcons-Regular.ttf"
    }

    ToolBar{
        id: toolBar
        width: parent.width
        onMySignal: sideBar.react()
    }
    
    SideBar {
        id: sideBar
        y: toolBar.height
        height: window.height - toolBar.height
    }

    Settings {
        id: settings
    }

    StackView {
        id: stackView
        anchors {
            top: toolBar.bottom
            bottom: parent.bottom
            left: parent.left
            leftMargin: 0
            right: parent.right
        }
        Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/home.qml"),StackView.Immediate)

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

    FileDialog {
        id: fileDialog
        title: "Select CSV File"
        nameFilters: ["CSV Files (*.csv)"]
        onAccepted: {
            if (fileDialog.selectedFile) {
                pythonModel.load_csv_file(fileDialog.selectedFile.toString().replace("file://", ""))
            }
        }
    }

    Universal.theme: toolBar.toggle ? Universal.Dark : Universal.Light
    Universal.accent: toolBar.toggle ? Universal.Red : Universal.Cyan
}
