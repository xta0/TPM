/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem!
  private let server = ServerManager.shared

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "Photo Ingress")

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Start Server", action: #selector(startServer), keyEquivalent: "s"))
    menu.addItem(NSMenuItem(title: "Stop Server", action: #selector(stopServer), keyEquivalent: "t"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    statusItem.menu = menu

//    Task { await server.start() } // auto-start
  }

  @objc private func startServer() { Task { await server.start() } }
  @objc private func stopServer() { Task { await server.stop() } }
  @objc private func quit() {
    Task { await server.stop() }
    NSApp.terminate(nil)
  }
}
