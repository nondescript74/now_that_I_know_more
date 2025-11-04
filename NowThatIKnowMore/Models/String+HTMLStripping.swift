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
}
