import QtQuick
import QtQuick.Controls
import QtQuick.Studio.Components 1.0

RoundButton {
    id: menuButton
    width: 350
    height: 60
    radius: 19
    property alias menuText: menu.text
    state: "state_idle"

    Rectangle {
        id: rectangle_18
        color: "#003c3c3c"
        radius: 19
        anchors.fill:parent
    }

    Text {
        id: menu
        color: "#ffffff"
        text: qsTr("Menu")
        anchors.fill: parent
        anchors.leftMargin: 74
        anchors.rightMargin: 11
        font.pixelSize: 20
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        font.weight: Font.Normal
        font.family: "Anaheim"
    }

    Rectangle {
        id: cube_small
        radius: 19
        color: "transparent"
        anchors.fill: parent
        anchors.leftMargin: 25
        anchors.rightMargin: 299
        anchors.topMargin: 17
        anchors.bottomMargin: 17
        SvgPathItem {
            id: cubePath
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 0
            anchors.bottomMargin: 0
            strokeWidth: 1
            strokeStyle: 1
            strokeColor: "transparent"
            path: "M 13.484976941888982 2.4677292018784507 C 13.176554333079945 2.328938883268905 12.823446793989701 2.328938883268905 12.515024185180664 2.4677292018784507 L 3.0604778853329746 6.722275222566977 C 2.636381723664024 6.913118549799919 2.3636363636363638 7.3349424096106075 2.3636363636363638 7.800000662239072 L 2.3636363636363638 18.26235742649593 C 2.3636363636363638 18.745607710784242 2.6578515551306983 19.180173093295792 3.106539249420166 19.359648795764393 L 12.561084140430799 23.141467981740718 C 12.84284253553911 23.25417044118301 13.15715859153054 23.25417044118301 13.43891698663885 23.141467981740718 L 22.893462441184305 19.359648795764393 C 23.342148867520418 19.18017422036547 23.636363636363637 18.745608837853922 23.636363636363637 18.26235742649593 L 23.636363636363637 7.800000662239072 C 23.636363636363637 7.334942973145446 23.36361954428933 6.913118549799919 22.939523523504086 6.722275222566977 L 13.484976941888982 2.4677292018784507 Z M 11.545071428472346 0.3122782520924048 C 12.470340381969105 -0.10409284461994134 13.529660745100543 -0.1040927037362317 14.454929698597303 0.3122783225342596 L 23.909475153142758 4.566824061455367 C 25.181763215498492 5.139354043154194 26 6.404827031423355 26 7.800000662239072 L 26 18.26235742649593 C 26 19.712110533500223 25.11735569347035 21.015805553965187 23.77129416032271 21.554231534301316 L 14.316749832846902 25.336048466138287 C 13.471474647521973 25.674158098604522 12.528527606617322 25.674158098604522 11.683252421292392 25.336048466138287 L 2.2287066849795254 21.554231534301316 C 0.8826454335992986 21.015805553965187 0 19.712110533500223 0 18.26235742649593 L 0 7.800000662239072 C 0 6.404827031423355 0.8182363618503918 5.139354043154194 2.0905251286246562 4.566824061455367 L 11.545071428472346 0.3122782520924048 Z M 5.337066997181286 9.706528059744334 C 5.579472910274159 9.100510865563662 6.267255891453137 8.805745585650584 6.873273069208319 9.048151434871773 L 12.999907580288975 11.498795387513397 L 19.12676863236861 9.048146363058226 C 19.732789473100144 8.80574769890623 20.420569073070183 9.100521431841885 20.662966814908117 9.70654158458046 C 20.9053656838157 10.312561737319035 20.61059076135809 11.00034121504694 20.004571047696203 11.242739808757083 L 14.181732524525037 13.571784213924516 L 14.18183283372359 19.33734183271305 C 14.181844104420056 19.990041971156344 13.652735059911555 20.519169063120653 13.000034939159047 20.519180333817424 C 12.347334818406539 20.519191604514194 11.818207740783691 19.990081982129887 11.818196470087225 19.337382407221433 L 11.818096160888672 13.571785340994193 L 5.995443604209207 11.242734173408696 C 5.389426426454024 11.000328253745653 5.094661154530265 10.312545253925007 5.337066997181286 9.706528059744334 Z"
            joinStyle: 0
            fillColor: "#ffffff"
            antialiasing: true
        }
    }
    states: [
        State {
            name: "state_hover"

            PropertyChanges {
                target: rectangle_18
                color: "#2e3c3c3c"
            }
        },
        State {
            name: "state_selected"

            PropertyChanges {
                target: rectangle_18
                color: "#9e3c3c3c"
            }
        },
        State {
            name: "state_idle"

            PropertyChanges {
                target: rectangle_18
                color: "#003c3c3c"
            }
        }
    ]
}