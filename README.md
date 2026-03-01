# dms-plugin-teamspeak

DMS bar widget for real-time TeamSpeak 6 status display.

Shows server name, channel, mute state, talking indicator, and away status in your DankMaterialShell bar. The popout panel lists all connected servers with channel members.

## Dependencies

Requires the [ts6-status](https://github.com/thisilike/ts6-status) binary to bridge the TeamSpeak 6 Remote Apps WebSocket API.

Install it via AUR (`ts6-status`) or `go install github.com/thisilike/ts6-status@latest`.

## Install

```
git clone https://github.com/thisilike/dms-plugin-teamspeak.git \
    ~/.config/DankMaterialShell/plugins/TeamspeakStatus
```

## Enable

1. Open DMS Settings
2. Go to Plugins
3. Click Scan
4. Enable "TeamSpeak Status"

## Features

- Server name and connection status
- Current channel name
- Microphone/speaker mute icons with priority logic
- Talking indicator dot
- Away status icon
- Multi-server badge when connected to multiple servers
- Channel member list in popout with per-user mute/talking/away indicators
- Auto-scrolling long server names
- Configurable update rate throttle

## Settings

| Setting | Default | Description |
|---|---|---|
| Binary Path | `ts6-status` | Path to the ts6-status binary |
| WebSocket Address | `ws://localhost:5899` | TS6 Remote Apps WebSocket address |
| Max Update Rate | 30 fps | Maximum UI updates per second |
| Show Server Name | on | Display server name in bar pill |
| Show Channel Name | on | Display channel name in bar pill |
| Show Mute Icons | on | Display mute status icons |
| Show Talking Indicator | on | Display talking dot |
| Show Nickname | off | Display your nickname in bar pill |
| Show Away Status | on | Display away icon |
