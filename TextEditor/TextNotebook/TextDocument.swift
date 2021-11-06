//
//  TextDocument.swift
//  TextDocument
//
//  Created by Serega on 16.10.2021.
//
import SwiftUI
import Foundation
import UniformTypeIdentifiers
extension Data {
    var stringEncoding: String.Encoding? {
        var nsString: NSString?
        guard case let rawValue = NSString.stringEncoding(for: self, encodingOptions: nil, convertedString: &nsString, usedLossyConversion: nil), rawValue != 0 else { return nil }
        return .init(rawValue: rawValue)
    }
}
public struct TextDocument: FileDocument {
    public let textEncoding : String.Encoding
    public let defaultEncoding : String.Encoding = .utf16
    public static var readableContentTypes = [UTType.plainText]
    public var text : String
    init(initialText: String = "") {
        text = initialText
        textEncoding = defaultEncoding
    }
    public func save() throws -> FileWrapper
    {
        let data = text.data(using: textEncoding)!
        return FileWrapper(regularFileWithContents: data)
    }
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            let soucreData = data
            textEncoding = soucreData.stringEncoding!
             text = String(data: soucreData, encoding: textEncoding)!
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try! save()
    }
}
