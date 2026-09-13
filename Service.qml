import QtQuick
import Quickshell
import Quickshell.Io

// Omarchy 4.0.3 intentionally limits the API injected into third-party bar
// widgets. Services may opt into the supported, detached widget-catalog
// snapshot without receiving the shell's mutable internal registry. It also
// scopes mutateShellConfig() to bar-only data, which is insufficient here:
// hosting atomically moves an entry between bar.layout and plugins[]. Keep the
// full-config write in this companion service, at the same watched path the
// shell itself uses, so the operation remains one atomic JSON replacement.
// Item supplies the default data property required by FileView. The shell
// hosts services under an invisible Item, so this does not render anything.
Item {
  id: root

  property var barWidgetRegistry: null
  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/shell.json"

  Timer {
    interval: 1000
    running: true
    repeat: false
    onTriggered: {
      var count = root.barWidgetRegistry && typeof root.barWidgetRegistry.availableIds === "function"
        ? root.barWidgetRegistry.availableIds().length : 0
      console.log("menubar manager: widget registry settled with " + count + " entries")
    }
  }

  function mutateShellConfig(mutator) {
    if (typeof mutator !== "function") return false

    var raw = configFile.text() || ""
    var config = null
    try {
      config = JSON.parse(raw)
    } catch (e) {
      console.warn("menubar manager: refusing to overwrite invalid shell.json:", e)
      return false
    }
    if (!config || typeof config !== "object" || Array.isArray(config) || config.version !== 1) {
      console.warn("menubar manager: refusing to overwrite unsupported shell.json")
      return false
    }

    mutator(config)
    config.version = 1
    configFile.setText(JSON.stringify(config, null, 2) + "\n")
    return true
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    atomicWrites: true
    printErrors: true
    onFileChanged: reload()
  }
}
