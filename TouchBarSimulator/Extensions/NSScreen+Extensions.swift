//
//  NSScreen+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 10/3/23.
//

import Foundation

extension NSScreen {
    public static var atMouseLocation: NSScreen? {
        get {
            let mouseLocation = NSEvent.mouseLocation
            return NSScreen.screens.first(where: {
                let frame = $0.frame
                let fixedFrame = NSRect(x: frame.minX, y: frame.minY, width: frame.width + 1, height: frame.height + 1)
                return fixedFrame.contains(mouseLocation) // Include the edge!!!
                //$0.frame.contains(mouseLocation)
            })
        }
    }
}
