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
    public var textEncoding : String.Encoding = .utf16
    public static var readableContentTypes = [UTType.plainText]
    public var text = ""
    public init() {}
    public func getFileWrapper() throws -> FileWrapper
    {
        return FileWrapper(regularFileWithContents: text.data(using: textEncoding)!)
    }
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            let soucreData = data
            let isNull = soucreData.count == 2
            if(!isNull) {
                textEncoding = soucreData.stringEncoding!
                text = String(data: soucreData, encoding: textEncoding)!
            }
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try! getFileWrapper()
    }
}
