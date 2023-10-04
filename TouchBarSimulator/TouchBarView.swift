//
//  TouchBarView.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 9/26/23.
//

import Foundation

class TouchBarView: NSView {
    
    var dockSideButtonDelegate: ((_: NSButton) -> Void)? // This is a func delegate from external modules, called when `sideButtonPressed` is called
    
    @objc func sideButtonPressed(_ button: NSButton) { // This is the slot for the `sideButton` in the `sideBarView`
        dockSideButtonDelegate?(button)
    }
}

class TouchBarViewFactory {
    
    private var mainContentView: NSView = {
        let newView = NSView()
        newView.translatesAutoresizingMaskIntoConstraints = false
        
        let blurView = NSVisualEffectView()
        blurView.autoresizingMask = [.height, .width]
        blurView.translatesAutoresizingMaskIntoConstraints = true
        blurView.blendingMode = .behindWindow
        blurView.material = .fullScreenUI
        blurView.state = .active
        newView.addSubview(blurView)
        
        let remoteView = NSRemoteView(frame: CGRectMake(0, 0, 1004, 30)) // 1004px*30px is the resolution of second-gen touch bar
        remoteView.setSynchronizesImplicitAnimations(false)
        remoteView.serviceName = Globals.serviceBundleId
        remoteView.serviceSubclassName = Globals.serviceSubClassName
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        remoteView.setShouldMaskToBounds(false)
        remoteView.layer?.allowsEdgeAntialiasing = true
        
        remoteView.advance(toRunPhaseIfNeeded: {(error) in
            newView.addSubview(remoteView)
            
            let constraintsArray = [
                [NSLayoutConstraint(item: remoteView, attribute: .width, relatedBy: .equal, toItem: remoteView, attribute: .height, multiplier: 1004.0/30.0, constant: 0.0)],
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView]),
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView])
            ].reduce([], +)
            
            newView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            newView.layoutSubtreeIfNeeded()
            
            return
        })
        
        let constraintsArray: [NSLayoutConstraint] = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:[newView(>=1014)]", metrics: nil, views: ["newView": newView]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:[newView(>=40)]", metrics: nil, views: ["newView": newView])
        ].reduce([], +).map{with($0, update: {$0.priority = .required - 1})}
        newView.addConstraints(constraintsArray)
        NSLayoutConstraint.activate(constraintsArray)
        newView.layoutSubtreeIfNeeded()
        
        return newView
    }()
    
    private var sideBarViewTuple: (NSView, (TouchBarView) -> Void) = {
        let newView = NSView()
        newView.translatesAutoresizingMaskIntoConstraints = false
        
        let blurView = NSVisualEffectView()
        blurView.autoresizingMask = [.height, .width]
        blurView.translatesAutoresizingMaskIntoConstraints = true
        blurView.blendingMode = .behindWindow
        blurView.material = .headerView
        blurView.state = .active
        newView.addSubview(blurView)
        
        let escapeImage = {
            if #available(macOS 11, *) {
                return NSImage(systemSymbolName: "escape", accessibilityDescription: "Undock touch bar simulator.".localized) // Alternative: "rhombus.fill" "chevron.compact.left"
            }
            else {
                let image = NSImage(named: "Escape")
                image?.accessibilityDescription = "Undock touch bar simulator.".localized
                return image
            }
        }()
        
        let closeImage = {
            if #available(macOS 11, *) {
                return NSImage(systemSymbolName: "xmark.square.fill", accessibilityDescription: "Close touch bar simulator.".localized)
            }
            else {
                let image = NSImage(named: "Xmark")
                image?.accessibilityDescription = "Close touch bar simulator.".localized
                return image
            }
        }()
        
        let settingsImage = {
            if #available(macOS 11, *) {
                return NSImage(systemSymbolName: "gear", accessibilityDescription: "Touch bar simulator settings.".localized)
            }
            else {
                let image = NSImage(named: "Settings")
                image?.accessibilityDescription = "Touch bar simulator settings.".localized
                return image
            }
        }()
        
        let sideButton = NSButton()
        sideButton.image = escapeImage
        sideButton.imageScaling = .scaleProportionallyDown
        sideButton.isBordered = false
        sideButton.bezelStyle = .shadowlessSquare
        sideButton.frame = CGRect(x: 0, y: 0, width: 16, height: 11)
        sideButton.autoresizingMask = [.minXMargin, .minYMargin, .maxYMargin]
        sideButton.translatesAutoresizingMaskIntoConstraints = false
        newView.addSubview(sideButton)
        
        // `sideButton` needs an entity target for posting button-press events to, which is externally assigned. So we throw a closure to the caller for the backpatch.
        let targetRegistration = {(target: TouchBarView) -> Void in sideButton.target = target} // `sideButton.target` is a weak reference, don't worry about Reference Looping
        sideButton.action = #selector(TouchBarView.sideButtonPressed) // Since it's concrete, we just have it hard-coded instead of requiring one from the caller.
        
        // Now create a closure for changing the image of the `sideButton`
        // FIXME: The logic handling the image and the actual action is seperated into different locations. Reassigning combinations (e.g. when `option` key is pressed) requires both changing the logic here and one from `dockSideButtonDelegate`.
        let keyListenHandler: (NSEvent) -> Void = {
            event in
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)
            let isCommandKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.command)
            
            switch (isCommandKeyPressed, isOptionKeyPressed) {
            case (true, _):
                sideButton.image = settingsImage
            case (false, true):
                sideButton.image = closeImage
            case (false, false):
                sideButton.image = escapeImage
            }
            return
        }
        
        // FIXME: Is there a better way to register key press event observer?
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) {event in keyListenHandler(event)}
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {event in keyListenHandler(event); return event}
        
        let constraintsArray = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:[buttonRelease(16)]", metrics: nil, views: ["buttonRelease": sideButton]),
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-3-[buttonRelease]-3-|", metrics: nil, views: ["buttonRelease": sideButton]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[buttonRelease]-5-|", metrics: nil, views: ["buttonRelease": sideButton])
        ].reduce([], +)
        
        newView.addConstraints(constraintsArray)
        NSLayoutConstraint.activate(constraintsArray)
        newView.layoutSubtreeIfNeeded()
        
        return (newView, targetRegistration)
    }()
    
    func generate(standalone: Bool = false, sideButtonDelegate delegateFunc: @escaping (_: NSButton) -> Void = {(_) in return}) -> TouchBarView {
        
        let touchBarView = TouchBarView()
        //touchBarView.autoresizingMask = [.height, .width]
        touchBarView.translatesAutoresizingMaskIntoConstraints = false
        touchBarView.needsLayout = true
        touchBarView.wantsLayer = true
        touchBarView.layerUsesCoreImageFilters = true
        touchBarView.dockSideButtonDelegate = delegateFunc
        //touchBarView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        
        if standalone {
            let (sideBarView, updateTarget) = sideBarViewTuple
            let mainView = mainContentView
            
            // Update target for the sidebar button to the newly generated `touchBarView` entity.
            updateTarget(touchBarView)
            
            touchBarView.addSubview(sideBarView)
            touchBarView.addSubview(mainView)
            let constraintsArray = [
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[sideBarView]-0-[mainView]-0-|", metrics: nil, views: ["sideBarView": sideBarView, "mainView": mainView]),
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[sideBarView]-0-|", metrics: nil, views: ["sideBarView": sideBarView]),
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[mainView]-0-|", metrics: nil, views: ["mainView": mainView])
            ].reduce([], +)
            
            touchBarView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            touchBarView.layoutSubtreeIfNeeded()
            
            // set round corner for touchBarView
            touchBarView.layer?.cornerRadius = 10.0
        }
        else {
            let mainView = mainContentView
            touchBarView.addSubview(mainView)
            let constraintsArray = [
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[mainView]-0-|", metrics: nil, views: ["mainView": mainView]),
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[mainView]-0-|", metrics: nil, views: ["mainView": mainView])
            ].reduce([], +)
            
            touchBarView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            touchBarView.layoutSubtreeIfNeeded()
        }
        
        return touchBarView
    }
    
}

// FIXME: `instance.contentViewController` might fails to return a `NSRemoteViewController` since `instance.contentView` might no longer be an `NSRemoteView`. Also it seems `NSRemoteView` is smart enough to disconnect themselves once they are unloaded from the view tree. Right now the following code seems does nothing.
// let remoteViewController = instance.contentViewController as? NSRemoteViewController
// remoteViewController?.disconnect()
