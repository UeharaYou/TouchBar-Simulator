//
//  AppDelegate.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import Foundation
import AppKit

class TouchBarSimulatorApplication: NSObject, NSApplicationDelegate{
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        TouchBarContextMenu.setUp()
        TouchBarWindowManager.setUp()
        //TouchBarWindow.showOnAllDesktops = true
        
        NSLog("App launched.")
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return TouchBarWindowManager.isClosed
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        TouchBarWindowManager.dockSetting = .floating
        NSLog("App Reopened.")
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("App shutting down.")
        //TouchBarContextMenu.finishUp()
        TouchBarWindowManager.finishUp()
    }
   
}

/*
 NSWindow `isReleasedOnClosed` is cursed!!!!
 Three ways things can go wrong:
 1. Window has strong reference, close only, then access again: Reference retained but resources freed. => Accessing freed resources.
 2. Window has strong reference, close and de-reference immediately: Window released (for ARC) before the main runloop actually handles the closure. => App runloop accessing freed resources.
 3. Window has weak reference: Window never retained after returning from caller that constructed it.
 */
