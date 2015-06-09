// The MIT License
//
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import XCTest
import Mustache

class SuiteTestCase: XCTestCase {
    
    func runTestsFromResource(name: String, directory: String) {
        let testBundle = NSBundle(forClass: self.dynamicType)
        let path: String! = testBundle.pathForResource(name, ofType: nil, inDirectory: directory)
        if path == nil {
            XCTFail("No such test suite \(directory)/\(name)")
            return
        }
        
        let data: NSData! = NSData(contentsOfFile:path)
        if data == nil {
            XCTFail("No test suite in \(path)")
            return
        }
        
        var error: NSError?
        let testSuite = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue: 0)) as! NSDictionary!
        if testSuite == nil {
            XCTFail("\(error)")
            return
        }
        
        let tests = testSuite["tests"] as! NSArray!
        if tests == nil {
            XCTFail("Missing tests in \(path)")
            return
        }
        
        for testDictionary in tests {
            let test = Test(path: path, dictionary: testDictionary as! NSDictionary)
            test.run()
        }
    }
    
    class Test {
        let path: String
        let dictionary: NSDictionary
        
        init(path: String, dictionary: NSDictionary) {
            self.path = path
            self.dictionary = dictionary
        }
        
        func run() {
            let name = dictionary["name"] as! String
            NSLog("Run test \(name)")
            for template in templates {
                
                // Standard Library
                template.registerInBaseContext("each", Box(StandardLibrary.each))
                template.registerInBaseContext("zip", Box(StandardLibrary.zip))
                template.registerInBaseContext("localize", Box(StandardLibrary.Localizer(bundle: nil, table: nil)))
                template.registerInBaseContext("HTMLEscape", Box(StandardLibrary.HTMLEscape))
                template.registerInBaseContext("URLEscape", Box(StandardLibrary.URLEscape))
                template.registerInBaseContext("javascriptEscape", Box(StandardLibrary.javascriptEscape))
                
                // Support for filters.json
                template.registerInBaseContext("capitalized", Box(Filter({ (string: String?, _) -> MustacheBox? in
                    return Box(string?.capitalizedString)
                })))
                
                testRendering(template)
            }
        }
        
        //
        
        var description: String { return "test `\(name)` at \(path)" }
        var name: String { return dictionary["name"] as! String }
        var partialsDictionary: [String: String]? { return dictionary["partials"] as! [String: String]? }
        var templateString: String? { return dictionary["template"] as! String? }
        var templateName: String? { return dictionary["template_name"] as! String? }
        var renderedValue: MustacheBox { return BoxAnyObject(dictionary["data"]) }
        var expectedRendering: String? { return dictionary["expected"] as! String? }
        var expectedError: String? { return dictionary["expected_error"] as! String? }
        
        var templates: [Template] {
            if let partialsDictionary = partialsDictionary {
                if let templateName = templateName {
                    var templates: [Template] = []
                    let templateExtension = templateName.pathExtension
                    for (directoryPath, encoding) in pathsAndEncodingsToPartials(partialsDictionary) {
                        var error: NSError?
                        do {
                            let template = try TemplateRepository(directoryPath: directoryPath, templateExtension: templateExtension, encoding: encoding).template(named: templateName.stringByDeletingPathExtension)
                            templates.append(template)
                        } catch var error2 as NSError {
                            error = error2
                            XCTAssertNotNil(error, "Expected parsing error in \(description)")
                            testError(error!, replayOnFailure: {
                                let template: Template?
                                do {
                                    template = try TemplateRepository(directoryPath: directoryPath, templateExtension: templateExtension, encoding: encoding).template(named: templateName.stringByDeletingPathExtension)
                                } catch var error1 as NSError {
                                    error = error1
                                    template = nil
                                } catch {
                                    fatalError()
                                }
                            })
                        }
                        do {
                            let template = try TemplateRepository(baseURL: NSURL.fileURLWithPath(directoryPath)!, templateExtension: templateExtension, encoding: encoding).template(named: templateName.stringByDeletingPathExtension)
                            templates.append(template)
                        } catch var error2 as NSError {
                            error = error2
                            XCTAssertNotNil(error, "Expected parsing error in \(description)")
                            testError(error!, replayOnFailure: {
                                let template: Template?
                                do {
                                    template = try TemplateRepository(baseURL: NSURL.fileURLWithPath(directoryPath)!, templateExtension: templateExtension, encoding: encoding).template(named: templateName.stringByDeletingPathExtension)
                                } catch var error1 as NSError {
                                    error = error1
                                    template = nil
                                } catch {
                                    fatalError()
                                }
                            })
                        }
                    }
                    return templates
                } else if let templateString = templateString {
                    var templates: [Template] = []
                    for (directoryPath, encoding) in pathsAndEncodingsToPartials(partialsDictionary) {
                        var error: NSError?
                        do {
                            let template = try TemplateRepository(directoryPath: directoryPath, templateExtension: "", encoding: encoding).template(string: templateString)
                            templates.append(template)
                        } catch var error2 as NSError {
                            error = error2
                            XCTAssertNotNil(error, "Expected parsing error in \(description)")
                            testError(error!, replayOnFailure: {
                                let template: Template?
                                do {
                                    template = try TemplateRepository(directoryPath: directoryPath, templateExtension: "", encoding: encoding).template(string: templateString)
                                } catch var error1 as NSError {
                                    error = error1
                                    template = nil
                                } catch {
                                    fatalError()
                                }
                            })
                        }
                        do {
                            let template = try TemplateRepository(baseURL: NSURL.fileURLWithPath(directoryPath)!, templateExtension: "", encoding: encoding).template(string: templateString)
                            templates.append(template)
                        } catch var error2 as NSError {
                            error = error2
                            XCTAssertNotNil(error, "Expected parsing error in \(description)")
                            testError(error!, replayOnFailure: {
                                let template: Template?
                                do {
                                    template = try TemplateRepository(baseURL: NSURL.fileURLWithPath(directoryPath)!, templateExtension: "", encoding: encoding).template(string: templateString)
                                } catch var error1 as NSError {
                                    error = error1
                                    template = nil
                                } catch {
                                    fatalError()
                                }
                            })
                        }
                    }
                    return templates
                } else {
                    XCTFail("Missing `template` and `template_name` in \(description)")
                    return []
                }
            } else {
                if let templateName = templateName {
                    XCTFail("Missing `partials` in \(description)")
                    return []
                } else if let templateString = templateString {
                    var error: NSError?
                    do {
                        let template = try TemplateRepository().template(string: templateString)
                        return [template]
                    } catch var error2 as NSError {
                        error = error2
                        XCTAssertNotNil(error, "Expected parsing error in \(description)")
                        testError(error!, replayOnFailure: {
                            let template: Template?
                            do {
                                template = try TemplateRepository().template(string: templateString)
                            } catch var error1 as NSError {
                                error = error1
                                template = nil
                            } catch {
                                fatalError()
                            }
                        })
                        return []
                    }
                } else {
                    XCTFail("Missing `template` and `template_name` in \(description)")
                    return []
                }
            }
        }
        
        func testRendering(template: Template) {
            var error: NSError?
            do {
                let rendering = try template.render(renderedValue)
                if let expectedRendering = expectedRendering as String! {
                    if expectedRendering != rendering {
                        XCTAssertEqual(rendering, expectedRendering, "Unexpected rendering of \(description)")
                    }
                }
                testSuccess(replayOnFailure: {
                    let rendering: String?
                    do {
                        rendering = try template.render(self.renderedValue)
                    } catch var error1 as NSError {
                        error = error1
                        rendering = nil
                    } catch {
                        fatalError()
                    }
                })
            } catch var error2 as NSError {
                error = error2
                XCTAssertNotNil(error, "Expected rendering error in \(description)")
                testError(error!, replayOnFailure: {
                    let rendering: String?
                    do {
                        rendering = try template.render(self.renderedValue)
                    } catch var error1 as NSError {
                        error = error1
                        rendering = nil
                    } catch {
                        fatalError()
                    }
                })
            }
        }
        
        func testError(error: NSError, replayOnFailure replayBlock: ()->()) {
            if let expectedError = expectedError {
                var regError: NSError?
                do {
                    let reg = try NSRegularExpression(pattern: expectedError, options: NSRegularExpressionOptions(rawValue: 0))
                    let errorMessage = error.localizedDescription
                    let matches = reg.matchesInString(errorMessage, options: NSMatchingOptions(0), range:NSMakeRange(0, (errorMessage as NSString).length))
                    if matches.count == 0 {
                        XCTFail("`\(errorMessage)` does not match /\(expectedError)/ in \(description)")
                        replayBlock()
                    }
                } catch var error as NSError {
                    regError = error
                    XCTFail("Invalid expected_error in \(description): \(regError!)")
                    replayBlock()
                }
            } else {
                XCTFail("Unexpected error in \(description): \(error)")
                replayBlock()
            }
        }
        
        func testSuccess(replayOnFailure replayBlock: ()->()) {
            if expectedError != nil {
                XCTFail("Unexpected success in \(description)")
                replayBlock()
            }
        }
        
        func pathsAndEncodingsToPartials(partialsDictionary: [String: String]) -> [(String, NSStringEncoding)] {
            var templatesPaths: [(String, NSStringEncoding)] = []
            
            let fm = NSFileManager.defaultManager()
            var error: NSError?
            let encodings: [NSStringEncoding] = [NSUTF8StringEncoding, NSUTF16StringEncoding]
            for encoding in encodings {
                let templatesPath = NSTemporaryDirectory().stringByAppendingPathComponent("GRMustacheTest").stringByAppendingPathComponent("encoding_\(encoding)")
                if fm.fileExistsAtPath(templatesPath) && !fm.removeItemAtPath(templatesPath) {
                    XCTFail("Could not cleanup tests in \(description): \(error!)")
                    return []
                }
                for (partialName, partialString) in partialsDictionary {
                    let partialPath = templatesPath.stringByAppendingPathComponent(partialName)
                    do {
                        try fm.createDirectoryAtPath(partialPath.stringByDeletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
                    } catch var error1 as NSError {
                        error = error1
                        XCTFail("Could not save template in \(description): \(error!)")
                        return []
                    }
                    if !fm.createFileAtPath(partialPath, contents: partialString.dataUsingEncoding(encoding, allowLossyConversion: false), attributes: nil) {
                        XCTFail("Could not save template in \(description): \(error!)")
                        return []
                    }
                }
                
                templatesPaths.append(templatesPath, encoding)
            }
            
            return templatesPaths
        }
    }
}
