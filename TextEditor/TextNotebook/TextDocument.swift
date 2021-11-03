//
//  TextDocument.swift
//  TextDocument
//
//  Created by Serega on 16.10.2021.
//
import SwiftUI
import UniformTypeIdentifiers
public struct TextDocument: FileDocument {
    public let encoding : String.Encoding = .utf16
    public static var readableContentTypes = [UTType.plainText]
    public var text : String
    init(initialText: String = "") {
        text = initialText
    }
    public func save() throws -> FileWrapper
    {
        let data = text.data(using: encoding)!
        return FileWrapper(regularFileWithContents: data)
    }
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: encoding)!
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try! save()
    }
}
