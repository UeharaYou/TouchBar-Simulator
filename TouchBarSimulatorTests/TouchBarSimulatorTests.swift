//
//  TouchBarSimulatorTests.swift
//  TouchBarSimulatorTests
//
//  Created by 上原葉 on 10/4/23.
//

import XCTest
@testable import TouchBarSimulator

@MainActor
final class TouchBarSimulatorTests: XCTestCase {
    class TestVoteWindow: NSWindow {
        var expectation: XCTestExpectation? = nil
        @objc func accept() {
            if let expectation = expectation {
                expectation.fulfill()
            }
            close()
        }
        @objc func reject() {
            XCTFail("Manual Inspection Failed.")
            if let expectation = expectation {
                expectation.fulfill()
            }
            close()
            
        }
        
        let acceptButton = NSButton(title: "Accept", target: nil, action: #selector(TestVoteWindow.accept))
        let rejectButton = NSButton(title: "Reject", target: nil, action: #selector(TestVoteWindow.reject))
        
        func voteView() -> NSView  {
            let voteView = NSView()
            voteView.addSubview(acceptButton)
            voteView.addSubview(rejectButton)
            acceptButton.translatesAutoresizingMaskIntoConstraints = false
            rejectButton.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-3-[acp(>=100)]-3-[rej(>=100)]-3-|", metrics: nil, views: ["acp": acceptButton, "rej": rejectButton]),
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[btn(>=50)]-3-|", metrics: nil, views: ["btn": acceptButton]),
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-3-[btn(>=50)]-3-|", metrics: nil, views: ["btn": rejectButton]),
            ].reduce([], +)
            voteView.addConstraints(constraints)
            NSLayoutConstraint.activate(constraints)
            
            voteView.layout()

            return voteView
        }
        
        func show() {
            level = .assistiveTechHigh
            isReleasedWhenClosed = false
            title = "Test Result Vote"
            acceptButton.target = self
            rejectButton.target = self
            contentView = voteView()
            layoutIfNeeded()
            setFrame(NSRect(x: NSScreen.main?.frame.midX ?? 100, y: NSScreen.main?.frame.midY ?? 100, width: 0, height: 0), display: true)
            orderFrontRegardless()
        }
    }
    
    override func setUpWithError() throws {
        TouchBarWindowManager.instance.orderOut(nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testScreenView() throws {
        let viewTuples = NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Manual Inspection")
        
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
            let manualVote = TestVoteWindow()
            manualVote.expectation = expectation
            manualVote.show()
        }
        
        wait(for: [expectation])
        
        return
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testWindowForAllScreenView() async throws {
        let viewTuples = NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Manual Inspection")
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
                    let newWindow = TestVoteWindow()
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
        
        let manualVote = TestVoteWindow()
        manualVote.expectation = expectation
        manualVote.show()
        
        await fulfillment(of: [expectation])
        
        return
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testDetectionRectForAllScreenView() async throws {
        let viewTuples = NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Manual Inspection")
        
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
        let manualVote = TestVoteWindow()
        manualVote.expectation = expectation
        manualVote.show()
        
        
        await fulfillment(of: [expectation])
        
        return
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testIndependentTouchBarView() throws {
        let viewTuples = [(NSScreen.main!, NSView(), NSView.frameView(from: .init(origin: .init(x: 0, y: 0), size: .init(width: 300, height: 100))))]//NSScreen.frameViews
        let expectation = XCTestExpectation(description: "Manual Inspection")
        
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
            
            let manualVote = TestVoteWindow()
            manualVote.expectation = expectation
            manualVote.show()
        }
        
        wait(for: [expectation])
        
        return
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
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
    
}
