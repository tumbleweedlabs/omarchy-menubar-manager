"use strict"

const { test } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const root = path.join(__dirname, "..")

test("structural host/unhost writes route through the full-config service", function() {
  const qml = fs.readFileSync(path.join(root, "MenubarManager.qml"), "utf8")
  const hostBody = qml.match(/function hostWidgetById\(id\) \{([\s\S]*?)\n  \}/)[1]
  const unhostBody = qml.match(/function unhostWidgetById\(id\) \{([\s\S]*?)\n  \}/)[1]

  assert.match(hostBody, /root\.mutateFullConfig\(/)
  assert.match(unhostBody, /root\.mutateFullConfig\(/)
  assert.doesNotMatch(hostBody, /bar\.shell\.mutateShellConfig/)
  assert.doesNotMatch(unhostBody, /bar\.shell\.mutateShellConfig/)
})

test("the bar widget retries service discovery across startup ordering", function() {
  const qml = fs.readFileSync(path.join(root, "MenubarManager.qml"), "utf8")

  assert.match(qml, /function resolveManagerService\(\)/)
  assert.match(qml, /running: !root\.managerService/)
  assert.match(qml, /onTriggered: root\.resolveManagerService\(\)/)
  assert.match(qml, /var revision = registry\.revision/)
})

test("the companion service atomically writes the complete shell config", function() {
  const qml = fs.readFileSync(path.join(root, "Service.qml"), "utf8")

  assert.match(qml, /function mutateShellConfig\(mutator\)/)
  // Service helpers are declared as children, so the root must provide a
  // default data property. QtObject does not; Item does.
  assert.match(qml, /\nItem \{/)
  assert.match(qml, /atomicWrites: true/)
  assert.match(qml, /configFile\.setText\(JSON\.stringify\(config/)
})
