# Nightscout widget for KDE Plasma 6

Shows your current glucose value from a [Nightscout](https://nightscout.github.io/) server in the Plasma panel or on the desktop.

<table>
  <tr>
    <td align="center"><img src="screenshots/desktop.png" alt="Nightscout widget on the desktop showing 163 with a flat trend arrow, -4 mg/dL, just now" width="444"></td>
    <td align="center"><img src="screenshots/panel.png" alt="Nightscout widget in a vertical panel showing 163 with a flat trend arrow" width="126"></td>
  </tr>
  <tr>
    <td align="center">On the desktop</td>
    <td align="center">In a panel</td>
  </tr>
</table>

- Glucose value with trend arrow and delta (e.g. `112 ↗ +4`)
- mg/dL or mmol/L
- Colour coding: green in range, orange high, red low
- Stale readings are greyed out and struck through
- Low readings flag the widget as needing attention, so it stays visible in a collapsed system tray
- Click for a detailed view; middle-click to refresh

## Installation

From Plasma: right-click the panel or desktop → *Add Widgets…* → *Get New Widgets…* → *Download New Plasma Widgets* → search for **Nightscout**.

Manually, from a downloaded `.plasmoid` file:

```sh
kpackagetool6 -t Plasma/Applet -i nightscout-1.0.0.plasmoid
```

## Configuration

Right-click the widget → *Configure Nightscout…*

| Setting | Description |
|---|---|
| Nightscout URL | e.g. `https://my-nightscout.example.com` or `http://192.168.1.10:1337` |
| Access token | Needed if your site is not publicly readable. Create one in Nightscout under *Admin Tools* with the `readable` role. |
| Units | mg/dL or mmol/L |
| Refresh interval | Seconds between updates (default 60) |
| Low / high | Thresholds in mg/dL (default 70 / 180) |
| Stale after | Minutes after which a reading counts as old (default 15) |

The widget reads `/api/v1/entries/sgv.json` and sends the token both as the `token` query parameter and as the `api-secret` header.

## Development

```sh
# install from source
kpackagetool6 -t Plasma/Applet -i package
# update after changes
kpackagetool6 -t Plasma/Applet -u package
# build the .plasmoid for the KDE Store
./build.sh
```

## Disclaimer

This widget is not a medical device. Do not make treatment decisions based on it.

## License

GPL-2.0-or-later
