/*
 * Copyright (C) 2016
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

import QtQuick 2.4
import Ubuntu.Components 1.3

Image {
    id: container

    smooth: true
    visible: styledItem.running && styledItem.visible
    fillMode: Image.PreserveAspectFit
    horizontalAlignment: Image.AlignHCenter
    verticalAlignment: Image.AlignVCenter
    source: visible ? Qt.resolvedUrl("../../graphics/spinner.png") : ""
    asynchronous: true

    RotationAnimator on rotation {
        running: styledItem.running
        from: 0
        to: 360
        loops: Animation.Infinite
        duration: 1000 /*UbuntuAnimation.SleepyDuration*/
    }
}
