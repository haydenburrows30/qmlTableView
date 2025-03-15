import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls.Universal

import components 1.0

Rectangle {
    id: root
    
    // Properties
    property real activePower: sineModel.activePower
    property real reactivePower: sineModel.reactivePower
    property real apparentPower: sineModel.apparentPower
    property real powerFactor: sineModel.averagePowerFactor
    property color textColor: Universal.foreground
    
    // Scaling properties
    property real triangleScale: 100
    property real minPowerValue: 0.1
    property real maxPowerValue: 2000
    property real minScale: 400
    property real padding: 10
    property real labelPadding: 40

    // Container for triangle and labels
    Item {
        id: triangleContainer
        anchors.fill: parent
        anchors.margins: 1
        // anchors.bottom: parent.bottom

        // Calculate triangle dimensions
        property real baseLength: activePower * triangleScale
        property real triangleHeight: reactivePower * triangleScale
        property real maxSize: Math.min(width * 1, height * 1)

        // Calculate hypotenuse length using Pythagorean theorem
        property real hypotenuseLength: Math.sqrt(baseLength * baseLength + triangleHeight * triangleHeight)
        
        // Scale factor to fit triangle within container
        property real scaleFactor: Math.min(
            maxSize / Math.max(baseLength, 1),
            maxSize / Math.max(triangleHeight, 1)
        )

        // Triangle shape
        Shape {
            id: triangle
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            ShapePath {
                strokeWidth: 2
                strokeColor: "black"
                fillColor: "transparent"
                
                // Start at origin point
                startX: 0
                startY: 0
                
                // Draw active power (horizontal line)
                PathLine {
                    x: triangleContainer.baseLength * triangleContainer.scaleFactor
                    y: 0
                }
                
                // Draw hypotenuse
                PathLine {
                    x: 0
                    y: -triangleContainer.triangleHeight * triangleContainer.scaleFactor
                }
                
                // Close triangle
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // Labels with dynamic positioning
        Text {
            id: activePowerLabel
            anchors.top: triangle.bottom
            anchors.horizontalCenter: triangle.horizontalCenter
            anchors.topMargin: 10
            text: "P = " + activePower.toFixed(1) + " kW"
            color: root.textColor
        }
        
        Text {
            id: reactivePowerLabel
            anchors.right: triangle.left
            anchors.verticalCenter: triangle.verticalCenter
            anchors.rightMargin: 10
            text: "Q = " + reactivePower.toFixed(1) + " kVAR"
            color: root.textColor
        }

        // Direct Text element approach for apparent power label
        Item {
            id: apparentPowerLabelContainer
            anchors.fill: parent
            
            // Calculate midpoint of hypotenuse
            property real centerX: width / 2
            property real centerY: height / 2
            property real scaledHeight: triangleContainer.triangleHeight * triangleContainer.scaleFactor
            property real scaledBase: triangleContainer.baseLength * triangleContainer.scaleFactor
            property real startX: centerX + scaledBase
            property real startY: centerY - scaledHeight
            property real endX: centerX + scaledBase
            property real endY: centerY
            property real midX: (startX + endX) / 2
            property real midY: (startY + endY) / 2
            property real angleRadians: Math.atan2(startY - endY, endX - startX)
            property real angleDegrees: angleRadians * 180 / Math.PI
            
            Text {
                id: apparentPowerText
                text: "S = " + apparentPower.toFixed(1) + " kVA"
                anchors.centerIn: parent
                
                // Position at midpoint of hypotenuse
                x: parent.midX - width/2 - parent.centerX
                y: parent.midY - height/2 - parent.centerY - 15 // Offset above line
                
                // Apply rotation to align with hypotenuse
                transformOrigin: Item.Center
                rotation: parent.angleDegrees
                visible: false // Hide this, used as reference
                color: root.textColor
            }
            
            // Draw using Canvas for perfect alignment
            Canvas {
                id: apparentPowerCanvas
                anchors.fill: parent
                property string powerText: "S = " + apparentPower.toFixed(1) + " kVA"
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Get coordinates
                    var centerX = width / 2;
                    var centerY = height / 2;
                    var scaledBase = triangleContainer.baseLength * triangleContainer.scaleFactor;
                    var scaledHeight = triangleContainer.triangleHeight * triangleContainer.scaleFactor;
                    
                    // Start is the top vertex of the triangle
                    var startX = centerX;
                    var startY = centerY - scaledHeight;
                    
                    // End is the right vertex of the triangle
                    var endX = centerX + scaledBase;
                    var endY = centerY;
                    
                    // Find midpoint of the hypotenuse
                    var midX = (startX + endX) / 2;
                    var midY = (startY + endY) / 2;
                    
                    // Calculate the slope of the hypotenuse
                    var angle = Math.atan2(endY - startY, endX - startX);
                    
                    // Calculate perpendicular offset for text placement
                    var offsetDistance = 5; // Reduced from 10 to 5 for closer positioning to the hypotenuse
                    var offsetX = -Math.sin(angle) * offsetDistance;
                    var offsetY = Math.cos(angle) * offsetDistance;
                    
                    // Position at midpoint of hypotenuse with reduced offset
                    ctx.save();
                    ctx.translate(midX + offsetX, midY + offsetY);
                    
                    // Rotate to align with hypotenuse
                    ctx.rotate(angle);
                    
                    // Set text properties
                    ctx.font = "14px sans-serif";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillStyle = sideBar.toggle1 ? "#ffffff" : "#000000";
                    
                    // Draw text aligned with the hypotenuse
                    ctx.fillText(powerText, 0, 0);
                    ctx.restore();
                }
            }
        }

        Text {
            id: powerFactorLabel
            anchors.right: triangle.right
            anchors.bottom: triangle.bottom
            anchors.margins: 10
            text: "PF = " + powerFactor.toFixed(3)
            font.bold: true
            color: root.textColor
        }

        // Angle arc
        Shape {
            id: angleArc
            anchors.fill: triangle

            ShapePath {
                strokeWidth: 1
                strokeColor: "blue"
                fillColor: "transparent"
                
                PathArc {
                    x: 30
                    y: 0
                    radiusX: 30
                    radiusY: 30
                    useLargeArc: false
                }
            }
        }

        // Angle label
        Text {
            anchors.left: triangle.left
            anchors.bottom: triangle.bottom
            anchors.margins: 25
            text: "φ = " + (Math.acos(powerFactor) * 180 / Math.PI).toFixed(1) + "°"
            font.italic: true
            color: root.textColor
        }
    }

    // Update the canvas when the triangle values change
    onActivePowerChanged: apparentPowerCanvas.requestPaint()
    onReactivePowerChanged: apparentPowerCanvas.requestPaint()
    onApparentPowerChanged: apparentPowerCanvas.requestPaint()
    onWidthChanged: apparentPowerCanvas.requestPaint()
    onHeightChanged: apparentPowerCanvas.requestPaint()
}