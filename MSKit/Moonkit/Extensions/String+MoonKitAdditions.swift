//
//  String+MoonKitAdditions.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/15/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

public extension String {

  static let Space:       String = " "
  static let Newline:     String = "\n"
  static let Tab:         String = "\t"
  static let CommaSpace:  String = ", "
  static let Quote:       String = "'"
  static let DoubleQuote: String = "\""

  var length: Int { return countElements(self) }

  /**
  subscript:

  :param: i Int

  :returns: Character
  */
  subscript (i: Int) -> Character {
    let index: String.Index = advance(i < 0 ? self.endIndex : self.startIndex, i)
    return self[index]
  }

  /**
  subscript:

  :param: r Range<Int>

  :returns: String
  */
  subscript (r: Range<Int>) -> String {
    let rangeStart: String.Index = advance(startIndex, r.startIndex)
    let rangeEnd:   String.Index = advance(r.endIndex < 0 ? endIndex : startIndex, r.endIndex)
    let range: Range<String.Index> = Range<String.Index>(start: rangeStart, end: rangeEnd)
    return self[range]
  }

  /**
  matchFirst:

  :param: pattern String
  :returns: [String?]
  */
  func matchFirst(pattern: String) -> [String?] { return matchFirst(~/pattern) }


  /**
  matchFirst:

  :param: regex NSRegularExpression
  :returns: [String?]
  */
  func matchFirst(regex: NSRegularExpression) -> [String?] {

  	let match: NSTextCheckingResult? = regex.firstMatchInString(self,
                                                        options: nil,
                                                          range: NSRange(location: 0, length: (self as NSString).length))
  	var captures: [String?] = [String?](count: regex.numberOfCaptureGroups, repeatedValue: nil)
  	for i in 0..<regex.numberOfCaptureGroups {
      if let range = match?.rangeAtIndex(i) {
        if range.location != NSNotFound { captures[i] = (self as NSString).substringWithRange(range) }
      }
  	}

    return captures
  }

}

// pattern matching operator
func ~=(lhs: NSRegularExpression, rhs: String) -> Bool {
  return lhs.numberOfMatchesInString(rhs,
                             options: nil,
                               range: NSRange(location: 0,  length: (rhs as NSString).length)) > 0
}
func ~=(lhs: String, rhs: NSRegularExpression) -> Bool { return rhs ~= lhs }

func *(lhs: String, var rhs: Int) -> String { var s = ""; while rhs-- > 0 { s += lhs }; return s }

prefix operator ~/ {}

prefix func ~/(pattern: String) -> NSRegularExpression! {
  var error: NSError? = nil
  let regex = NSRegularExpression(pattern: pattern, options: nil, error: &error)
  if error != nil { printError(error!, message: "failed to create regular expression object") }
  return regex
}

infix operator +⁈ { associativity left precedence 140 }

func +⁈(lhs:String, rhs:String?) -> String? { if let r = rhs { return lhs + r } else { return nil } }
func +⁈(lhs:String, rhs:String) -> String? { return lhs + rhs }
func +⁈(lhs:String?, rhs:String?) -> String? { if let l = lhs { if let r = rhs { return l + r } }; return nil }
