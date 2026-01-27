import XCTest
@testable import DeepLinkHandler

// MARK: - Test Helpers

/// Test module for deep link testing
class TestModule: AppModule {
    var urls: [DeepLinkModule] = []
    
    init(urls: [DeepLinkModule]) {
        self.urls = urls
    }
}

/// Test deep link handler that captures calls
class TestDeepLinkHandler: DeepLinkModule {
    var url: URLPattern
    var parameters: [String] = []
    var type: DeeplinkType = .navigation
    
    var capturedFullPath: URLConvertible?
    var capturedValues: [String: Any]?
    var capturedData: Data?
    var completionCalled = false
    
    init(url: URLPattern, parameters: [String] = [], type: DeeplinkType = .navigation) {
        self.url = url
        self.parameters = parameters
        self.type = type
    }
    
    func handle(
        fullPath: URLConvertible,
        values: [String: Any],
        data: Data?,
        completion: AppNavigationCompletion?
    ) {
        capturedFullPath = fullPath
        capturedValues = values
        capturedData = data
        completionCalled = true
        completion?(.success(Data()))
    }
}

// MARK: - DeepLinkConfig Tests

final class DeepLinkConfigTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset to default scheme before each test
        DeepLinkConfig.configure(scheme: "app")
    }
    
    func testDefaultScheme() {
        XCTAssertEqual(DeepLinkConfig.scheme, "app")
        XCTAssertEqual(DeepLinkConfig.baseURL, "app://")
    }
    
    func testConfigureScheme() {
        DeepLinkConfig.configure(scheme: "myapp")
        XCTAssertEqual(DeepLinkConfig.scheme, "myapp")
        XCTAssertEqual(DeepLinkConfig.baseURL, "myapp://")
    }
    
    func testBuildURLFromPath() {
        DeepLinkConfig.configure(scheme: "testapp")
        let url = DeepLinkConfig.buildURL(from: "profile/:id")
        XCTAssertEqual(url, "testapp://profile/:id")
    }
    
    func testBuildURLFromPathWithLeadingSlash() {
        DeepLinkConfig.configure(scheme: "testapp")
        let url = DeepLinkConfig.buildURL(from: "/profile/:id")
        XCTAssertEqual(url, "testapp://profile/:id")
    }
    
    func testBuildURLWithComplexPath() {
        DeepLinkConfig.configure(scheme: "myapp")
        let url = DeepLinkConfig.buildURL(from: "user/:id/posts/:postId")
        XCTAssertEqual(url, "myapp://user/:id/posts/:postId")
    }
}

// MARK: - DeepLinkHandler Scheme Configuration Tests

final class DeepLinkHandlerSchemeTests: XCTestCase {
    
    var handler: DeepLinkHandler!
    
    override func setUp() {
        super.setUp()
        handler = DeepLinkHandler.shared
        // Clear registry before each test
        #if DEBUG
        handler.clearRegistry()
        #endif
        // Reset scheme to default
        DeepLinkConfig.configure(scheme: "testapp")
    }
    
    func testModuleRegistrationWithScheme() {
        // Given: A module with path-only URLs
        let testHandler = TestDeepLinkHandler(url: "profile/:id")
        let module = TestModule(urls: [testHandler])
        
        // When: Register the module
        handler.registerModule {
            module
        }
        
        // Then: The URL should be registered with the configured scheme
        let expectation = expectation(description: "Deep link opened")
        handler.open(url: "testapp://profile/123") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testOpenWithPathOnly() {
        // Given: A registered module
        let testHandler = TestDeepLinkHandler(url: "settings")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening with path only (no scheme)
        let expectation = expectation(description: "Deep link opened")
        handler.open(url: "settings") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testOpenWithCompleteURL() {
        // Given: A registered module
        let testHandler = TestDeepLinkHandler(url: "profile/:id")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening with complete URL (with scheme)
        let expectation = expectation(description: "Deep link opened")
        handler.open(url: "testapp://profile/456") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testOpenWithDeepLinkPath() {
        // Given: A registered module
        let testHandler = TestDeepLinkHandler(url: "checkout")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening with DeepLinkPath (path only)
        let deepLinkPath = DeepLinkPath(path: "checkout", tracingKey: "test")
        let expectation = expectation(description: "Deep link opened")
        
        handler.open(deepLinkPath) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testOpenWithDifferentScheme() {
        // Given: A registered module with configured scheme "testapp"
        let testHandler = TestDeepLinkHandler(url: "profile/:id")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening with different scheme
        let expectation = expectation(description: "Deep link should fail")
        handler.open(url: "otherscheme://profile/123") { result in
            switch result {
            case .success:
                XCTFail("Should fail with different scheme")
            case .failure(let error):
                if let deepLinkError = error as? DeepLinkError,
                   case .handlerNotFound = deepLinkError {
                    expectation.fulfill()
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testSchemeChangeAfterRegistration() {
        // Given: Register module with scheme "testapp"
        let testHandler = TestDeepLinkHandler(url: "settings")
        let module = TestModule(urls: [testHandler])
        
        DeepLinkConfig.configure(scheme: "testapp")
        handler.registerModule {
            module
        }
        
        // When: Change scheme
        DeepLinkConfig.configure(scheme: "newapp")
        
        // Then: Module registered with old scheme should still work with old scheme URL
        let expectation1 = expectation(description: "Deep link opened with old scheme")
        handler.open(url: "testapp://settings") { result in
            switch result {
            case .success:
                expectation1.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        // And: Opening with path should use new scheme, but module was registered with old scheme
        // So we need to register again or use the old scheme URL
        let expectation2 = expectation(description: "Deep link should fail with new scheme")
        handler.open(url: "newapp://settings") { result in
            switch result {
            case .success:
                XCTFail("Should fail because module was registered with old scheme")
            case .failure:
                expectation2.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - DeepLinkHandler Integration Tests

final class DeepLinkHandlerIntegrationTests: XCTestCase {
    
    var handler: DeepLinkHandler!
    
    override func setUp() {
        super.setUp()
        handler = DeepLinkHandler.shared
        // Clear registry before each test
        #if DEBUG
        handler.clearRegistry()
        #endif
        DeepLinkConfig.configure(scheme: "testapp")
    }
    
    func testMultipleModulesRegistration() {
        // Given: Multiple modules
        let profileHandler = TestDeepLinkHandler(url: "profile/:id")
        let settingsHandler = TestDeepLinkHandler(url: "settings")
        let checkoutHandler = TestDeepLinkHandler(url: "checkout/:orderId")
        
        let profileModule = TestModule(urls: [profileHandler])
        let settingsModule = TestModule(urls: [settingsHandler])
        let checkoutModule = TestModule(urls: [checkoutHandler])
        
        // When: Register all modules
        handler.registerModule { profileModule }
        handler.registerModule { settingsModule }
        handler.registerModule { checkoutModule }
        
        // Then: All should work
        let expectations = [
            expectation(description: "Profile opened"),
            expectation(description: "Settings opened"),
            expectation(description: "Checkout opened")
        ]
        
        handler.open(url: "profile/123") { result in
            if case .success = result { expectations[0].fulfill() }
        }
        
        handler.open(url: "settings") { result in
            if case .success = result { expectations[1].fulfill() }
        }
        
        handler.open(url: "checkout/456") { result in
            if case .success = result { expectations[2].fulfill() }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testPathWithParameters() {
        // Given: Module with parameters
        let testHandler = TestDeepLinkHandler(url: "product/:int:id/:string:category")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening with parameters
        let expectation = expectation(description: "Deep link opened")
        handler.open(url: "product/123/electronics") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testHandlerNotFound() {
        // Given: No registered modules
        // When: Opening non-existent deep link
        let expectation = expectation(description: "Should fail")
        handler.open(url: "nonexistent/path") { result in
            switch result {
            case .success:
                XCTFail("Should fail")
            case .failure(let error):
                if let deepLinkError = error as? DeepLinkError,
                   case .handlerNotFound = deepLinkError {
                    expectation.fulfill()
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testSubscribeMethod() {
        // Given: Module to subscribe
        let testHandler = TestDeepLinkHandler(url: "subscribe/test")
        let module = TestModule(urls: [testHandler])
        
        // When: Using subscribe method
        handler.subscribe {
            module
        }
        
        // Then: Should work
        let expectation = expectation(description: "Deep link opened")
        handler.open(url: "subscribe/test") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should not fail: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Async/Await Tests

@available(iOS 13.0, *)
final class DeepLinkHandlerAsyncTests: XCTestCase {
    
    var handler: DeepLinkHandler!
    
    override func setUp() {
        super.setUp()
        handler = DeepLinkHandler.shared
        // Clear registry before each test
        #if DEBUG
        handler.clearRegistry()
        #endif
        DeepLinkConfig.configure(scheme: "testapp")
    }
    
    func testOpenAsyncWithPath() async throws {
        // Given: Registered module
        let testHandler = TestDeepLinkHandler(url: "async/test")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening async with path only
        let result = try await handler.open(url: "async/test")
        XCTAssertNotNil(result)
    }
    
    func testOpenAsyncWithCompleteURL() async throws {
        // Given: Registered module
        let testHandler = TestDeepLinkHandler(url: "async/complete")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening async with complete URL
        let result = try await handler.open(url: "testapp://async/complete")
        XCTAssertNotNil(result)
    }
    
    func testOpenAsyncWithDeepLinkPath() async throws {
        // Given: Registered module
        let testHandler = TestDeepLinkHandler(url: "async/path")
        let module = TestModule(urls: [testHandler])
        
        handler.registerModule {
            module
        }
        
        // When: Opening async with DeepLinkPath
        let deepLinkPath = DeepLinkPath(path: "async/path", tracingKey: nil)
        let result = try await handler.open(url: deepLinkPath)
        XCTAssertNotNil(result)
    }
}
