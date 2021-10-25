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
        //Thanks for Carpsen90. Please see comments below.
        if separator.isEmpty {
            return [self] //generates the same output as `.components(separatedBy: "")`
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
    @State private var currentSearchingWordIndex = 0
    @State private var isEditing = false
    @State private var foundedWordsCount = 0
    @State private var wordsCount = 0
    @State private var words : [String] = []
    @State private var searchText = ""
    @FocusState private var searchBarFocus : Bool?
    @FocusState private var editorFocus : Bool?
    @Binding var document: TextDocument
    private func dissmisKeyboard()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    private func dissmisSearch()
    {
        dissmisKeyboard()
        searchText = ""
        withAnimation(.default) {
            isEditing = false
        }
    }
    private func getSubStringInString(str: String, substr: String) -> Int {
        return str.caseInsensitiveSplit(separator: substr).count - 1
    }
    private func updateFoundedWordsCount()
    {
        foundedWordsCount = getSubStringInString(str: document.text, substr: searchText)
    }
    private func updateWords() {
        let components = $document.text.wrappedValue.components(separatedBy: .whitespacesAndNewlines)
        words = components.filter { !$0.isEmpty }
    }
    private func getHighlightRules(pattern: String) -> [HighlightRule]
    {
        do{
            let regularExpression = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            return [HighlightRule(pattern: regularExpression, formattingRule: .init(key: .foregroundColor, value: UIColor.red))]
        } catch {
            return []
        }
    }
    var body: some View {
        VStack
        {
            if(isEditing) {
                HStack {
                    TextField("Search(beta)...", text: $searchText).focused($searchBarFocus, equals: true)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            self.isEditing = true
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
                    
                }.transition(AnyTransition.move(edge: .top).combined(with: .opacity)).padding(.vertical, 5)
                
            }
            HighlightedTextEditor(text: $document.text, highlightRules: getHighlightRules(pattern: searchText)).focused($editorFocus, equals: true).onTapGesture{
                dissmisKeyboard() }.onChange(of: $document.text.wrappedValue
                                             , perform: { _ in updateWords()
                    wordsCount = words.count
                    if(isEditing)
                    {
                        updateFoundedWordsCount()
                    }
                }
                )
        }.toolbar{
            ToolbarItem(placement: .navigationBarTrailing)
            {
                if(!isEditing) {
                    Button(action: {
                        withAnimation(.default) {
                            isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                searchBarFocus = true
                            }
                        }
                    }, label:
                            {
                        Image(systemName: "magnifyingglass")
                    })
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if(isEditing && foundedWordsCount > 0)
                {
                    HStack
                    {
                        Spacer()
                        Text("Founded \(foundedWordsCount)\(foundedWordsCount == 1 ? " repeat" : " repeats")")
                        Spacer()
                    }
                }
                else if (wordsCount > 0) {
                    Text("Words count: " + String(wordsCount))
                }
            }
        }.onAppear{
            if(document.text == "") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    editorFocus = true
                }
            } else{
                updateWords()
                wordsCount = words.count
            }
        }
    }
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView(document: .constant(TextDocument()))
        }
    }
    
    
}

