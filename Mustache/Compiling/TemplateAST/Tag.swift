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


import Foundation

// For some reason, declaring a Type enum inside the Tag class prevents
// variables to be declared as Tag.Type.
// So let's use a `TagType` type instead.
public enum TagType {
    case Variable
    case Section
}
    
public class Tag: Printable {
    public let type: TagType
    public let innerTemplateString: String
    var inverted: Bool
    var expression: Expression
    
    init(type: TagType, innerTemplateString: String, inverted: Bool, expression: Expression) {
        self.type = type
        self.innerTemplateString = innerTemplateString
        self.inverted = inverted
        self.expression = expression
    }
    
    public func renderInnerContent(context: Context, error: NSErrorPointer = nil) -> Rendering? {
        fatalError("Subclass must override")
    }
    
    public var description: String {
        fatalError("Subclass must override")
    }
}
