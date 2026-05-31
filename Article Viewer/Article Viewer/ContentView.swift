//
//  ContentView.swift
//  DocCKit-Test
//
//  Created by Morris Richman on 5/30/26.
//

import SwiftUI
import DocCKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var article: Article?
    @State private var navigator = DocumentationNavigator()
    @State private var isShowingImporter = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            if let article {
                DocCArticleView(
                    article: article,
                    navigator: navigator,
                    identifier: "doc://my-app/app-guide"
                )
                .toolbar {
                    Button {
                        isShowingImporter.toggle()
                    } label: {
                        Label("Open Article", systemImage: "folder")
                    }
                }
            } else if isLoading {
                ProgressView("Loading")
            } else {
                Button {
                    isShowingImporter.toggle()
                } label: {
                    Label("Open Article", systemImage: "folder")
                }
            }
        }
        .fileImporter(isPresented: $isShowingImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let success):
                Task {
                    isLoading = true
                    defer {
                        isLoading = false
                    }
                    
                    await fetchArticle(success)
                }
            case .failure(let failure):
                print(failure)
            }
        }
        .task {
            guard let index = ProcessInfo.processInfo.arguments.firstIndex(where: { $0.contains("--preview") }),
                  let url = ProcessInfo.processInfo.arguments[index...index+1].last.flatMap(URL.init(string:))
            else { return }
            
            isLoading = true
            defer {
                isLoading = false
            }
            
            await fetchArticle(url)
        }
    }
    
    func fetchArticle(_ url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            article = try JSONDecoder().decode(Article.self, from: data)
        } catch {
            print(error)
        }
    }
}

#Preview {
    ContentView()
}
