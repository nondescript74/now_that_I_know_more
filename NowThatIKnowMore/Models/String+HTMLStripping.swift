// String+HTMLStripping.swift
// Shared HTML -> plain text helper for the project
import Foundation
import UIKit

public extension String {
    /// Returns a plain string by parsing and stripping all HTML tags.
    var strippedHTML: String {
        guard let data = self.data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(data: data,
                                                   options: [
                                                    .documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue
                                                   ],
                                                   documentAttributes: nil) {
            return attributed.string
        }
        return self
    }
    
    /// Returns a sanitized string suitable for use as a filename.
    var sanitizedForFileName: String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    /// Cleans HTML by converting common tags to plain text with formatting.
    var cleanedHTML: String {
        var text = self.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<li>", with: "• ", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<ul>|</ul>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<b>(.*?)</b>", with: "**$1**", options: .regularExpression)
        text = text.replacingOccurrences(of: "<i>(.*?)</i>", with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.filter { !$0.isEmpty }.map { $0 + "\n" }.joined()
    }
}

/// Global helper function for cleaning HTML summaries
//public func cleanSummary(_ html: String) -> String {
//    return html.cleanedHTML
//}
