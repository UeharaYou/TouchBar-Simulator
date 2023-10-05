//
//  NSWindow+Extensions.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit

extension NSWindow {
    var titleBarView: NSView? { standardWindowButton(.closeButton)?.superview }
}

extension NSWindow {

}


extension NSWindow.Level {
    private static func level(for cgLevelKey: CGWindowLevelKey) -> Self {
        .init(rawValue: Int(CGWindowLevelForKey(cgLevelKey)))
    }
    
    static let desktop = level(for: .desktopWindow)
    static let desktopIcon = level(for: .desktopIconWindow)
    static let backstopMenu = level(for: .backstopMenu)
    static let dragging = level(for: .draggingWindow)
    static let overlay = level(for: .overlayWindow)
    static let help = level(for: .helpWindow)
    static let utility = level(for: .utilityWindow)
    static let assistiveTechHigh = level(for: .assistiveTechHighWindow)
    static let cursor = level(for: .cursorWindow)
    
    static let minimum = level(for: .minimumWindow)
    static let maximum = level(for: .maximumWindow)
}

