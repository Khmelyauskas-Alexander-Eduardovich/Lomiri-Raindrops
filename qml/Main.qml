/*
 * Copyright (C) 2025  JasonWalt Bab@
 * NO SHIT OR FUCKED SCUM HERE, USE, MODIFY OR ENJOY!!!
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * raindrops is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Window {
    id: window
    visible: true
    width: 600
    height: 900
    color: transparentWindow ? "transparent" : "black"
    property bool transparentWindow: true
    property bool fullscreen: false
    property int colorMode: 0       // 0=обычный, 1=радужный, 2=рандом, 3=гладкий
    property real hue: 0            // для режима 3
    property string rainbowAxis: "Y" // "X" или "Y" для радужного режима
    property int r: 0
    property int g: 100
    property int b: 255
    property real avgSpeed: 4       // средняя скорость капель
    property int dropCount: 150     // количество капель
    property real autohideDuration: 5000 //in ms, and in sec = 5 secs
    Canvas {
        id: canvas
        anchors.fill: parent
        property var drops: generateDrops(dropCount)

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, canvas.width, canvas.height)

            for (var i = 0; i < drops.length; i++) {
                var d = drops[i]
                d.y += d.speed
                if (d.y > canvas.height) d.y = -d.length

                var colorStr;
                switch(colorMode) {
                    case 0: colorStr = "rgba("+r+","+g+","+b+",1)"; break
                    case 1:
                        var hueVal = rainbowAxis==="Y" ? (d.y/canvas.height)*360 : (d.x/canvas.width)*360
                        colorStr = hslToRgb(hueVal, 100, 50)
                        break
                    case 2:
                        if(d.randomChange) {
                            d.color = "rgba(" + Math.floor(Math.random()*256) + "," +
                                        Math.floor(Math.random()*256) + "," +
                                        Math.floor(Math.random()*256) + ",1)"
                            d.targetSpeed = 1 + Math.random()*avgSpeed
                            d.speed += (d.targetSpeed - d.speed) * 0.05  // плавное изменение скорости
                            d.y += d.speed

                        }
                        colorStr = d.color;
                        break
                    case 3: colorStr = hslToRgb(hue, 100, 50); break
                }

                var gradient = ctx.createLinearGradient(d.x, d.y, d.x, d.y + d.length)
                gradient.addColorStop(0, "rgba(0,0,0,0)")
                gradient.addColorStop(1, colorStr)
                ctx.strokeStyle = gradient
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(d.x, d.y)
                ctx.lineTo(d.x, d.y + d.length)
                ctx.stroke()
            }
        }

        Timer {
            interval: 16; running: true; repeat: true
            onTriggered: {
                if (colorMode === 3) {
                    hue += 0.5
                    if (hue > 360) hue = 0
                }
                canvas.requestPaint()
            }
        }

        function generateDrops(count) {
            var arr = []
            for (var i = 0; i < count; i++) {
                arr.push({
                    x: Math.random()*canvas.width,
                    y: Math.random()*canvas.height,
                    length: 10 + Math.random()*20,
                    speed: 1 + Math.random()*avgSpeed,
                    color: "rgba(" + Math.floor(Math.random()*256) + "," +
                                  Math.floor(Math.random()*256) + "," +
                                  Math.floor(Math.random()*256) + ",1)",
                    randomChange: Math.random() > 0.5
                })
            }
            return arr
        }

        function hslToRgb(h, s, l) {
            s /= 100; l /= 100
            let c = (1 - Math.abs(2*l - 1)) * s
            let x = c * (1 - Math.abs((h / 60) % 2 - 1))
            let m = l - c/2
            let r1=0,g1=0,b1=0
            if (0<=h && h<60){r1=c; g1=x; b1=0}
            else if(60<=h && h<120){r1=x; g1=c; b1=0}
            else if(120<=h && h<180){r1=0; g1=c; b1=x}
            else if(180<=h && h<240){r1=0; g1=x; b1=c}
            else if(240<=h && h<300){r1=x; g1=0; b1=c}
            else {r1=c; g1=0; b1=x}
            r1=Math.round((r1+m)*255); g1=Math.round((g1+m)*255); b1=Math.round((b1+m)*255)
            return "rgba("+r1+","+g1+","+b1+",1)"
        }
        MouseArea {
        anchors.fill: parent
onDoubleClicked: {
    controls.opacity = 1
    hider.restart()
}
        }
    }
    // Панель управления
    Item {
        id: controls
        opacity: hider ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

    Column {
        spacing: 5
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        Row {
            spacing: 5
            Label { text: qsTr("Mode:"); color: "white" }
            ComboBox {
                model: [qsTr("Default"), qsTr("Rainbow"), qsTr("Random"), qsTr("Smooth")]
                currentIndex: colorMode
                onCurrentIndexChanged: colorMode = currentIndex
            }
        }

        // RGB слайдеры для режима 0
        Row { spacing: 5
            Label { text: qsTr("R"); color:"white" }
            Slider { from:0; to:255; value: r; onValueChanged: r=value; enabled: colorMode===0 }
            Label { text: r.toFixed(0); color:"white" }
        }
        Row { spacing: 5
            Label { text: qsTr("G"); color:"white" }
            Slider { from:0; to:255; value: g; onValueChanged: g=value; enabled: colorMode===0 }
            Label { text: g.toFixed(0); color:"white" }
        }
        Row { spacing: 5
            Label { text: qsTr("B"); color:"white" }
            Slider { from:0; to:255; value: b; onValueChanged: b=value; enabled: colorMode===0 }
            Label { text: b.toFixed(0); color:"white" }
        }

        // Свитч направления радужного режима
        Row { spacing: 5
            Label { text:qsTr("Rainbow Axis"); color:"white" }
            ComboBox {
                model: ["X", "Y"]
                currentIndex: rainbowAxis==="X"?0:1
                onCurrentIndexChanged: rainbowAxis = currentIndex===0?"X":"Y"
                enabled: colorMode===1
            }
        }

        // Скорость
        Row { spacing: 5
            Label { text: qsTr("Speed"); color:"white" }
            Slider { from:1; to:10; value: avgSpeed; onValueChanged: avgSpeed=value
                onMoved: {
                    for(var i=0;i<canvas.drops.length;i++) {
                        canvas.drops[i].speed = Math.random()*avgSpeed + 1
                    }
                }
            }
            Label { text: avgSpeed.toFixed(1); color:"white" }
        }

        // Количество капель
        Row { spacing: 5
            Label { text: qsTr("Count"); color:"white" }
            Slider { from:50; to:500; value: dropCount; onValueChanged: dropCount=value
                onMoved: canvas.drops = canvas.generateDrops(dropCount)
            }
            Label { text: dropCount.toFixed(0); color:"white" }
        }
        //Fullscreen
        Row { spacing: 5
            Label { text: qsTr("Fullscreen Mode"); color:" white " }
        Switch {
        onCheckedChanged: {
            fullscreen = !fullscreen
            if (fullscreen)
        window.showFullScreen();
            if (!fullscreen)
                window.showNormal()
        }
        }
        }
        //Transparent Window
        Row { spacing: 5
            Label { text: qsTr("Transparent Window"); color:" white " }
        Switch {
            id: twToggle
            checked: true
        onCheckedChanged: {
transparentWindow = checked
        }
        }
        }
        Row { spacing: 5
            Label { text: qsTr("Autohide Duration"); color:"white" }
            Slider { from:1000; to:10000; value: 5000; onValueChanged: autohideDuration =value}
            Label { text: autohideDuration.toFixed(0); color:"white" }
        }
        Timer {
        id: hider
        interval: autohideDuration
        running: true
        repeat: false
        onTriggered: controls.opacity = 0
        }
    }
    }
}
