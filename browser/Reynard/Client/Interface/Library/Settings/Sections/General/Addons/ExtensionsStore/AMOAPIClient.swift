//
//  AMOAddonListing.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import Foundation

/// A single add-on as returned by addons.mozilla.org's public API
/// (`/api/v5/addons/search/` and `/api/v5/addons/addon/{id|slug|guid}/`).
/// Fields matched against the official API docs
/// (addons-server.readthedocs.io/topics/api/addons.html), requesting
/// `lang=en-US` so translated fields (name/summary) come back as plain
/// strings instead of per-locale objects.
struct AMOAddonListing: Decodable {
    let id: Int
    let guid: String
    let slug: String
    let name: String?
    let summary: String?
    let iconURL: String?
    let weeklyDownloads: Int?
    let ratings: Ratings?
    let currentVersion: CurrentVersion?
    let authors: [Author]?
    
    struct Ratings: Decodable {
        let average: Double
        let count: Int
    }
    
    struct CurrentVersion: Decodable {
        let file: FileInfo
        
        struct FileInfo: Decodable {
            let url: String
        }
    }
    
    struct Author: Decodable {
        let name: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, guid, slug, name, summary, ratings, authors
        case iconURL = "icon_url"
        case weeklyDownloads = "weekly_downloads"
        case currentVersion = "current_version"
    }
    
    var authorsDisplayText: String? {
        guard let authors, !authors.isEmpty else {
            return nil
        }
        return authors.map { $0.name }.joined(separator: ", ")
    }
    
    var installURL: String? {
        currentVersion?.file.url
    }
}

private struct AMOSearchResponse: Decodable {
    let count: Int
    let results: [AMOAddonListing]
}

/// Thin client for the subset of the AMO API the extensions store needs.
/// Mirrors SearchCompletion's cancelable-URLSessionDataTask shape, since
/// this is the same kind of "search-as-you-type over the network" use
/// case and benefits from the same in-flight-request cancellation.
enum AMOAPIClient {
    private static let searchURL = "https://addons.mozilla.org/api/v5/addons/search/"
    private static let baseHeaders = ["User-Agent": "Reynard-iOS"]
    
    /// Empty/whitespace-only query browses AMO's own default ordering
    /// (recommended add-ons first, then most-used) rather than searching.
    static func search(
        query: String?,
        urlSession: URLSession = .shared,
        completion: @escaping (Result<[AMOAddonListing], Error>) -> Void
    ) -> URLSessionDataTask? {
        guard let url = requestURL(for: query) else {
            completion(.failure(URLError(.badURL)))
            return nil
        }
        
        var request = URLRequest(url: url)
        baseHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error as NSError?,
               error.domain == NSURLErrorDomain,
               error.code == NSURLErrorCancelled {
                return
            }
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(AMOSearchResponse.self, from: data)
                completion(.success(decoded.results))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }
    
    private static func requestURL(for query: String?) -> URL? {
        var components = URLComponents(string: searchURL)
        var queryItems = [
            URLQueryItem(name: "app", value: "firefox"),
            URLQueryItem(name: "type", value: "extension"),
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "page_size", value: "25"),
        ]
        
        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "sort", value: "recommended,users"))
        } else {
            queryItems.append(URLQueryItem(name: "q", value: trimmedQuery))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
}
