/* Samurai Linux Calamares slideshow. */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Slide {
        Image {
            id: background1
            source: "slide1.png"
            width: 467
            height: 280
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: background1.horizontalCenter
            anchors.top: background1.bottom
            anchors.topMargin: 12
            text: qsTr("Install Samurai Linux on this computer.<br/>" +
                       "Your files will be kept intact if you choose manual partitioning.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
            color: "#F2EEE5"
        }
    }
}
