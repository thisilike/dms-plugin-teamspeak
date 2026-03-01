import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "teamspeakStatus"

    // --- Connection settings ---

    StyledText {
        text: "Connection"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "binaryPath"
        label: "Binary Path"
        description: "Path to the ts-status binary"
        defaultValue: "ts-status"
        placeholder: "/usr/bin/ts-status"
    }

    StringSetting {
        settingKey: "wsAddress"
        label: "WebSocket Address"
        description: "TeamSpeak Remote Apps WebSocket address"
        defaultValue: "ws://localhost:5899"
        placeholder: "ws://localhost:5899"
    }

    SliderSetting {
        settingKey: "maxFps"
        label: "Max Update Rate"
        description: "Maximum UI updates per second"
        defaultValue: 30
        minimum: 5
        maximum: 60
        unit: "fps"
    }

    // --- Separator ---

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Bar display settings ---

    StyledText {
        text: "Bar Display"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "showServerName"
        label: "Show Server Name"
        description: "Display the server name in the bar pill"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showChannelName"
        label: "Show Channel Name"
        description: "Display the current channel name in the bar pill"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showMuteIcons"
        label: "Show Mute Icons"
        description: "Display microphone and speaker mute status icons"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showTalkingIndicator"
        label: "Show Talking Indicator"
        description: "Display a dot when you are talking"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showNickname"
        label: "Show Nickname"
        description: "Display your nickname in the bar pill"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showAwayStatus"
        label: "Show Away Status"
        description: "Display an icon when you are set to away"
        defaultValue: true
    }
}
