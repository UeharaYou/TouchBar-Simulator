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
    class TestWindow: NSWindow {
        var expectation: XCTestExpectation? = nil
        @objc func dismiss() {
            if let expectation = expectation {
                expectation.fulfill()
            }
            close()
        }
    }
    
    class TestTouchBarWindow: TouchBarWindow {
        var expectation: XCTestExpectation? = nil
        override func close() {
            if let expectation = expectation {
                expectation.fulfill()
            }
            super.close()
        }
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScreenView() throws {
        let viewTuples = NSScreen.frameViews
        let expectation = viewTuples.map {
            ($0, XCTestExpectation(description: "\($0)"))
        }
        
        DispatchQueue.main.async {
            let _ = expectation.map {
                let (screen, _, visibleView) = $0.0
                let window = TestWindow()
                let button = NSButton(title: "Screen Visible Frame. Click to Dismiss.", target: window, action: #selector(TestWindow.dismiss))
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
                window.expectation = $0.1
                window.backgroundColor = .clear
                window.contentView = visibleView
                window.setFrame(screen.visibleFrame, display: true)
                window.orderFrontRegardless()
                return window
            }
        }

        wait(for: expectation.map{$0.1})
        
        return
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testIndependentTouchBarView() throws {
        let viewTuples = NSScreen.frameViews
        let expectation = viewTuples.map {
            ($0, XCTestExpectation(description: "\($0)"))
        }
        
        DispatchQueue.main.async {
            let _ = expectation.map {
                let (screen, _, visibleView) = $0.0
                let window = TestTouchBarWindow()
                window.confinementView = visibleView
                window.title = "Touch Bar [Test Window]"
                window.setUp()
                window.docking = .floating
                window.expectation = $0.1
                window.backgroundColor = .clear
                window.setFrame(screen.visibleFrame, display: true)
                //window.setContentSize(visibleView.fittingSize)
                window.orderFrontRegardless()
                return window
            }
        }

        wait(for: expectation.map{$0.1})
        
        return
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        //measure {
            // Put the code you want to measure the time of here.
        //}
    }

}
