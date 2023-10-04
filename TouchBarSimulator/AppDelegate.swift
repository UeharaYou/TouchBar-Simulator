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
