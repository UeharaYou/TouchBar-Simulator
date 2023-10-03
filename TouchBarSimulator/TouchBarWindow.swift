//
//  TouchBarWindow.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit
import Defaults

class TouchBarWindow: NSPanel, NSWindowDelegate {
    
    enum Docking: String, Codable {
        case floating
        case dockedToTop
        case dockedToBottom
    }
    
    // View Factory
    private let touchBarViewFactory = TouchBarViewFactory()
    
    // Properties overrides
    override var canBecomeMain: Bool { false }
    override var canBecomeKey: Bool { false }
    
    // Properties handling confinement
    override var contentView: NSView? {
        didSet {
            if let newRestrictionView = confinementView, let contentView = contentView {
                contentView.addSubview(newRestrictionView)
                let constraints = [
                    [NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: newRestrictionView, attribute: .width, multiplier: 1, constant: 0)],
                    [NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: newRestrictionView, attribute: .height, multiplier: 1, constant: 0)]
                ].reduce([], +)
                contentView.addConstraints(constraints)
                NSLayoutConstraint.activate(constraints)
                contentView.layout()
                contentView.updateConstraints()
            }
        }
    }
    var confinementView: NSView? = nil {
        didSet {
            if let oldRestrictionView = oldValue {
                oldRestrictionView.removeFromSuperview()
                contentView?.layout()
                contentView?.updateConstraints()
            }
            
            if let newRestrictionView = confinementView, let contentView = contentView {
                contentView.addSubview(newRestrictionView)
                let constraints = [
                    [NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: newRestrictionView, attribute: .width, multiplier: 1, constant: 0)],
                    [NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: newRestrictionView, attribute: .height, multiplier: 1, constant: 0)]
                ].reduce([], +)
                contentView.addConstraints(constraints)
                NSLayoutConstraint.activate(constraints)
                contentView.layout()
                contentView.updateConstraints()
            }
        }
    }
    override func constrainFrameRect(
        _ frameRect: NSRect,
        to screen: NSScreen?
    ) -> NSRect {
        let frameRect = super.constrainFrameRect(frameRect, to: screen)
        
        guard let targetScreen = screen else {
            return frameRect
        }
        
        // FIXME: Does not work!!! Constraint of content size override it!!!
        // Probable workaround: Add constraint link with contentView to a new view
        let constrainedWidthFrame = {
            if (frameRect.width >= targetScreen.visibleFrame.width) {
                let screenWidth = targetScreen.visibleFrame.width
                let dWidth = frameRect.width - screenWidth
                let rectifiedRect = NSRect(origin: frameRect.offsetBy(dx: -dWidth, dy: 0).origin, size: CGSize(width: targetScreen.visibleFrame.width, height: frameRect.height))
                return rectifiedRect
            }
            else {
                return frameRect
            }
        }()
        
        return constrainedWidthFrame
    }
    
    // Properties that holds the last screen the window is on
    // private var lastScreen: NSScreen? = nil
    
    // Properties & delegates func for handling Window Close
    var isClosed: Bool {
        get {
            switch(isVisible, isCloseNoted) {
            case (true, _): // visible <= never closed (t,f) [stable state] / closed but reopened (t,t) [temporal state]
                isCloseNoted = false // treated as not closed (t,t) -> (t,f)
                fallthrough
            case (false, false): // not visible, but close event not noted <= not closed (_,f)
                return false
            case (false, true):
                return true
            }
        }
    }
    private var isCloseNoted = false
    func windowWillClose(_ notification: Notification) {
        stopAnimations(fastForward: true) // Fast forward all animations to the end
        isCloseNoted = true
    }
    
    // Properties & delegate funcs for handling Live Resize
    private var isLiveResizeUnhandled = false
    func windowDidResize(_ notification: Notification) {
        if inLiveResize {
            isLiveResizeUnhandled = true
        }
    }
    
    // Major properties
    var docking: Docking = Defaults[.windowDocking] {
        didSet {
            switch (oldValue, docking) {
            case (_, .floating):
                hasTitle = true
                startAnimations(duration: 0.35, animation:
                                    moveAnimation(destination: destinationFrame(docking, hiding, inScreen: screen)) +
                                fadeAnimation(destination: 1.0)
                )
                renewretainingUpdateDeadline(infinite: true)
            case (.floating, .dockedToTop), (.floating, .dockedToBottom):
                Defaults[.lastFloatingPosition] = frame.origin
                fallthrough
            case (_, _):
                hasTitle = false
                startAnimations(duration: 0.35, animation: moveAnimation(destination: destinationFrame(docking, hiding, inScreen: NSScreen.atMouseLocation)))
                renewretainingUpdateDeadline(infinite: false)
                break
            }
            Defaults[.windowDocking] = docking
        }
    }
    private var hiding: Bool = false {
        didSet {
            switch (docking, hiding) {
            case (.floating, _) where hiding == true:
                hiding = false
                break
            case (_, true) where oldValue != hiding:
                startAnimations(duration: 0.35, animation:
                                    moveAnimation(destination: destinationFrame(docking, hiding, inScreen: screen)) +
                                fadeAnimation(destination: 0.0) // FIXME: set alpha value all the way to 0 causes window to re-layout (no more boarders!)
                )
            case (_, false) where oldValue != hiding:
                setFrame(destinationFrame(docking, oldValue, inScreen: NSScreen.atMouseLocation), display: true) // FIXME: might be glitchy, move start first
                startAnimations(duration: 0.35, animation:
                                    moveAnimation(destination: destinationFrame(docking, hiding, inScreen: NSScreen.atMouseLocation)) +
                                fadeAnimation(destination: 1.0)
                )
            case (_, _):
                break
            }
        }
    }
    private var viewHasSideBar: Bool = false {
        didSet {
            let oldContentHeight = contentView?.frame.height ?? 0.0
            
            let newContentView = {
                viewHasSideBar ?
                touchBarViewFactory.generate(standalone: true) {
                    [weak self] button in
                    self?.viewSideButtonPressed(button)
                    return
                } :
                touchBarViewFactory.generate(standalone: false)
            }()
            
            let constraintsArray: [NSLayoutConstraint] = [
                //NSLayoutConstraint.constraints(withVisualFormat: "H:[contentView(<=windowWidth)]", metrics: ["windowWidth": screen?.frame.width ?? 10000], views: ["contentView": newContentView])
                //[NSLayoutConstraint(item: newContentView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: , attribute: .width, multiplier: 1, constant: 0)]
            ].reduce([], +).map{with($0, update: {$0.priority = .fittingSizeCompression - 1})}
            newContentView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            
            contentView = newContentView
            
            layoutIfNeeded()
            updateConstraintsIfNeeded()
            
            setContentSize(newContentView.getFittingRect(withMinimunHeight: oldContentHeight))
            //setContentSize(.init(width: 10, height: 10)) // FIXME: rm
            // Offsetting window frame should be Edge-triggering
            if oldValue != viewHasSideBar {
                setFrame(frame.offsetBy(dx: (viewHasSideBar ? -22 : 22), dy: 0), display: true)
            }
        }
    }
    private var hasTitle: Bool = false {
        didSet {
            if hasTitle {
                if !styleMask.contains(.titled) {
                    styleMask.insert(.titled)
                    adjustTitleBar()
                }
                viewHasSideBar = false
            }
            else {
                
                if styleMask.contains(.titled) {
                    styleMask.remove(.titled)
                }
                viewHasSideBar = true
            }
        }
    }
    
    // Properties & funcs for Mouse Detection
    private var detectionRects: [CGRect] {
        let windowFrame = frame
        
        let detectionRectArray = NSScreen.screens.map { screen in
            let visibleFrame = screen.visibleFrame
            let screenFrame = screen.frame
            
            switch (docking, hiding) {
            case (.floating, _):
                return CGRect.infinite//windowFrame
            case (.dockedToBottom, false):
                return CGRect(
                    x: visibleFrame.midX - windowFrame.width / 2,
                    y: screenFrame.minY,
                    width: windowFrame.width,//visibleFrame.width,
                    height: windowFrame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness)
                )
            case (.dockedToBottom, true):
                return CGRect(x: visibleFrame.midX - windowFrame.width / 2,
                              y: screenFrame.minY,
                              width: windowFrame.width,
                              height: 1)
            case (.dockedToTop, false):
                return CGRect(
                    x: visibleFrame.midX - windowFrame.width / 2,
                    // Without `+ 1`, the Touch Bar would glitch (toggling rapidly).
                    y: screenFrame.minY + screenFrame.height - frame.height - NSStatusBar.system.thickness + 1,
                    width: windowFrame.width,
                    height: windowFrame.height + NSStatusBar.system.thickness
                )
            case (.dockedToTop, true):
                return CGRect(
                    x: visibleFrame.midX - windowFrame.width / 2,
                    y: screenFrame.maxY,
                    width: windowFrame.width,
                    height: 1
                )
            }
        }
        
        return detectionRectArray
    }
    private var isMouseDetected: Bool {
        //NSLog("\(NSScreen.screens.map{return $0.visibleFrame}), \(detectionRects)")
        //NSLog("\(NSEvent.mouseLocation), \(detectionRects.contains{$0.contains(NSEvent.mouseLocation)})")
        return detectionRects.contains{$0.contains(NSEvent.mouseLocation)}
    }
    
    // Properties & funcs for handling Cyclical State Updates
    private var retainingUpdateDeadline = Date() + Defaults[.windowDetectionTimeOut]
    private func renewretainingUpdateDeadline(infinite: Bool) {
        retainingUpdateDeadline = infinite ? .distantFuture : Date() + Defaults[.windowDetectionTimeOut]
    }
    private func handleCyclicalUpdate() {
        let shouldHandleResize = isLiveResizeUnhandled && !inLiveResize
        switch (docking, hiding) {
        case (.floating, _):
            break
        case (.dockedToTop, _), (.dockedToBottom, _):
            if isMouseDetected {
                if hiding == true {
                    hiding = false
                }
                else if screen != NSScreen.atMouseLocation {
                    startAnimations(duration: 0.45, animation: teleportAnimation(destination: destinationFrame(docking, hiding, inScreen: NSScreen.atMouseLocation)))
                }
                renewretainingUpdateDeadline(infinite: false)
            }
            else if shouldHandleResize {
                isLiveResizeUnhandled = false
                startAnimations(duration: 0.35, animation: moveAnimation(destination: destinationFrame(docking, hiding, inScreen: screen))) // FIXME: move, 0.35; tele, 0.45
                renewretainingUpdateDeadline(infinite: false)
            }
            else if Date() >= retainingUpdateDeadline {
                hiding = true
            }
        }
        
        contentView?.updateConstraints()
    }
    private var cyclicalUpdateTimer: Timer? = nil {
        didSet {
            if let oldTimer = oldValue {
                oldTimer.invalidate()
            }
            
            if let newTimer = cyclicalUpdateTimer {
                RunLoop.main.add(newTimer, forMode: .default)
            }
        }
    }
    
    // Members for Tool Bar
    private let toolBarView = {
        let toolBoxView = NSView()
        toolBoxView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonUp = NSButton()
        if #available(macOS 11, *) {
            buttonUp.image = NSImage(systemSymbolName: "menubar.arrow.up.rectangle", accessibilityDescription: "Dock touch bar simulator to the top of the screen.".localized)
        }
        
        else {
            let image = NSImage(named: "DockUp")
            image?.accessibilityDescription = "Dock touch bar simulator to the top of the screen.".localized
            buttonUp.image = image
        }
        buttonUp.imageScaling = .scaleProportionallyDown
        buttonUp.translatesAutoresizingMaskIntoConstraints = false
        buttonUp.isBordered = false
        buttonUp.bezelStyle = .shadowlessSquare
        //buttonUp.frame = CGRect(x: toolBoxView.frame.width - 57, y: 4, width: 16, height: 11)
        //buttonUp.autoresizingMask.insert(NSView.AutoresizingMask.minXMargin)
        buttonUp.action = #selector(TouchBarWindow.dockUpPressed)
        toolBoxView.addSubview(buttonUp)
        
        let buttonDown = NSButton()
        if #available(macOS 11, *) {
            buttonDown.image = NSImage(systemSymbolName: "dock.arrow.down.rectangle", accessibilityDescription: "Dock touch bar simulator to the bottom of the screen.".localized)
        }
        else {
            let image = NSImage(named: "DockDown")
            image?.accessibilityDescription = "Dock touch bar simulator to the bottom of the screen.".localized
            buttonDown.image = image
        }
        buttonDown.imageScaling = .scaleProportionallyDown
        buttonDown.translatesAutoresizingMaskIntoConstraints = false
        buttonDown.isBordered = false
        buttonDown.bezelStyle = .shadowlessSquare
        //buttonDown.frame = CGRect(x: toolBoxView.frame.width - 38, y: 4, width: 16, height: 11)
        //buttonDown.autoresizingMask.insert(NSView.AutoresizingMask.minXMargin)
        buttonDown.action = #selector(TouchBarWindow.dockDownPressed)
        toolBoxView.addSubview(buttonDown)
        
        let buttonSettings = NSButton()
        if #available(macOS 11, *) {
            buttonSettings.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Touch bar simulator settings.".localized)
        }
        else {
            let image = NSImage(named: "Settings")
            image?.accessibilityDescription = "Touch bar simulator settings.".localized
            buttonSettings.image = image
        }
        buttonSettings.imageScaling = .scaleProportionallyDown
        buttonSettings.translatesAutoresizingMaskIntoConstraints = false
        buttonSettings.isBordered = false
        buttonSettings.bezelStyle = .shadowlessSquare
        //buttonSettings.frame = CGRect(x: toolBoxView.frame.width - 19, y: 4, width: 16, height: 11)
        //buttonSettings.autoresizingMask.insert(NSView.AutoresizingMask.minXMargin)
        buttonSettings.action = #selector(TouchBarWindow.settingsPressed)
        toolBoxView.addSubview(buttonSettings)
        
        let constraintsArray = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[buttonUp]-3-[buttonDown]-3-[buttonSettings]|", metrics: nil, views: ["buttonUp": buttonUp, "buttonDown": buttonDown, "buttonSettings": buttonSettings]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[buttonUp]-3-|", metrics: nil, views: ["buttonUp": buttonUp]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[buttonDown]-3-|", metrics: nil, views: ["buttonDown": buttonDown]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[buttonSettings]-3-|", metrics: nil, views: ["buttonSettings": buttonSettings])
        ]
            .reduce([], +)
        toolBoxView.addConstraints(constraintsArray)
        NSLayoutConstraint.activate(constraintsArray)
        toolBoxView.layoutSubtreeIfNeeded()
        toolBoxView.updateConstraints()
        toolBoxView.updateConstraintsForSubtreeIfNeeded()
        
        return toolBoxView
    }()
    private func adjustTitleBar() {
        guard let titleBarView = titleBarView else {
            return
        }
        
        titleBarView.addSubview(toolBarView)
        
        let constraintsArray = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:[toolBarView]-3-|", metrics: nil, views: ["toolBarView": toolBarView]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[toolBarView]|", metrics: nil, views: ["toolBarView": toolBarView])
        ]
            .reduce([], +)
        titleBarView.addConstraints(constraintsArray)
        NSLayoutConstraint.activate(constraintsArray)
        titleBarView.layoutSubtreeIfNeeded()
        titleBarView.updateConstraints()
        titleBarView.updateConstraintsForSubtreeIfNeeded()
        
    }
    
    // Members & funcs for Animation
    private let windowAnimator = TouchBarAnimation(duration: 0, animationCurve: .easeInOut, blockMode: .nonblocking)
    private func startAnimations(duration: TimeInterval, animation: @escaping TouchBarAnimation.AnimationFunc) {
        windowAnimator.duration = duration
        windowAnimator.animation = animation
        windowAnimator.start()
    }
    private func stopAnimations(fastForward: Bool = false) { // Setting `fastForward` to true skips all frames till the last one
        if fastForward {
            windowAnimator.currentProgress = 1.0
        }
        windowAnimator.stop()
    }
    
    // Animation funcs
    private func moveAnimation(destination endFrame: CGRect) -> TouchBarAnimation.AnimationFunc {
        return {(startFrame, endFrame) in
            let dWidth = endFrame.size.width / startFrame.size.width - 1
            let dHeight = endFrame.size.width / startFrame.size.width - 1
            let centerX = startFrame.midX
            let centerY = startFrame.midY
            let dX = endFrame.midX - startFrame.midX
            let dY = endFrame.midY - startFrame.midY
            let scaleTranslateTransform = {(t: CGFloat) in
                return CGAffineTransform.identity
                // Step 1: Scaling transform with mid point as origin
                    .translatedBy(x: -centerX, y: -centerY)
                    .scaledBy(x: dWidth * t + 1, y: dHeight * t + 1)
                    .translatedBy(x: centerX, y: centerY)
                // Step 2: Translating transform
                    .translatedBy(x: dX * t, y: dY * t)
            }
            
            return { [weak self] (currentProgress: Float, currentValue: Float) in
                if currentProgress == 1.0 {
                    NSLog("\(startFrame)->\(endFrame)")
                    self?.setFrame(endFrame, display: true)
                }
                else {
                    //self?.updateConstraintsIfNeeded()
                    let t = CGFloat(currentValue)
                    
                    let currentTransform = scaleTranslateTransform(t)
                    let currentFrame = startFrame.applying(currentTransform)
                    self?.setFrame(currentFrame, display: true)
                }
            }}(frame, endFrame)
    }
    private func fadeAnimation(destination endValue: CGFloat) -> TouchBarAnimation.AnimationFunc {
        return {(startValue, endValue) in
            let dAlphaValue = endValue - startValue
            let scaleValue = {(t: CGFloat) in return startValue + dAlphaValue * t}
            
            return { [weak self] (currentProgress: Float, currentValue: Float) in
                if currentProgress == 1.0 {
                    self?.alphaValue = endValue
                }
                else {
                    let t = CGFloat(currentValue)
                    self?.alphaValue = scaleValue(t)
                }
            }}(alphaValue, endValue)
    }
    private func teleportAnimation(destination endFrame: CGRect) -> TouchBarAnimation.AnimationFunc {
        return {(savedAlphaValue, startFrame) in
            let scaledValue = {(t: CGFloat) in return savedAlphaValue * abs(t * 2 - 1)}
            let dy = frame.height
            
            let scaleTranslateTransform = {(t: CGFloat) in
                return CGAffineTransform.identity
                    .translatedBy(x: 0, y: dy * (1 - abs(t * 2 - 1)))
            }
            
            return { [weak self] (currentProgress: Float, currentValue: Float) in
                if currentProgress == 1.0 {
                    self?.alphaValue = savedAlphaValue
                    self?.setFrame(endFrame, display: true)
                }
                else {
                    let t = CGFloat(currentValue)
                    
                    let currentTransform = scaleTranslateTransform(t)
                    if currentProgress <= 0.5 {
                        let currentFrame = startFrame.applying(currentTransform)
                        self?.setFrame(currentFrame, display: true)
                    }
                    else {
                        let currentFrame = endFrame.applying(currentTransform)
                        self?.setFrame(currentFrame, display: true)
                    }
                    
                    self?.alphaValue = scaledValue(t)
                }
            }}(alphaValue, frame)
    }
    
    // Funcs for calculating Window Move Destination
    private func destinationOrigin(_ forDocking: Docking, _ forHiding: Bool, inScreen targetScreen: NSScreen?) -> CGPoint {
        let savedValue = Defaults[.lastFloatingPosition]
        switch(forDocking, forHiding) {
        case (.floating, _):
            return savedValue
        case (.dockedToTop, false):
            return alignedOrigin(.center, .top, inScreen: targetScreen)
        case (.dockedToBottom, false):
            return alignedOrigin(.center, .bottom, inScreen: targetScreen)
        case (.dockedToTop, true):
            return alignedOrigin(.center, .topOut, inScreen: targetScreen)
        case (.dockedToBottom, true):
            return alignedOrigin(.center, .bottomOut, inScreen: targetScreen)
        }
    }
    private func destinationFrame(_ forDocking: Docking, _ forHiding: Bool, inScreen targetScreen: NSScreen?) -> CGRect {
        switch(forDocking, forHiding) {
        case (.floating, _):
            let savedFrame = constrainFrameRect(CGRect(origin: destinationOrigin(forDocking, forHiding, inScreen: targetScreen), size: CGSize(width: frame.width, height: frame.height)), to: targetScreen)
            if NSScreen.screens.map({return $0.visibleFrame.contains(savedFrame)}).contains(true) {
                return savedFrame
            }
            else {
                return constrainFrameRect(CGRect(origin: alignedOrigin(.center, .center, inScreen: targetScreen), size: CGSize(width: frame.width, height: frame.height)), to: targetScreen)
            }
        case (_, _):
            let result = constrainFrameRect(CGRect(origin: destinationOrigin(forDocking, forHiding, inScreen: targetScreen), size: CGSize(width: frame.width, height: frame.height)), to: targetScreen)
            //NSLog("\(targetScreen)->\(result)")
            return result
        }
    }
    
    // Slot funcs for UI Elements
    @objc func dockDownPressed(_: NSButton) {
        docking = .dockedToBottom
    }
    @objc func dockUpPressed(_: NSButton) {
        docking = .dockedToTop
    }
    @objc func viewSideButtonPressed(_ sender: NSButton) {
        if let event = NSApp.currentEvent {
            
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)
            let isComandKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.command)
            
            switch (isComandKeyPressed, isOptionKeyPressed) {
            case (true, _):
                TouchBarContextMenu.showContextMenu(sender)
            case (false, true):
                close()
            case (false, false):
                docking = .floating
            }
        }
    }
    @objc func settingsPressed(_ sender: NSButton) {
        TouchBarContextMenu.showContextMenu(sender)
    }
    
    // Convenient init
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [
                //.titled,
                .closable,
                .nonactivatingPanel,
                .hudWindow, // Setting this flag always renders title bar in darkAqua...
                .resizable,
                .utilityWindow,
            ],
            backing: .buffered,
            defer: false
        )
        cyclicalUpdateTimer = {
            Timer(timeInterval: 0.5, repeats: true) {timer in
                self.handleCyclicalUpdate()
            }
        }()
        delegate = self
        isReleasedWhenClosed = false
        collectionBehavior = .canJoinAllSpaces
        title = "Touch Bar".localized
        level = .assistiveTechHigh
        backgroundColor = .clear
        isOpaque = false
        isRestorable = true
        hidesOnDeactivate = false
        worksWhenModal = true
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = false
        appearance = NSAppearance(named: NSAppearance.Name.darkAqua) // As `.hudWindow` flag set, we always render the window in darkAqua
        
        contentView = NSView()
    }
    //private static let instance = TouchBarWindow()
    
    // Class funcs for accessing singleton object
    func setUp() {
        let previousDocking = Defaults[.windowDocking]
        let previousFrame = Defaults[.lastWindowFrame]
        
        switch previousDocking {
        case .floating:
            hasTitle = true
            setFrame(previousFrame, display: true)
        case .dockedToTop:
            hasTitle = false
            setFrame(previousFrame, display: true)
        case .dockedToBottom:
            hasTitle = false
            setFrame(previousFrame, display: true)
        }
        
        //docking = previousDocking
        
        // Add cyclicalObserver
        cyclicalUpdateTimer = Timer(timeInterval: 0.5, repeats: true) {[weak self] timer in
            self?.handleCyclicalUpdate()
        }
        
        // Show instance
        orderFrontRegardless()
    }
    func finishUp() {
        // Remove cyclicalObserver
        cyclicalUpdateTimer = nil
        
        // save last float position
        if docking == .floating {
            Defaults[.lastFloatingPosition] = frame.origin
        }
        
        Defaults[.lastWindowFrame] = frame
    }
    
    
}

class TouchBarWindowManager {
    static let instance = TouchBarWindow()
    
    static var isClosed: Bool {
        return instance.isClosed
    }
    
    static var showOnAllDesktops = true {
        didSet {
            if showOnAllDesktops {
                instance.collectionBehavior = .canJoinAllSpaces
            } else {
                instance.collectionBehavior = .moveToActiveSpace
            }
        }
    }
    static var dockSetting: TouchBarWindow.Docking = .floating {
        didSet {
            instance.docking = dockSetting
        }
    }
    
    static func setUp() {
        instance.setUp()
    }
    
    static func finishUp() {
        instance.finishUp()
    }
    
}
