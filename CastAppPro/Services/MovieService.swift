import Foundation

class MovieService: ObservableObject {
    private let apiKey = "46cc3c921aeefbaea1471a222d074643"
    private let baseURL = "https://api.themoviedb.org/3"
    
    @Published var popularMovies: [Movie] = []
    @Published var trendingMovies: [Movie] = []
    @Published var searchResults: [Movie] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchMovies() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let trending = fetchMovies(endpoint: "/trending/movie/week")
            async let popular = fetchMovies(endpoint: "/movie/popular")
            let (trendingResult, popularResult) = try await (trending, popular)
            await MainActor.run {
                self.trendingMovies = trendingResult
                self.popularMovies = popularResult
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func fetchPopularMovies() async {
        do {
            _ = try await fetchMovies(endpoint: "/movie/popular")
        } catch {
            await MainActor.run { self.error = error }
        }
    }
    
    func fetchTrendingMovies() async {
        do {
            _ = try await fetchMovies(endpoint: "/trending/movie/week")
        } catch {
            await MainActor.run { self.error = error }
        }
    }
    
    func searchMovies(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run { self.searchResults = [] }
            return
        }
        
        isLoading = true
        error = nil
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let endpoint = "/search/movie?query=\(encodedQuery)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)&api_key=\(apiKey)") else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            
            await MainActor.run {
                self.searchResults = response.results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func fetchMovies(endpoint: String) async throws -> [Movie] {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(baseURL)\(endpoint)?api_key=\(apiKey)") else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            isLoading = false
            throw error!
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            
            await MainActor.run {
                if endpoint.contains("popular") {
                    self.popularMovies = response.results
                } else {
                    self.trendingMovies = response.results
                }
                self.isLoading = false
            }
            return response.results
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            throw error
        }
    }
} 