/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Controls 2.4
import org.videolan.vlc 0.1

import "qrc:///style/"
import "qrc:///util/Helpers.js" as Helpers

FocusScope {
    id: listview_id

    // Properties

    property int modelCount: view.count

    property alias listView: view

    property int highlightMargin: VLCStyle.margin_large

    property var fadeColor: undefined

    // NOTE: We want buttons to be centered verticaly but configurable.
    property int buttonMargin: height / 2 - buttonLeft.height / 2

    property int scrollBarWidth: scroll_id.visible ? scroll_id.width : 0

    property bool keyNavigationWraps : false

    // Private

    property int _currentFocusReason: Qt.OtherFocusReason

    // Aliases

    //forward view properties
    property alias spacing: view.spacing
    property alias interactive: view.interactive
    property alias model: view.model
    property alias delegate: view.delegate

    property alias leftMargin: view.leftMargin
    property alias rightMargin: view.rightMargin
    property alias topMargin: view.topMargin
    property alias bottomMargin: view.bottomMargin

    property alias originX: view.originX
    property alias originY: view.originY

    property alias contentX: view.contentX
    property alias contentY:  view.contentY
    property alias contentHeight: view.contentHeight
    property alias contentWidth: view.contentWidth

    property alias footer: view.footer
    property alias footerItem: view.footerItem
    property alias header: view.header
    property alias headerItem: view.headerItem
    property alias headerPositioning: view.headerPositioning

    property alias currentIndex: view.currentIndex
    property alias currentItem: view.currentItem

    property alias highlightMoveVelocity: view.highlightMoveVelocity

    property alias section: view.section
    property alias currentSection: view.currentSection
    property alias orientation: view.orientation

    property alias add: view.add
    property alias displaced: view.displaced

    property alias displayMarginBeginning: view.displayMarginBeginning
    property alias displayMarginEnd: view.displayMarginEnd

    property alias fadeRectBottomHovered: fadeRectBottom.isHovered
    property alias fadeRectTopHovered: fadeRectTop.isHovered

    property alias listScrollBar: scroll_id

    property alias buttonLeft: buttonLeft
    property alias buttonRight: buttonRight

    // Signals

    signal selectionUpdated(int keyModifiers, int oldIndex, int newIndex)

    signal selectAll()

    signal actionAtIndex(int index)

    signal deselectAll()

    signal showContextMenu(point globalPos)

    // Settings

    Accessible.role: Accessible.List

    // Events

    onCurrentItemChanged: {
        if (_currentFocusReason === Qt.OtherFocusReason)
            return;

        // NOTE: We make sure the view has active focus before enforcing it on the item.
        if (view.activeFocus && currentItem)
            Helpers.enforceFocus(currentItem, _currentFocusReason);

        _currentFocusReason = Qt.OtherFocusReason;
    }

    // Functions

    function setCurrentItemFocus(reason) {
        if (!model || model.count === 0) {
            // NOTE: By default we want the focus on the flickable.
            view.forceActiveFocus(reason);

            // NOTE: Saving the focus reason for later.
            _currentFocusReason = reason;

            return;
        }

        if (currentIndex === -1)
            currentIndex = 0;

        positionViewAtIndex(currentIndex, ItemView.Contain);

        Helpers.enforceFocus(currentItem, reason);
    }

    function nextPage() {
        view.contentX += (Math.min(view.width, (view.contentWidth - view.width - view.contentX)))
    }
    function prevPage() {
        view.contentX -= Math.min(view.width,view.contentX - view.originX)
    }

    function positionViewAtIndex(index, mode) {
        view.positionViewAtIndex(index, mode)
    }

    function itemAtIndex(index) {
        return view.itemAtIndex(index)
    }

    // Events

    Component {
        id: sectionHeading

        Column {
            width: parent.width

            Text {
                text: section
                font.pixelSize: VLCStyle.fontSize_xlarge
                color: VLCStyle.colors.accent
            }

            Rectangle {
                width: parent.width
                height: 1
                color: VLCStyle.colors.textDisabled
            }
        }
    }

    // Connections

    // FIXME: This is probably not useful anymore.
    Connections {
        target: view.headerItem
        onFocusChanged: {
            if (!headerItem.focus) {
                currentItem.focus = true
            }
        }
    }

    // Children

    ListView {
        id: view

        anchors.fill: parent

        focus: true

        //key navigation is reimplemented for item selection
        keyNavigationEnabled: false

        ScrollBar.vertical: ScrollBar { id: scroll_id }
        ScrollBar.horizontal: ScrollBar { visible: view.contentWidth > view.width }

        highlightMoveDuration: 300 //ms
        highlightMoveVelocity: 1000 //px/s

        section.property: ""
        section.criteria: ViewSection.FullString
        section.delegate: sectionHeading

        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds

        MouseEventFilter {
            target: view

            onMouseButtonPress: {
                if (buttons & (Qt.LeftButton | Qt.RightButton)) {
                    Helpers.enforceFocus(view, Qt.MouseFocusReason)

                    if (!(modifiers & (Qt.ShiftModifier | Qt.ControlModifier))) {
                        listview_id.deselectAll()
                    }
                }
            }

            onMouseButtonRelease: {
                if (button & Qt.RightButton) {
                    listview_id.showContextMenu(globalPos)
                }
            }
        }

        // NOTE: We always want a valid 'currentIndex' by default.
        onCountChanged: if (count && currentIndex === -1) currentIndex = 0

        Keys.onPressed: {
            var newIndex = -1

            if (orientation === ListView.Vertical)
            {
                if ( KeyHelper.matchDown(event) ) {
                    if (currentIndex !== modelCount - 1 )
                        newIndex = currentIndex + 1
                    else if ( listview_id.keyNavigationWraps )
                        newIndex = 0
                } else if ( KeyHelper.matchPageDown(event) ) {
                    newIndex = Math.min(modelCount - 1, currentIndex + 10)
                } else if ( KeyHelper.matchUp(event) ) {
                    if ( currentIndex !== 0 )
                        newIndex = currentIndex - 1
                    else if ( listview_id.keyNavigationWraps )
                        newIndex = modelCount - 1
                } else if ( KeyHelper.matchPageUp(event) ) {
                    newIndex = Math.max(0, currentIndex - 10)
                }
            }else{
                if ( KeyHelper.matchRight(event) ) {
                    if (currentIndex !== modelCount - 1 )
                        newIndex = currentIndex + 1
                    else if ( listview_id.keyNavigationWraps )
                        newIndex = 0
                }
                else if ( KeyHelper.matchPageDown(event) ) {
                    newIndex = Math.min(modelCount - 1, currentIndex + 10)
                } else if ( KeyHelper.matchLeft(event) ) {
                    if ( currentIndex !== 0 )
                        newIndex = currentIndex - 1
                    else if ( listview_id.keyNavigationWraps )
                        newIndex = modelCount - 1
                } else if ( KeyHelper.matchPageUp(event) ) {
                    newIndex = Math.max(0, currentIndex - 10)
                }
            }

            if (KeyHelper.matchOk(event) || event.matches(StandardKey.SelectAll) ) {
                //these events are matched on release
                event.accepted = true
            }

            if (newIndex >= 0 && newIndex < modelCount) {
                event.accepted = true;

                var oldIndex = currentIndex;

                currentIndex = newIndex;

                selectionUpdated(event.modifiers, oldIndex, newIndex);

                // NOTE: We make sure we have the proper visual focus on components.
                if (oldIndex < currentIndex)
                    Helpers.enforceFocus(currentItem, Qt.TabFocusReason);
                else
                    Helpers.enforceFocus(currentItem, Qt.BacktabFocusReason);
            }

            if (!event.accepted) {
                listview_id.Navigation.defaultKeyAction(event)
            }
        }

        Keys.onReleased: {
            if (event.matches(StandardKey.SelectAll)) {
                event.accepted = true
                selectAll()
            } else if ( KeyHelper.matchOk(event) ) { //enter/return/space
                event.accepted = true
                actionAtIndex(currentIndex)
            }
        }

        readonly property bool _fadeRectsOverlap: fadeRectTop.y + fadeRectTop.height > fadeRectBottom.y

        Rectangle {
            id: fadeRectTop
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: headerItem && (headerPositioning === ListView.OverlayHeader) ? headerItem.height : 0
            }
            height: highlightMargin * 2
            visible: !!fadeColor && fadeRectTop.opacity !== 0.0 && !view._fadeRectsOverlap

            property bool isHovered: false
            property bool _stateVisible: ((orientation === ListView.Vertical && !view.atYBeginning)
                                        && !isHovered)

            states: [
                State {
                    when: fadeRectTop._stateVisible;
                    PropertyChanges {
                        target: fadeRectTop
                        opacity: 1.0
                    }
                },
                State {
                    when: !fadeRectTop._stateVisible;
                    PropertyChanges {
                        target: fadeRectTop
                        opacity: 0.0
                    }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    property: "opacity"
                    duration: VLCStyle.duration_fast
                    easing.type: Easing.InOutSine
                }
            }

            gradient: Gradient {
                GradientStop { position: 0.0; color: !!fadeColor ? fadeColor : "transparent" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            id: fadeRectBottom
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: highlightMargin * 2
            visible: !!fadeColor && fadeRectBottom.opacity !== 0.0 && !view._fadeRectsOverlap

            property bool isHovered: false
            property bool _stateVisible: ((orientation === ListView.Vertical && !view.atYEnd)
                                        && !isHovered)

            states: [
                State {
                    when: fadeRectBottom._stateVisible;
                    PropertyChanges {
                        target: fadeRectBottom
                        opacity: 1.0
                    }
                },
                State {
                    when: !fadeRectBottom._stateVisible;
                    PropertyChanges {
                        target: fadeRectBottom
                        opacity: 0.0
                    }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    property: "opacity"
                    duration: VLCStyle.duration_fast
                    easing.type: Easing.InOutSine
                }
            }

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: !!fadeColor ? fadeColor : "transparent" }
            }
        }
    }

    // FIXME: We propbably need to upgrade these RoundButton(s) eventually. And we probably need
    //        to have some kind of animation when switching pages.

    RoundButton {
        id: buttonLeft

        anchors.left: parent.left
        anchors.top: parent.top

        anchors.topMargin: buttonMargin

        text: '<'

        visible: (view.orientation === ListView.Horizontal && !(view.atXBeginning))

        onClicked: listview_id.prevPage()
    }

    RoundButton {
        id: buttonRight

        anchors.right: parent.right
        anchors.top: buttonLeft.top

        text: '>'

        visible: (view.orientation === ListView.Horizontal && !(view.atXEnd))

        onClicked: listview_id.nextPage()
    }
}
