
/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
 *
 * Author: Prince Gupta <guptaprince8832@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

import QtQuick 2.11

DragItem {
    id: root

    /* required */ property var mlModel: null

    // string => role for medialib id, data[id] will be pass to Medialib::mlInputItem for QmlInputItem
    property string mlIDRole: "id"

    function getSelectedInputItem() {
        var inputs = []

        for (var i in indexes) {
            var inputItems = _getInputItem(i, indexesData[i])
            console.assert(inputItems instanceof Array)

            inputs = inputs.concat(inputItems)
        }

        return inputs
    }

    onRequestData: {
        mlModel.getData(indexes, function (data) {
            root.setData(identifier, data)
        })
    }

    function _getInputItem(index, data) {
        console.assert(mlIDRole)
        return medialib.mlInputItem(data[mlIDRole])
    }

}
