import XCTest

import CodeGenTests
import ParserTests

var tests = [XCTestCaseEntry]()
tests += CodeGenTests.__allTests()
tests += ParserTests.__allTests()

XCTMain(tests)
