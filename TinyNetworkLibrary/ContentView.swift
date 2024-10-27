//
//  ContentView.swift
//  TinyNetworkLibrary
//
//  Created by admin on 10/27/24.
//

import SwiftUI

// Sample data structure for episodes
struct Episode: Identifiable {
    let id: String
    let title: String
}

extension Episode {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String else { return nil }
        self.id = id
        self.title = title
    }
}

// JSON parsing resource
struct Resource<A> {
    let url: URL
    let parse: (Data) -> A?
}

extension Resource {
    init(url: URL, parseJSON: @escaping (Any) -> A?) {
        self.url = url
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            return json.flatMap(parseJSON)
        }
    }
}

// Resource to load all episodes
extension Episode {
    static var all: Resource<[Episode]> {
        let url = URL(string: "http://localhost:8000/episodes.json")! // Replace with your actual URL
        return Resource<[Episode]>(url: url, parseJSON: { json in
            guard let dictionaries = json as? [[String: Any]] else { return nil }
            return dictionaries.compactMap(Episode.init)
        })
    }
}

// Web service to load data
final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        URLSession.shared.dataTask(with: resource.url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data))
        }.resume()
    }
}

// View to display episodes
struct ContentView: View {
    @State private var episodes: [Episode] = []
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            List(episodes) { episode in
                Text(episode.title)
            }
            .navigationTitle("Episodes")
            .onAppear {
                loadEpisodes()
            }
            .overlay(
                isLoading ? ProgressView() : nil
            )
        }
    }

    private func loadEpisodes() {
        let webservice = Webservice()
        webservice.load(resource: Episode.all) { episodes in
            DispatchQueue.main.async {
                self.episodes = episodes ?? []
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
