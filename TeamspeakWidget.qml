import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property string plugId: "teamspeakStatus"

    // --- Settings ---
    property string binaryPath: pluginData.binaryPath || "ts-status"
    property string wsAddress: pluginData.wsAddress || "ws://localhost:5899"
    property int maxFps: pluginData.maxFps ?? 30
    property bool showServerName: pluginData.showServerName ?? true
    property bool showChannelName: pluginData.showChannelName ?? true
    property bool showMuteIcons: pluginData.showMuteIcons ?? true
    property bool showTalkingIndicator: pluginData.showTalkingIndicator ?? true
    property bool showNickname: pluginData.showNickname ?? false
    property bool showAwayStatus: pluginData.showAwayStatus ?? true

    // --- State ---
    property var servers: []
    property bool connected: false
    property string errorMsg: ""

    readonly property var primaryServer: {
        // Pick first established connection (status 4), else first with any status > 0
        let best = null;
        for (let i = 0; i < servers.length; i++) {
            const s = servers[i];
            if (s.status === 4) return s;
            if (!best && s.status > 0) best = s;
        }
        return best;
    }

    readonly property bool hasMultipleServers: {
        let count = 0;
        for (let i = 0; i < servers.length; i++) {
            if (servers[i].status >= 4) count++;
        }
        return count > 1;
    }

    // --- API key path ---
    readonly property string apiKeyPath: {
        if (!pluginService) return "";
        const statePath = pluginService.getPluginStatePath(plugId);
        // statePath is like ~/.local/state/DankMaterialShell/plugins/teamspeakStatus_state.json
        // We want the directory portion + /ts6_apikey.txt
        const dir = statePath.substring(0, statePath.lastIndexOf("/"));
        return dir + "/ts6_apikey.txt";
    }

    // --- Process ---
    function buildCommand() {
        if (!binaryPath || !apiKeyPath) return [];
        return [binaryPath, "--addr", wsAddress, "--apikey-path", apiKeyPath,
                "--max-fps", maxFps.toString()];
    }

    Process {
        id: tsProcess
        command: root.buildCommand()
        running: false

        stdout: SplitParser {
            onRead: data => {
                try {
                    const msg = JSON.parse(data);
                    root.connected = msg.connected;
                    root.errorMsg = msg.error;
                    root.servers = msg.servers;
                } catch (e) {
                    console.error("TeamspeakStatus: failed to parse JSON:", e, data);
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                console.log("TeamspeakStatus: process stopped");
                root.connected = false;
                restartTimer.start();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: {
            if (root.binaryPath) {
                console.log("TeamspeakStatus: restarting process...");
                tsProcess.command = root.buildCommand();
                tsProcess.running = true;
            }
        }
    }

    function restartProcess() {
        tsProcess.running = false;
        restartTimer.stop();
        tsProcess.command = buildCommand();
        tsProcess.running = true;
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            if (binaryPath && apiKeyPath) {
                tsProcess.running = true;
            }
        });
    }

    onBinaryPathChanged: Qt.callLater(restartProcess)
    onWsAddressChanged: Qt.callLater(restartProcess)
    onMaxFpsChanged: Qt.callLater(restartProcess)

    // --- Helpers ---
    // Mute display logic (priority order):
    //   outputMuted → volume_off (mic is implicitly muted)
    //   inputDeactivated → mic_external_off (hardware disabled, overrides software mute)
    //   away → mic_off (away auto-mutes mic)
    //   inputMuted → mic_off
    //   none → mic
    function muteIconName(s) {
        if (!s) return "";
        if (s.status !== undefined && s.status !== 4) return "";
        if (s.outputMuted) return "volume_off";
        if (s.inputDeactivated) return "mic_external_off";
        if (s.away || s.inputMuted) return "mic_off";
        return "mic";
    }
    function muteIconColor(s) {
        if (!s) return Theme.surfaceText;
        if (s.outputMuted || s.inputDeactivated || s.away || s.inputMuted) return Theme.error;
        return Theme.surfaceText;
    }

    // --- Bar pills ---
    popoutWidth: 380

    horizontalBarPill: Component {
        Row {
            spacing: 4

            DankIcon {
                name: "headset_mic"
                size: root.iconSize
                color: root.primaryServer && root.primaryServer.status === 4
                    ? Theme.primary
                    : Theme.surfaceVariantText
                filled: root.primaryServer && root.primaryServer.status === 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.showServerName && root.primaryServer && root.primaryServer.serverName
                text: root.primaryServer ? root.primaryServer.serverName : ""
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.showChannelName && root.primaryServer && root.primaryServer.channelName
                text: root.primaryServer ? root.primaryServer.channelName : ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                visible: root.showMuteIcons && root.primaryServer && root.primaryServer.status === 4
                name: root.muteIconName(root.primaryServer)
                size: root.iconSize - 2
                color: root.muteIconColor(root.primaryServer)
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                visible: root.showTalkingIndicator && root.primaryServer && root.primaryServer.status === 4
                width: 6
                height: 6
                radius: 3
                color: root.primaryServer && root.primaryServer.talking ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            DankIcon {
                visible: root.showAwayStatus && root.primaryServer && root.primaryServer.away
                name: "schedule"
                size: root.iconSize - 4
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                visible: root.hasMultipleServers
                width: badgeText.implicitWidth + 6
                height: 14
                radius: 7
                color: Theme.primaryContainer
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: {
                        let count = 0;
                        for (let i = 0; i < root.servers.length; i++) {
                            if (root.servers[i].status >= 4) count++;
                        }
                        return count.toString();
                    }
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.onPrimaryContainer
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 2

            DankIcon {
                name: "headset_mic"
                size: root.iconSize
                color: root.primaryServer && root.primaryServer.status === 4
                    ? Theme.primary
                    : Theme.surfaceVariantText
                filled: root.primaryServer && root.primaryServer.status === 4
                anchors.horizontalCenter: parent.horizontalCenter
            }

            DankIcon {
                visible: root.showMuteIcons && root.primaryServer && root.primaryServer.status === 4
                name: root.muteIconName(root.primaryServer)
                size: root.iconSize - 4
                color: root.muteIconColor(root.primaryServer)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                visible: root.showTalkingIndicator && root.primaryServer && root.primaryServer.status === 4
                width: 6
                height: 6
                radius: 3
                color: root.primaryServer && root.primaryServer.talking ? Theme.primary : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // --- Popout ---
    popoutContent: Component {
        Column {
            width: parent.width
            spacing: 0

            PopoutComponent {
                width: parent.width
                headerText: "TeamSpeak Status"
                detailsText: root.connected
                    ? (root.servers.length + " server" + (root.servers.length !== 1 ? "s" : ""))
                    : "Disconnected"
                showCloseButton: true
                closePopout: root.closePopout
            }

            Column {
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                bottomPadding: Theme.spacingS

                Repeater {
                    model: root.servers

                    StyledRect {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: serverCol.implicitHeight + Theme.spacingM * 2
                        radius: Theme.cornerRadius
                        color: serverMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.width: 0

                        MouseArea {
                            id: serverMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Column {
                            id: serverCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            anchors.topMargin: Theme.spacingM
                            spacing: 4

                            // Server name + status
                            Row {
                                spacing: Theme.spacingM
                                width: parent.width

                                DankIcon {
                                    name: "dns"
                                    size: Theme.iconSize
                                    color: modelData.status === 4 ? Theme.primary : Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    spacing: 2
                                    width: parent.width - Theme.iconSize - Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter

                                    Item {
                                        width: parent.width
                                        height: serverNameText.height
                                        clip: true

                                        StyledText {
                                            id: serverNameText
                                            property bool needsScrolling: implicitWidth > parent.width
                                            property real scrollOffset: 0

                                            text: modelData.serverName || "Unknown Server"
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Medium
                                            color: Theme.surfaceText
                                            wrapMode: Text.NoWrap
                                            x: needsScrolling ? -scrollOffset : 0

                                            onTextChanged: {
                                                scrollOffset = 0;
                                                serverNameScroll.restart();
                                            }

                                            SequentialAnimation {
                                                id: serverNameScroll
                                                running: serverNameText.needsScrolling
                                                loops: Animation.Infinite

                                                PauseAnimation { duration: 2000 }
                                                NumberAnimation {
                                                    target: serverNameText
                                                    property: "scrollOffset"
                                                    from: 0
                                                    to: serverNameText.implicitWidth - serverNameText.parent.width + 5
                                                    duration: Math.max(1000, (serverNameText.implicitWidth - serverNameText.parent.width + 5) * 60)
                                                    easing.type: Easing.Linear
                                                }
                                                PauseAnimation { duration: 2000 }
                                                NumberAnimation {
                                                    target: serverNameText
                                                    property: "scrollOffset"
                                                    to: 0
                                                    duration: Math.max(1000, (serverNameText.implicitWidth - serverNameText.parent.width + 5) * 60)
                                                    easing.type: Easing.Linear
                                                }
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: modelData.statusText
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: modelData.status === 4 ? Theme.primary : Theme.surfaceVariantText
                                    }
                                }
                            }

                            // Channel
                            StyledText {
                                visible: modelData.channelName && modelData.status === 4
                                x: Theme.iconSize + Theme.spacingM
                                text: modelData.channelName || ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            // Channel members (including self)
                            Column {
                                id: membersCol
                                visible: modelData.status === 4 && modelData.channelMembers && modelData.channelMembers.length > 0
                                width: parent.width - Theme.iconSize - Theme.spacingM
                                x: Theme.iconSize + Theme.spacingM
                                spacing: 2

                                Repeater {
                                    model: modelData.channelMembers || []

                                    delegate: Item {
                                        required property var modelData
                                        property var member: modelData
                                        width: membersCol.width
                                        height: memberNameRow.height

                                        Row {
                                            id: memberNameRow
                                            anchors.left: parent.left
                                            anchors.right: memberIcons.left
                                            anchors.rightMargin: Theme.spacingS
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.spacingS

                                            StyledText {
                                                text: member.nickname || ""
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Normal
                                                color: member.isSelf ? Theme.primary : Theme.surfaceVariantText
                                                elide: Text.ElideRight
                                                width: Math.min(implicitWidth, parent.width)
                                            }
                                        }

                                        Row {
                                            id: memberIcons
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.spacingS

                                            DankIcon {
                                                name: root.muteIconName(member)
                                                size: Theme.iconSize - 6
                                                color: root.muteIconColor(member)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Rectangle {
                                                width: 6
                                                height: 6
                                                radius: 3
                                                color: member.talking ? Theme.primary : Theme.surfaceVariantText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            DankIcon {
                                                visible: member.away
                                                name: "schedule"
                                                size: Theme.iconSize - 6
                                                color: Theme.surfaceVariantText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state
                Column {
                    visible: root.servers.length === 0
                    width: parent.width
                    spacing: Theme.spacingS
                    topPadding: Theme.spacingM
                    bottomPadding: Theme.spacingM

                    DankIcon {
                        visible: !root.connected && root.errorMsg
                        name: "error"
                        size: Theme.iconSize + 4
                        color: Theme.error
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    StyledText {
                        text: root.connected ? "No servers connected" : (root.errorMsg ? "Error" : "Waiting for TeamSpeak...")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        visible: !root.connected && root.errorMsg
                        text: root.errorMsg
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        opacity: 0.7
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
