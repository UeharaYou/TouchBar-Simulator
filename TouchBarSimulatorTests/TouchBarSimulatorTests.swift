//
//  TouchBarSimulatorTests.swift
//  TouchBarSimulatorTests
//
//  Created by 上原葉 on 10/4/23.
//

import XCTest
@testable import TouchBarSimulator

class TestFeedBackWindow: NSWindow {
    
    var expectation: XCTestExpectation? = nil
    @objc func accept() {
        if let expectation = expectation {
            expectation.fulfill()
        }
        close()
    }
    @objc func reject() {
        let rejectString = feedBackInput.stringValue
        if rejectString.isEmpty {
            XCTFail("Test REJECTED during manual inspection.")
        }
        else {
            XCTFail("Test REJECTED during manual inspection: \(rejectString)")
        }
        if let expectation = expectation {
            expectation.fulfill()
        }
        close()
        
    }
    
    let acceptButton = NSButton(title: "Accept", target: nil, action: #selector(TestFeedBackWindow.accept))
    let rejectButton = NSButton(title: "Reject", target: nil, action: #selector(TestFeedBackWindow.reject))
    let feedBackInput = with(NSTextField()){$0.placeholderString = "Reason of rejection."; $0.lineBreakMode = .byTruncatingHead; $0.maximumNumberOfLines = 1}
    
    func voteView(desc: String) -> NSView  {
        let descriptionText = NSTextField(labelWithString: desc)
        
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let textScrollView = NSScrollView()
        textScrollView.translatesAutoresizingMaskIntoConstraints = false
        textScrollView.borderType = .bezelBorder
        textScrollView.backgroundColor = .clear
        textScrollView.hasVerticalScroller = true
        textScrollView.autohidesScrollers = true
        
        descriptionText.translatesAutoresizingMaskIntoConstraints = false
        descriptionText.alignment = .center
        descriptionText.lineBreakMode = .byWordWrapping
        
        let textClipView = NSClipView()
        textClipView.translatesAutoresizingMaskIntoConstraints = false
        textScrollView.contentView = textClipView

        let textDocumentView = NSView()
        textDocumentView.translatesAutoresizingMaskIntoConstraints = false
        textScrollView.documentView = textDocumentView
        textClipView.addConstraint(NSLayoutConstraint(item: textClipView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: (NSScreen.main?.frame.width ?? 1600) * 0.25))
        textClipView.addConstraint(NSLayoutConstraint(item: textClipView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: (NSScreen.main?.frame.height ?? 2000) * 0.25))
        textClipView.addConstraint(NSLayoutConstraint(item: textClipView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50))
        textClipView.addConstraint(with(NSLayoutConstraint(item: textClipView, attribute: .width, relatedBy: .equal, toItem: textDocumentView, attribute: .width, multiplier: 1.0, constant: 0), update: {$0.priority = .required - 1}))
        textClipView.addConstraint(with(NSLayoutConstraint(item: textClipView, attribute: .height, relatedBy: .equal, toItem: textDocumentView, attribute: .height, multiplier: 1.0, constant: 0), update: {$0.priority = .windowSizeStayPut + 1}))
        
        textDocumentView.addSubview(descriptionText)
        let textDocumentConstraints = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[btn]|", metrics: nil, views: ["btn": descriptionText]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[btn(>=45)]|", metrics: nil, views: ["btn": descriptionText]),
        ].reduce([], +)
        textDocumentView.addConstraints(textDocumentConstraints)
        NSLayoutConstraint.activate(textDocumentConstraints)
        
        let voteView = NSView()
        voteView.translatesAutoresizingMaskIntoConstraints = false
        
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        voteView.addSubview(acceptButton)
        voteView.addSubview(rejectButton)
        let voteConstraints = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-6-[acp(>=100)]-3-[rej(>=100)]-6-|", metrics: nil, views: ["acp": acceptButton, "rej": rejectButton]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[btn]-3-|", metrics: nil, views: ["btn": acceptButton]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[btn]-3-|", metrics: nil, views: ["btn": rejectButton]),
            [NSLayoutConstraint(item: acceptButton, attribute: .width, relatedBy: .equal, toItem: rejectButton, attribute: .width, multiplier: 2, constant: 0)]
        ].reduce([], +)
        voteView.addConstraints(voteConstraints)
        NSLayoutConstraint.activate(voteConstraints)
        
        voteView.layout()

        feedBackInput.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(feedBackInput)
        view.addSubview(voteView)
        view.addSubview(textScrollView)
        
        let constraints = [
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[txt]-5-[feedBackInput]-3-[vote]-3-|", metrics: nil, views: ["txt": textScrollView, "vote": voteView, "feedBackInput": feedBackInput]),
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[btn]-10-|", metrics: nil, views: ["btn": textScrollView]),
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-3-[btn]-3-|", metrics: nil, views: ["btn": voteView]),
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[btn]-10-|", metrics: nil, views: ["btn": feedBackInput]),
        ].reduce([], +)
        view.addConstraints(constraints)
        NSLayoutConstraint.activate(constraints)
        
        //view.layout()
        return view
    }
    
    func show() {
        level = .assistiveTechHigh
        isReleasedWhenClosed = false
        title = "Test Feedback"
        
        acceptButton.target = self
        rejectButton.target = self
        
        contentView = voteView(desc: expectation?.expectationDescription ?? "")
        layoutIfNeeded()
        updateConstraintsIfNeeded()
        setFrame(NSRect(x: NSScreen.main?.frame.midX ?? 100, y: NSScreen.main?.frame.midY ?? 100, width: 0, height: 0), display: true)
        orderFrontRegardless()
    }
}


@MainActor
final class TouchBarSimulatorTests: XCTestCase {
    
    override func setUpWithError() throws {
        TouchBarWindowManager.instance.orderOut(nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testScreenView() throws {
        let viewTuples = NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Test: \(#function).")
        
        DispatchQueue.main.async {
            let _ = viewTuples.map {
                let (screen, _, visibleView) = $0
                let window = NSWindow()
                let button = NSButton(title: "Screen Visible Frame. Click to Dismiss.", target: window, action: #selector(NSWindow.close))
                button.isBordered = false
                visibleView.addSubview(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                let constraints = [
                    NSLayoutConstraint.constraints(withVisualFormat: "H:|-100-[btn]-100-|", metrics: nil, views: ["btn": button]),
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|-100-[btn]-100-|", metrics: nil, views: ["btn": button]),
                ].reduce([], +)
                visibleView.addConstraints(constraints)
                visibleView.wantsLayer = true
                visibleView.updateLayer()
                visibleView.layer?.borderColor = .white
                visibleView.layer?.borderWidth = 10.0
                visibleView.layer?.backgroundColor = .black
                visibleView.alphaValue = 0.5
                NSLayoutConstraint.activate(constraints)
                
                window.styleMask = []
                window.isReleasedWhenClosed = false
                window.backgroundColor = .clear
                window.contentView = visibleView
                window.setFrame(screen.visibleFrame, display: true)
                window.orderFrontRegardless()
                return window
            }
            let manualVote = TestFeedBackWindow()
            manualVote.expectation = expectation
            manualVote.show()
        }
        
        wait(for: [expectation])
        
        return

    }
    
    func testWindowForAllScreenView() async throws {
        let viewTuples = NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Test: \(#function).")
        let tuple = viewTuples.map {
            let (screen, _, visibleView) = $0
            let window = TouchBarWindow()
            return (window, screen, visibleView)
        }
        
        await withCheckedContinuation { continuation in
            _ = tuple.map { (window, screen, visibleView) in
                window.confinementView = visibleView
                window.title = "Touch Bar [Test Window]"
                window.setUp()
                //window.docking = .floating
                window.backgroundColor = .clear
                window.setFrame(NSRect(origin: screen.visibleFrame.origin, size: visibleView.fittingSize) , display: true)
                //window.setContentSize(visibleView.fittingSize)
                window.orderFrontRegardless()
            }
            let timer = Timer(timeInterval: 1, repeats: false)
            { _ in
                //Thread.sleep(forTimeInterval: 1)
                continuation.resume()
            }
            RunLoop.main.add(timer, forMode: .default)
        }
        
        await withCheckedContinuation { continuation in
            _  = tuple.map { (window, screen, visibleView) in
                for docking in [TouchBarWindow.Docking.dockedToTop, .dockedToBottom] {
                    let newWindow = TestFeedBackWindow()
                    newWindow.styleMask = []
                    let destFrame = window.destinationFrame(for: docking, for: false, in: screen)
                    let destView = NSView.frameView(from: destFrame)
                    destView.wantsLayer = true
                    destView.layer?.borderColor = .white
                    destView.layer?.borderWidth = 10.0
                    destView.layer?.backgroundColor = .black
                    destView.alphaValue = 0.5
                    newWindow.contentView = destView
                    newWindow.backgroundColor = .cyan
                    newWindow.alphaValue = 0.5
                    newWindow.setFrame(destFrame, display: true)
                    newWindow.orderFrontRegardless()
                }
            }
            let timer = Timer(timeInterval: 0.5, repeats: false)
            { _ in
                //Thread.sleep(forTimeInterval: 1)
                continuation.resume()
            }
            RunLoop.main.add(timer, forMode: .default)
        }
        
        let manualVote = TestFeedBackWindow()
        manualVote.expectation = expectation
        manualVote.show()
        
        await fulfillment(of: [expectation])
        
        return

    }
    
    func testDetectionRectForAllScreenView() async throws {
        let viewTuples = NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Test: \(#function).")
        
        let tuple = viewTuples.map {
            let (screen, _, visibleView) = $0
            let window = TouchBarWindow()
            return (window, screen, visibleView)
        }
        
        await withCheckedContinuation { continuation in
            _  = tuple.map { (window, screen, visibleView) in
                window.confinementView = visibleView
                window.title = "Touch Bar [Test Window]"
                window.setUp()
                window.docking = .floating
                window.backgroundColor = .clear
                window.setFrame(NSRect(origin: screen.visibleFrame.origin, size: visibleView.fittingSize) , display: true)
                //window.setContentSize(visibleView.fittingSize)
                window.orderFrontRegardless()
            }
            let timer = Timer(timeInterval: 1, repeats: false)
            { _ in
                //Thread.sleep(forTimeInterval: 1)
                continuation.resume()
            }
            RunLoop.main.add(timer, forMode: .default)
        }
        await withCheckedContinuation { continuation in
            _  = tuple.map { (window, screen, visibleView) in
                for docking in [TouchBarWindow.Docking.dockedToTop, .dockedToBottom] {
                    for hiding in [true, false] {
                        //Thread.sleep(forTimeInterval: 1)
                        let newWindow = NSWindow()
                        newWindow.level = .assistiveTechHigh
                        newWindow.styleMask = []
                        let destFrame = window.detectionFrame(for: docking, for: hiding, in: screen)
                        let destView = NSView.frameView(from: destFrame)
                        destView.wantsLayer = true
                        destView.layer?.borderColor = .white
                        destView.layer?.borderWidth = 10.0
                        destView.layer?.backgroundColor = .black
                        destView.alphaValue = 0.5
                        newWindow.contentView = destView
                        newWindow.backgroundColor = !hiding ? .cyan : .magenta
                        newWindow.alphaValue = 0.5
                        newWindow.setFrame(destFrame, display: true)
                        newWindow.orderFrontRegardless()
                    }
                }
            }
            let timer = Timer(timeInterval: 0.5, repeats: false)
            { _ in
                //Thread.sleep(forTimeInterval: 1)
                continuation.resume()
            }
            RunLoop.main.add(timer, forMode: .default)
        }
        let manualVote = TestFeedBackWindow()
        manualVote.expectation = expectation
        manualVote.show()
        
        
        await fulfillment(of: [expectation])
        
        return

    }
    
    func testIndependentTouchBarView() throws {
        let viewTuples = [(NSScreen.main!, NSView(), NSView.frameView(from: .init(origin: .init(x: 0, y: 0), size: .init(width: 300, height: 100))))]//NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Test: \(#function).")
        
        DispatchQueue.main.async {
            let _ = viewTuples.map {
                let (screen, _, visibleView) = $0
                let window = TouchBarWindow()
                window.confinementView = visibleView
                window.title = "Touch Bar [Test Window]"
                window.setUp()
                window.docking = .floating
                window.backgroundColor = .clear
                window.setFrame(screen.visibleFrame, display: true)
                //window.setContentSize(visibleView.fittingSize)
                window.orderFrontRegardless()
                
                return window
            }
            
            let manualVote = TestFeedBackWindow()
            manualVote.expectation = expectation
            manualVote.show()
        }
        
        wait(for: [expectation])
        
        return

    }
    
    /*
    func testPerformanceExample() async throws {
        await withCheckedContinuation { continuation in
            let timer = Timer(timeInterval: 1, repeats: false) { timer in
                continuation.resume()
            }
            
            RunLoop.main.add(timer, forMode: .default)
        }
        // This is an example of a performance test case.
        //measure {
        // Put the code you want to measure the time of here.
        //}
    }
    */
    
}
