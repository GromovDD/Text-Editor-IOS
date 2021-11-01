//
//  TextDocument.swift
//  TextDocument
//
//  Created by Serega on 16.10.2021.
//
import SwiftUI
import UniformTypeIdentifiers
public struct TextDocument: FileDocument {
    public static var readableContentTypes = [UTType.plainText]
    public var text : String
    init(initialText: String = "") {
        text = initialText
    }
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf16)!
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf16)!
        return FileWrapper(regularFileWithContents: data)
    }
}
