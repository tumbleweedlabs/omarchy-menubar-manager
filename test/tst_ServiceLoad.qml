import QtQuick
import QtTest
import ".." as Plugin

TestCase {
  name: "ServiceLoad"

  Plugin.Service {
    id: service
  }

  function test_constructs() {
    verify(service !== null)
    verify(typeof service.mutateShellConfig === "function")
  }
}
