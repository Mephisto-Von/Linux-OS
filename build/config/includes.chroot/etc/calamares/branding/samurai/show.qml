/* Samurai Linux Calamares slideshow. */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#111214"
        }
        Image {
            id: background1
            source: "slide1.png"
            width: Math.min(parent.width * 0.6, 520)
            height: width * 0.5
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40
        }
        Text {
            anchors.horizontalCenter: background1.horizontalCenter
            anchors.top: background1.bottom
            anchors.topMargin: 16
            text: qsTr("<b>Samurai Linux</b><br/>A sleek, powerful, and secure operating system")
            wrapMode: Text.WordWrap
            width: parent.width * 0.8
            horizontalAlignment: Text.Center
            color: "#F2EEE5"
            font.pixelSize: 16
        }
    }

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#111214"
        }
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -30
            text: qsTr("<b>Built for Developers</b><br/><br/>KDE Plasma desktop with Samurai themes<br/>Pre-configured development tools<br/>Optimized for performance")
            wrapMode: Text.WordWrap
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            color: "#F2EEE5"
            font.pixelSize: 15
            lineHeight: 1.4
        }
    }

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#111214"
        }
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -30
            text: qsTr("<b>Ready to Go</b><br/><br/>Your files remain safe with careful partitioning<br/>Complete with all essentials out of the box")
            wrapMode: Text.WordWrap
            width: parent.width * 0.7
            horizontalAlignment: Text.Center
            color: "#F2EEE5"
            font.pixelSize: 15
            lineHeight: 1.4
        }
    }
}
