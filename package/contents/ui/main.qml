import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    // Raw data (always mg/dL from Nightscout)
    property int sgv: 0
    property int previousSgv: 0
    property bool hasPrevious: false
    property string direction: ""
    property double readingTime: 0
    property string errorText: ""
    property bool loading: false
    property double now: Date.now()

    readonly property bool hasData: readingTime > 0
    readonly property int minutesAgo: hasData ? Math.max(0, Math.floor((now - readingTime) / 60000)) : -1
    readonly property bool stale: hasData && minutesAgo >= cfg.staleMinutes
    readonly property bool isLow: hasData && sgv < cfg.lowThreshold
    readonly property bool isHigh: hasData && sgv > cfg.highThreshold

    readonly property string valueText: hasData ? formatValue(sgv) : "---"
    readonly property string arrowText: arrowFor(direction)
    readonly property string deltaText: (hasData && hasPrevious) ? formatDelta(sgv - previousSgv) : ""
    readonly property string unitText: cfg.useMmol ? "mmol/L" : "mg/dL"
    readonly property string agoText: !hasData ? ""
        : minutesAgo === 0 ? i18n("just now")
        : i18np("%1 minute ago", "%1 minutes ago", minutesAgo)

    readonly property color valueColor: {
        if (!hasData || stale) return Kirigami.Theme.disabledTextColor;
        if (isLow) return Kirigami.Theme.negativeTextColor;
        if (isHigh) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.positiveTextColor;
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.icon: Qt.resolvedUrl("../icons/nightscout-drop.svg")
    Plasmoid.status: (isLow && !stale) ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus

    toolTipMainText: hasData ? valueText + " " + arrowText + " " + unitText : i18n("Nightscout")
    toolTipSubText: errorText !== "" ? errorText
        : hasData ? (deltaText !== "" ? i18n("Delta: %1", deltaText) + "\n" : "") + agoText
        : i18n("No data yet")

    function formatValue(mgdl) {
        return cfg.useMmol ? (mgdl / 18.0182).toFixed(1) : String(mgdl);
    }

    function formatDelta(d) {
        const v = cfg.useMmol ? (d / 18.0182).toFixed(1) : String(d);
        return (d >= 0 ? "+" : "") + v;
    }

    function arrowFor(dir) {
        switch (dir) {
        case "DoubleUp": return "⇈";
        case "SingleUp": return "↑";
        case "FortyFiveUp": return "↗";
        case "Flat": return "→";
        case "FortyFiveDown": return "↘";
        case "SingleDown": return "↓";
        case "DoubleDown": return "⇊";
        default: return "";
        }
    }

    function refresh() {
        let base = (cfg.serverUrl || "").trim().replace(/\/+$/, "");
        if (base === "") {
            errorText = i18n("Configure your Nightscout URL in the widget settings");
            return;
        }
        if (!/^https?:\/\//.test(base)) {
            base = "https://" + base;
        }
        let url = base + "/api/v1/entries/sgv.json?count=2";
        const token = (cfg.token || "").trim();
        if (token !== "") {
            url += "&token=" + encodeURIComponent(token);
        }

        loading = true;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            loading = false;
            if (xhr.status !== 200) {
                errorText = xhr.status === 401 ? i18n("Unauthorized – check the access token")
                    : xhr.status === 0 ? i18n("Could not reach server")
                    : i18n("HTTP error %1", xhr.status);
                return;
            }
            try {
                const entries = JSON.parse(xhr.responseText);
                if (!Array.isArray(entries) || entries.length === 0) {
                    errorText = i18n("No glucose entries found");
                    return;
                }
                sgv = entries[0].sgv;
                direction = entries[0].direction || "";
                readingTime = entries[0].date;
                hasPrevious = entries.length > 1;
                previousSgv = hasPrevious ? entries[1].sgv : 0;
                errorText = "";
                now = Date.now();
            } catch (e) {
                errorText = i18n("Invalid response from server");
            }
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("Accept", "application/json");
        if (token !== "") {
            xhr.setRequestHeader("api-secret", token);
        }
        xhr.send();
    }

    Timer {
        interval: Math.max(15, root.cfg.refreshInterval) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Connections {
        target: Plasmoid.configuration
        function onServerUrlChanged() { root.refresh(); }
        function onTokenChanged() { root.refresh(); }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        },
        PlasmaCore.Action {
            text: i18n("Open Nightscout")
            icon.name: "internet-web-browser"
            enabled: (root.cfg.serverUrl || "") !== ""
            onTriggered: Qt.openUrlExternally(root.cfg.serverUrl)
        }
    ]

    compactRepresentation: MouseArea {
        id: compact
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

        Layout.minimumWidth: vertical ? -1 : compactLabel.implicitWidth
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: vertical ? compactLabel.implicitHeight : -1

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) root.refresh();
            else root.expanded = !root.expanded;
        }

        PlasmaComponents.Label {
            id: compactLabel
            anchors.centerIn: parent
            width: compact.vertical ? parent.width : implicitWidth
            horizontalAlignment: Text.AlignHCenter
            wrapMode: compact.vertical ? Text.WordWrap : Text.NoWrap
            text: root.valueText + (root.arrowText ? " " + root.arrowText : "")
                + (root.cfg.showDelta && root.deltaText && !compact.vertical ? "  " + root.deltaText : "")
            color: root.valueColor
            font.bold: true
            font.strikeout: root.stale
            font.pixelSize: compact.vertical ? Kirigami.Theme.defaultFont.pixelSize
                : Math.max(Kirigami.Theme.smallFont.pixelSize, Math.round(compact.height * 0.55))
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: content.implicitWidth
        Layout.minimumHeight: content.implicitHeight
        Layout.preferredWidth: content.implicitWidth
        Layout.preferredHeight: content.implicitHeight

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    text: root.valueText
                    color: root.valueColor
                    font.bold: true
                    font.strikeout: root.stale
                    font.pixelSize: Kirigami.Units.gridUnit * 2.5
                }
                PlasmaComponents.Label {
                    visible: text !== ""
                    text: root.arrowText
                    color: root.valueColor
                    font.pixelSize: Kirigami.Units.gridUnit * 2
                }
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.hasData
                text: [root.deltaText ? root.deltaText + " " + root.unitText : root.unitText, root.agoText].join(" · ")
                color: root.stale ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                opacity: root.stale ? 1 : 0.7
                font: Kirigami.Theme.smallFont
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                visible: root.errorText !== ""
                text: root.errorText
                color: Kirigami.Theme.negativeTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
