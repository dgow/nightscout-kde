import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_serverUrl: serverUrl.text
    property alias cfg_token: token.text
    property alias cfg_useMmol: useMmol.checked
    property alias cfg_refreshInterval: refreshInterval.value
    property alias cfg_lowThreshold: lowThreshold.value
    property alias cfg_highThreshold: highThreshold.value
    property alias cfg_staleMinutes: staleMinutes.value
    property alias cfg_showDelta: showDelta.checked

    Kirigami.FormLayout {
        QQC2.TextField {
            id: serverUrl
            Kirigami.FormData.label: i18n("Nightscout URL:")
            placeholderText: "https://my-nightscout.example.com"
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: token
            Kirigami.FormData.label: i18n("Access token:")
            placeholderText: i18n("optional, e.g. readable-1234abcd")
            echoMode: TextInput.Password
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: useMmol
            Kirigami.FormData.label: i18n("Units:")
            text: i18n("Show mmol/L instead of mg/dL")
        }
        QQC2.CheckBox {
            id: showDelta
            text: i18n("Show delta in panel")
        }
        QQC2.SpinBox {
            id: refreshInterval
            Kirigami.FormData.label: i18n("Refresh every (s):")
            from: 15
            to: 3600
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: lowThreshold
            Kirigami.FormData.label: i18n("Low below (mg/dL):")
            from: 40
            to: 150
        }
        QQC2.SpinBox {
            id: highThreshold
            Kirigami.FormData.label: i18n("High above (mg/dL):")
            from: 100
            to: 400
        }
        QQC2.SpinBox {
            id: staleMinutes
            Kirigami.FormData.label: i18n("Stale after (min):")
            from: 5
            to: 120
        }
    }
}
