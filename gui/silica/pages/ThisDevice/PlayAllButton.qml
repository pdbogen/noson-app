/*
 * Copyright (C) 2019
 *      Jean-Luc Barriere <jlbarriere68@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import "../../components"

MusicIcon {
    height: units.gu(5)
    width: units.gu(20)
    source: "image://theme/icon-m-media"
    label {
        //: this appears in a button with limited space (around 14 characters)
        text: qsTr("Play all")
        font.pixelSize: units.fx("medium")
        width: parent.width - units.gu(6)
        elide: Text.ElideRight
    }

    property var model

    onClicked: {
        delayPlayAll.start()
    }

    Timer {
        id: delayPlayAll
        interval: 100
        onTriggered: {
            var items = makeContainerPayloads(model);
            if (items.length > 0 && playAll(items[0])) {
                addMultipleItemsToQueue(items.slice(1, items.length));
            }
        }
    }
}
