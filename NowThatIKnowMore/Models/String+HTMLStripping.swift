// String+HTMLStripping.swift
// Shared HTML -> plain text helper for the project
import Foundation
import UIKit

extension String {
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
}
