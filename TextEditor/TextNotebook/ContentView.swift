//
//  ContentView.swift
//  TextNotebook
//
//  Created by Serega on 16.10.2021.
//
import HighlightedTextEditor
import SwiftUI
extension String {
    func caseInsensitiveSplit(separator: String) -> [String] {
        if separator.isEmpty {
            return [self]
        }
        let pattern = NSRegularExpression.escapedPattern(for: separator)
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex.matches(in: self, options: [], range: NSRange(0..<self.utf16.count))
        let ranges = (0..<matches.count+1).map { (i: Int)->NSRange in
            let start = i == 0 ? 0 : matches[i-1].range.location + matches[i-1].range.length
            let end = i == matches.count ? self.utf16.count: matches[i].range.location
            return NSRange(location: start, length: end-start)
        }
        return ranges.map {String(self[Range($0, in: self)!])}
    }
}
struct ContentView: View {
    @State private var empty = NSObject()
    @Environment(\.undoManager) var undoManager
    @State private var oldText = ""
    @State private var choosedColor = Color.red
    @State private var currentHighlightColor = UIColor.red
    @State private var showColorChooseView = false
    @State private var isSearching = false
    @State private var foundedWordsCount = 0
    @State private var wordsCount = 0
    @State private var searchText = ""
    @FocusState private var searchBarFocus : Bool?
    @FocusState private var editorFocus : Bool
    @Binding var document: TextDocument
    private func getBottomText() -> String
    {
        var result = ""
        if(isSearching && foundedWordsCount > 0)
        {
            result = "Founded \(foundedWordsCount)\(foundedWordsCount == 1 ? " repeat" : " repeats")"
        }
        else {
            result = "Words count: \(wordsCount)"
        }
        return result
    }
    private func dissmisKeyboard()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    private func saveColor()
    {
        UserDefaults.standard.highlightColor = currentHighlightColor
    }
    private func dissmisSearch()
    {
        dissmisKeyboard()
        searchText = ""
        withAnimation(.default) {
            isSearching = false
        }
    }
    private func getSubStringInString(str: String, substr: String) -> Int {
        return str.caseInsensitiveSplit(separator: substr).count - 1
    }
    private func updateFoundedWordsCount()
    {
        foundedWordsCount = getSubStringInString(str: document.text, substr: searchText)
    }
    private func updateWordsCount() {
        let components = $document.text.wrappedValue.components(separatedBy: .whitespacesAndNewlines)
        wordsCount = components.filter { !$0.isEmpty }.count
    }
    private func getHighlightRules(pattern: String) -> [HighlightRule]
    {
        do{
            let regularExpression = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            return [HighlightRule(pattern: regularExpression, formattingRule: .init(key: .foregroundColor, value: currentHighlightColor))]
        } catch {
            return []
        }
    }
    var body: some View {
        VStack
        {
            if(isSearching) {
                HStack {
                    TextField("Search(beta)...", text: $searchText).focused($searchBarFocus, equals: true)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            self.isSearching = true
                            updateFoundedWordsCount()
                        }.overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 15)
                            }
                        ).onChange(of: searchText, perform: {_ in
                            updateFoundedWordsCount()
                        })
                    Button(action: {
                        dissmisSearch()
                    }) {
                        Text("Cancel")
                    }
                    .padding(.trailing, 10)
                }.transition(.move(edge: .top).combined(with: .opacity)).padding(.vertical, 5)
                
            }
            HighlightedTextEditor(text: $document.text, highlightRules: getHighlightRules(pattern: searchText)).onTextChange { text in
                undoManager?.registerUndo(withTarget: empty, handler:  { _ in
                    let oldText = text
                    document.text = oldText
                })
            }.focused($editorFocus).onTapGesture
            {
                dissmisKeyboard()
            }.onChange(of: document.text, perform: {_ in
                updateWordsCount()
                if(isSearching)
                {
                    updateFoundedWordsCount()
                }
            }).toolbar{
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    HStack {
                        ColorPicker("Select highlight color", selection: $choosedColor, supportsOpacity: false).onChange(of: choosedColor, perform: {
                            color in
                            currentHighlightColor = UIColor(color)
                            saveColor()
                        }).labelsHidden()
                        if(!isSearching) {
                            Button(action: {
                                withAnimation(.default) {
                                    isSearching = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        searchBarFocus = true
                                    }
                                }
                            }, label:
                                    {
                                Image(systemName: "magnifyingglass")
                            })
                        }
                    }.transition(.move(edge: .trailing).combined(with: .opacity))
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack
                    {
                        let canUndo = undoManager?.canUndo ?? false
                        let canRedo = undoManager?.canRedo ?? false
                        Button(action: {
                            if(canUndo){
                                undoManager?.undo()
                            }
                        }, label: { Image(systemName: "arrow.left.circle").foregroundColor(canUndo ? .blue : .gray)}).disabled(!canUndo)
                        Button(action: {
                            if(canRedo){
                                undoManager?.redo()
                            }
                        }, label: { Image(systemName: "arrow.forward.circle").foregroundColor(canRedo ? .blue : .gray)}).disabled(!canRedo)
                        Spacer()
                        Text(getBottomText())
                        Spacer()
                    }
                }
            }.onAppear{
                if(document.text.isEmpty) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        editorFocus = true
                    }
                } else{
                    updateWordsCount()
                }
                currentHighlightColor = UserDefaults.standard.highlightColor ?? .red
                choosedColor = Color(currentHighlightColor)
                oldText = document.text
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(TextDocument()))
    }
}




