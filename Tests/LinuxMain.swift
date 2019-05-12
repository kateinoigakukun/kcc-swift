import XCTest

import CodeGenTests
import ParserTests
import SemaTests

var tests = [XCTestCaseEntry]()
tests += CodeGenTests.__allTests()
tests += ParserTests.__allTests()
tests += SemaTests.__allTests()

XCTMain(tests)
