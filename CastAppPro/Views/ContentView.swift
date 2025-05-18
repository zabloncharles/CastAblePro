import SwiftUI
import WebKit
import UIKit // For haptic feedback

// MARK: - StartPageView
struct StartPageView: View {
    @AppStorage("darkMode") var darkMode: Bool = false
    @StateObject private var movieService = MovieService()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedMovie: Movie?
    @FocusState private var searchFocused: Bool
    let userName = "Zablon"
    let accentBlue = Color(red: 0.18, green: 0.38, blue: 0.95)
    let bgColor = Color(.white)
    @ObservedObject var watchlistManager: WatchlistManager
    
    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        // Greeting, Notification, and Search
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Good morning, \(userName)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Ready to stream?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            ZStack(alignment: .topTrailing) {
                                Button(action: {}) {
                                    Image(systemName: "bell")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(accentBlue)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                }
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                    .overlay(Text("3").font(.caption2).foregroundColor(.white))
                                    .offset(x: 8, y: -8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search...", text: $searchText)
                                .focused($searchFocused)
                                .foregroundColor(.primary)
                                .onChange(of: searchText) { newValue in
                                    Task { await movieService.searchMovies(query: newValue) }
                                }
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        // Quick Actions
                        HStack(spacing: 24) {
                            QuickActionButton(icon: "flame.fill", label: "Popular", color: accentBlue)
                            QuickActionButton(icon: "star.fill", label: "Top Rated", color: .yellow)
                            QuickActionButton(icon: "film", label: "Genres", color: .purple)
                            QuickActionButton(icon: "heart.fill", label: "My List", color: .pink)
                        }
                        .padding(.horizontal)
                        .padding(.top, 18)
                        // Promo Card
                        PromoCard(accentBlue: accentBlue)
                            .padding(.horizontal)
                            .padding(.top, 18)
                        // Trending Section (rest of your content follows...)
                        SectionHeader(title: "Trending", accent: accentBlue)
                       
                            HorizontalBookCarousel(
                                movies: Array(movieService.popularMovies.prefix(8)),
                                accentBlue: accentBlue,
                                watchlistManager: watchlistManager,
                                movieService: movieService
                            )
                        
                        // Continue Watching
                        if let movie = movieService.popularMovies.first {
                            Text("Continue Watching")
                                .font(.title3).bold()
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 12)
                            ContinueWatchingCard(movie: movie, accentBlue: accentBlue, watchlistManager: watchlistManager)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        }
                        // New Arrival
                        SectionHeader(title: "New Arrival", accent: accentBlue)
                        HorizontalBookCarousel(
                            movies: Array(movieService.trendingMovies.prefix(8)),
                            accentBlue: accentBlue,
                            watchlistManager: watchlistManager,
                            movieService: movieService
                        )
                        Spacer(minLength: 60)
                    }
                   
                    .task {
                        await movieService.fetchMovies()
                    }
                }
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let accent: Color
    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
                .foregroundColor(.primary)
            Spacer()
            Button(action: {}) {
                Text("See All")
                    .font(.subheadline)
                    .foregroundColor(accent)
            }
        }
        .padding(.horizontal)
        .padding(.top, 18)
        .padding(.bottom, 15)
    }
}

// MARK: - Horizontal Book Carousel
struct HorizontalBookCarousel: View {
    let movies: [Movie]
    let accentBlue: Color
    @ObservedObject var watchlistManager: WatchlistManager
    let movieService: MovieService
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(movies) { movie in
                    NavigationLink(
                        destination: MovieDetailSheet(movie: movie, watchlistManager: watchlistManager, movieService: movieService)
                    ) {
                        BookStyleMovieCard(movie: movie, accentBlue: accentBlue, watchlistManager: watchlistManager)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - WatchlistMovie
struct WatchlistMovie: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String
}

// MARK: - WatchlistManager
class WatchlistManager: ObservableObject {
    @Published private(set) var watchlist: [WatchlistMovie] = []
    private let key = "watchlist"
    init() { load() }
    func add(_ movie: WatchlistMovie) {
        if !watchlist.contains(where: { $0.id == movie.id }) {
            watchlist.append(movie)
            save()
        }
    }
    func remove(_ id: Int) {
        watchlist.removeAll { $0.id == id }
        save()
    }
    func toggle(_ movie: WatchlistMovie) {
        if watchlist.contains(where: { $0.id == movie.id }) {
            remove(movie.id)
        } else {
            add(movie)
        }
    }
    func isInWatchlist(_ id: Int) -> Bool {
        watchlist.contains(where: { $0.id == id })
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([WatchlistMovie].self, from: data) {
            watchlist = items
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Book Style Movie Card
struct BookStyleMovieCard: View {
    let movie: Movie
    let accentBlue: Color
    @ObservedObject var watchlistManager: WatchlistManager
    var isInWatchlist: Bool { watchlistManager.isInWatchlist(movie.id) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let url = movie.posterURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 130, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: accentBlue.opacity(0.10), radius: 8, x: 0, y: 4)
                }
                Button(action: {
                    let entry = WatchlistMovie(id: movie.id, title: movie.title, description: movie.overview)
                    watchlistManager.toggle(entry)
                }) {
                    Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isInWatchlist ? .accentColor : .gray)
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            Text(movie.title)
                .font(.subheadline).bold()
                .foregroundColor(.primary)
                .lineLimit(1)
            Text("\(movie.year)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 130)
    }
}

// MARK: - Continue Watching Card
struct ContinueWatchingCard: View {
    let movie: Movie
    let accentBlue: Color
    @ObservedObject var watchlistManager: WatchlistManager
    var isInWatchlist: Bool { watchlistManager.isInWatchlist(movie.id) }
    var body: some View {
        Button(action: { }) {
            HStack(alignment: .top, spacing: 16) {
                if let url = movie.posterURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 80, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(movie.overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                    ProgressView(value: 0.7)
                        .accentColor(accentBlue)
                        .frame(width: 120)
                    Button(action: { }) {
                        Text("Continue watching")
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(accentBlue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 2)
                }
                Spacer()
                Button(action: {
                    let entry = WatchlistMovie(id: movie.id, title: movie.title, description: movie.overview)
                    watchlistManager.toggle(entry)
                }) {
                    Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isInWatchlist ? .accentColor : .gray)
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.top,10)
        }
    }
}

// MARK: - Hulu Hero Banner
struct HuluHeroBanner: View {
    let movie: Movie?
    let huluGreen: Color
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let movie = movie, let url = movie.backdropURL ?? movie.posterURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .clipped()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                )
            }
            VStack(alignment: .leading, spacing: 14) {
                if let movie = movie {
                    Text(movie.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                    HStack(spacing: 10) {
                        InfoChip(text: movie.year, color: huluGreen)
                        InfoChip(text: String(format: "%.1f ★", movie.voteAverage), color: huluGreen)
                        InfoChip(text: "Action", color: huluGreen)
                    }
                    .padding(.bottom, 2)
                    Text(movie.overview)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .shadow(radius: 4)
                    Button(action: {}) {
                        Text("Watch Now")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(huluGreen)
                            .clipShape(Capsule())
                            .shadow(radius: 8)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(32)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 12)
    }
}

// MARK: - Hulu Section Header
struct HuluSectionHeader: View {
    let title: String
    let huluGreen: Color
    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
                .foregroundColor(.white)
            Spacer()
            Button(action: {}) {
                Text("See All")
                    .font(.subheadline)
                    .foregroundColor(huluGreen)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

// MARK: - Hulu Horizontal Carousel
struct HuluHorizontalCarousel: View {
    let movies: [Movie]
    let huluGreen: Color
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(movies) { movie in
                    HuluMovieCard(movie: movie, huluGreen: huluGreen)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Hulu Movie Card
struct HuluMovieCard: View {
    let movie: Movie
    let huluGreen: Color
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    if let url = movie.posterURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 140, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(huluGreen, lineWidth: 2)
                                .opacity(0.18)
                        )
                        .shadow(color: huluGreen.opacity(0.12), radius: 8, x: 0, y: 4)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(huluGreen)
                            .font(.caption2)
                        Text(String(format: "%.1f", movie.voteAverage))
                            .foregroundColor(.white)
                            .font(.caption2)
                    }
                    .padding(8)
                }
                Text(movie.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Info Chip (Hulu Style)
struct InfoChip: View {
    var text: String
    var color: Color = Color.white.opacity(0.18)
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(12)
    }
}

// MARK: - Hulu Bottom Nav Bar
struct HuluBottomNavBar: View {
    let huluGreen: Color
    var body: some View {
        HStack(spacing: 48) {
            Button(action: {}) {
                Image(systemName: "house.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(huluGreen)
            }
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Button(action: {}) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 36)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule().stroke(huluGreen.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: huluGreen.opacity(0.18), radius: 18, x: 0, y: 8)
        .padding(.bottom, 18)
    }
}

// MARK: - Hero Section
struct HeroSectionView: View {
    let movie: Movie?
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let movie = movie, let url = movie.backdropURL ?? movie.posterURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .clipped()
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                )
            }
            VStack(alignment: .leading, spacing: 14) {
                if let movie = movie {
                    Text(movie.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                    HStack(spacing: 10) {
                        InfoChip(text: movie.year)
                        InfoChip(text: String(format: "%.1f ★", movie.voteAverage))
                        InfoChip(text: "Action")
                    }
                    .padding(.bottom, 2)
                    Text(movie.overview)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .shadow(radius: 4)
                    Button(action: {}) {
                        Text("Watch Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(BlurView(style: .systemUltraThinMaterialDark))
                            .clipShape(Capsule())
                            .shadow(radius: 8)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(32)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 12)
    }
}

// MARK: - Continue Watching Row
struct ContinueWatchingRow: View {
    let movies: [Movie]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continue Watching")
                .font(.title3).bold()
                .foregroundColor(.white)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(movies) { movie in
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottomTrailing) {
                                Button(action: {}) {
                                    if let url = movie.posterURL {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 110, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                }
                                // Circular progress (fake for demo)
                                Circle()
                                    .trim(from: 0, to: 0.4)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))
                                    .offset(x: -8, y: -8)
                            }
                            Text(movie.title)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - For You Carousel
struct ForYouCarousel: View {
    let movies: [Movie]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("For You")
                .font(.title3).bold()
                .foregroundColor(.white)
                .padding(.horizontal)
            TabView(selection: .constant(0)) {
                ForEach(Array(movies.enumerated()), id: \ .offset) { idx, movie in
                    Button(action: {}) {
                        ZStack(alignment: .bottomLeading) {
                            if let url = movie.backdropURL ?? movie.posterURL {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(radius: 12)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(movie.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .shadow(radius: 4)
                                Button(action: {}) {
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.7))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(16)
                        }
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 220)
        }
    }
}

// MARK: - Glassmorphism BlurView
import UIKit
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Bottom Nav Bar
struct BottomNavBar: View {
    var body: some View {
        HStack(spacing: 48) {
            Button(action: {}) {
                Image(systemName: "house.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Button(action: {}) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 36)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .clipShape(Capsule())
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 8)
        .padding(.bottom, 18)
    }
}

// MARK: - Supporting Views
struct AnimatedPlayButton: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.pink.opacity(animate ? 0.4 : 0.2))
                .frame(width: 90, height: 90)
                .scaleEffect(animate ? 1.2 : 1)
                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
            Circle()
                .fill(Color.pink)
                .frame(width: 70, height: 70)
            Image(systemName: "play.fill")
                .foregroundColor(.white)
                .font(.system(size: 32, weight: .bold))
        }
        .onAppear { animate = true }
        .shadow(radius: 10)
    }
}

struct FeaturedMovieCard: View {
    let movie: Movie
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let posterURL = movie.posterURL {
                AsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(height: 220)
                .clipped()
                .cornerRadius(20)
            }
            
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.01), Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                .cornerRadius(20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.title2).bold()
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", movie.voteAverage))
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    Text("Released: \(movie.year)")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Button(action: {}) {
                        Text("Watch")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .frame(height: 220)
    }
}

struct MovieThumbCard: View {
    let movie: Movie
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    if let posterURL = movie.posterURL {
                        AsyncImage(url: posterURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 140, height: 180)
                        .clipped()
                        .cornerRadius(16)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                            Text(String(format: "%.1f", movie.voteAverage))
                                .foregroundColor(.white)
                                .font(.caption2)
                        }
                    }
                    .padding(8)
                }
                Text(movie.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
}

struct MovieDetailSheet: View {
    let movie: Movie
    let accentYellow = Color.yellow
    let accentRed = Color.red
    let accentBlue = Color(red: 0.18, green: 0.38, blue: 0.95)
    @State private var showFullStory = false
    @State private var isFavorite = false
    @ObservedObject var watchlistManager: WatchlistManager
    var isInWatchlist: Bool { watchlistManager.isInWatchlist(movie.id) }
    @State private var trailerURL: URL? = nil
    @State private var showTrailerSection = false
    @State private var isLoadingTrailer = false
    @State private var trailerError: String? = nil
    let movieService: MovieService
    // Mock cast data
    let cast: [CastMember] = [
        .init(name: "Hirokazu Kor.", role: "Director", image: "person.crop.circle"),
        .init(name: "Lily Franky", role: "Osamu Shibata", image: "person.crop.circle.fill"),
        .init(name: "Sakura Andô", role: "Nobuyo Shibata", image: "person.circle"),
        .init(name: "Mayu Matsu.", role: "Aki Shibata", image: "person.circle.fill"),
        .init(name: "Jyo Kairi", role: "Shota Shibata", image: "person.crop.square")
    ]
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                ZStack(alignment: .top) {
                    if let backdropURL = movie.backdropURL ?? movie.posterURL {
                        AsyncImage(url: backdropURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(height: 220)
                        .clipped()
                        .overlay(
                            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.55),Color.white]), startPoint: .top, endPoint: .bottom)
                        )
                    }
                 
                }
                .frame(height: 220)
                // Movie Info Card
                HStack(alignment: .top, spacing: 16) {
                    if let posterURL = movie.posterURL {
                        AsyncImage(url: posterURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 80, height: 110)
                        .cornerRadius(12)
                        .shadow(color: accentBlue.opacity(0.10), radius: 8, x: 0, y: 4)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(.headline).bold()
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        Text("2h 1min | Crime, Drama")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < Int(movie.voteAverage/2) ? "star.fill" : "star")
                                    .foregroundColor(accentYellow)
                                    .font(.caption)
                            }
                            Text(String(format: "%.1f", movie.voteAverage))
                                .font(.caption).bold()
                                .foregroundColor(.primary)
                        }
                        Button(action: { isFavorite.toggle() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? accentRed : .gray)
                                .font(.title2)
                        }
                        Button(action: {
                            let entry = WatchlistMovie(id: movie.id, title: movie.title, description: movie.overview)
                            watchlistManager.toggle(entry)
                        }) {
                            Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isInWatchlist ? .accentColor : .gray)
                                .font(.title2)
                        }
                        // Watch Trailer Button
                        Button(action: {
                            Task {
                                isLoadingTrailer = true
                                trailerError = nil
                                do {
                                    if let key = try await movieService.fetchMovieTrailer(movieId: movie.id) {
                                        trailerURL = URL(string: "https://www.youtube.com/watch?v=\(key)")
                                        showTrailerSection = true
                                    } else {
                                        trailerError = "No trailer found."
                                    }
                                } catch {
                                    trailerError = "Failed to load trailer."
                                }
                                isLoadingTrailer = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Watch Trailer")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(accentBlue)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                        .disabled(isLoadingTrailer)
                        if isLoadingTrailer {
                            ProgressView().padding(.top, 4)
                        }
                        if let trailerError = trailerError {
                            Text(trailerError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    Spacer()
                 
                }
                .padding(.horizontal)
                .padding(.top, -32)
                .padding(.bottom, 8)
                // Trailer Section (inserted before Details)
                if showTrailerSection, let trailerURL = trailerURL, let videoKey = trailerURL.query?.split(separator: "=").last.map(String.init) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trailer")
                            .font(.headline).bold()
                            .foregroundColor(.primary)
                        YouTubePlayerView(videoKey: videoKey)
                            .frame(height: 220)
                            .cornerRadius(12)
                            .padding(.vertical, 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                // Details Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline).bold()
                        .foregroundColor(.primary)
                    HStack(spacing: 18) {
                        InfoCard(icon: "calendar", label: "Year", title: movie.year)
                        InfoCard(icon: "clock", label: "Release Date", title: movie.releaseDate)
                        InfoCard(icon: "number", label: "TMDB ID", title: String(movie.id))
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                // Storyline
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storyline")
                        .font(.headline).bold()
                        .foregroundColor(.primary)
                    Text(movie.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(showFullStory ? nil : 2)
                    if !showFullStory {
                        Button(action: { showFullStory = true }) {
                            Text("Read More")
                                .font(.caption).bold()
                                .foregroundColor(accentBlue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                // Cast Carousel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cast")
                            .font(.headline).bold()
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {}) {
                            Text("See all")
                                .font(.caption).bold()
                                .foregroundColor(accentBlue)
                        }
                    }
                    .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(cast) { member in
                                VStack(spacing: 6) {
                                    Image(systemName: member.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 54, height: 54)
                                        .clipShape(Circle())
                                        .background(Circle().fill(Color(.systemGray6)))
                                    Text(member.name)
                                        .font(.caption).bold()
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Text(member.role)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 70)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 18)
                Spacer()
            }
            .background(Color("dynamic"))
        }.toolbarBackground(Color("dynamic"))
            .navigationBarTitle(movie.title)
        
    }
}

// MARK: - Cast Member Model
struct CastMember: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let image: String
}

// MARK: - Info Card
struct InfoCard: View {
    let icon: String
    let label: String
    let title: String
    var body: some View {
       
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(Color.purple)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(label)
                        .font(.subheadline).bold()
                    .foregroundColor(.primary)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        .padding(.horizontal,10)
        
        
    }
}

struct CarouselSection: View {
    let title: String
    let images: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2).bold()
                .foregroundColor(.white)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(images, id: \.self) { img in
                        Image(img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 170)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
}

struct ContentView: View {
    @AppStorage("darkMode") private var darkMode: Bool = false
    @AppStorage("homePage") private var homePage: String = "https://www.google.com"
    @AppStorage("autoDetectVideos") private var autoDetectVideos: Bool = true
    @AppStorage("lastVisitedURL") private var lastVisitedURL: String = "https://www.google.com"
    @State private var url: URL = URL(string: "https://www.google.com")!
    @State private var showCastModal = false
    @State private var videoURL: String?
    @State private var isCasting = false
    @StateObject private var rokuController = RokuController()
    @StateObject private var webViewModel = WebViewModel()
    @FocusState private var searchFocused: Bool
    @State private var showSettings = false
    @State private var clearWebViewDataTrigger = false
    @State private var startPageSearch = ""
    @AppStorage("selectedTab") private var selectedTab: Int = 0
    @StateObject private var watchlistManager = WatchlistManager()

    var body: some View {
        ZStack {
            (darkMode ? Color.black : Color.white).ignoresSafeArea(edges: .top)
            Group {
                if selectedTab == 0 {
                    StartPageView(watchlistManager: watchlistManager)
                } else if selectedTab == 1 {
                    WatchlistView(watchlistManager: watchlistManager)
                } else if selectedTab == 2 {
                    BrowserTabView(
                        url: $url,
                        showCastModal: $showCastModal,
                        videoURL: $videoURL,
                        isCasting: $isCasting,
                        rokuController: rokuController,
                        webViewModel: webViewModel,
                        darkMode: darkMode,
                        autoDetectVideos: autoDetectVideos,
                        clearWebViewDataTrigger: $clearWebViewDataTrigger,
                        searchFocused: _searchFocused,
                        homePage: $homePage,
                        lastVisitedURL: $lastVisitedURL
                    )
                } else if selectedTab == 3 {
                    SettingsView(
                        darkMode: $darkMode,
                        homePage: $homePage,
                        autoDetectVideos: $autoDetectVideos,
                        clearWebViewDataTrigger: $clearWebViewDataTrigger,
                        connectedDevice: $rokuController.connectedDevice,
                        disconnectDevice: { rokuController.connectedDevice = nil },
                        rokuController: rokuController
                    )
                }
            }
            // Floating Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, rokuController: rokuController)
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            url = URL(string: lastVisitedURL) ?? URL(string: homePage) ?? URL(string: "https://www.google.com")!
        }
    }
}

struct SettingsView: View {
    @Binding var darkMode: Bool
    @Binding var homePage: String
    @Binding var autoDetectVideos: Bool
    @Binding var clearWebViewDataTrigger: Bool
    @Binding var connectedDevice: RokuDevice?
    var disconnectDevice: () -> Void
    @State private var showClearAlert = false
    @State private var showResetAlert = false
    @State private var showCastDevices = false
    @State private var feedbackURL = URL(string: "mailto:support@castablepro.com")!
    @State private var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    // Demo user data
    let userName = "Arthur"
    let avatarImage = "person.crop.circle.fill"
    @ObservedObject var rokuController: RokuController
    
    var body: some View {
        ZStack {
            (darkMode ? Color.black : Color(.systemGroupedBackground)).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Card
                    ZStack {
                        (darkMode ? Color.black : Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 90, height: 90)
                                Image(systemName: avatarImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .foregroundColor(.brown)
                            }
                            Text(userName)
                                .font(.title).bold()
                                .foregroundColor(darkMode ? .white : .primary)
                            Text("You rock!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("You've finished last movie in 3 days 🔥")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 18)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 48)
                    .zIndex(2)
                    // Settings Form Card
                    ZStack {
                        (darkMode ? Color.black : Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        VStack(spacing: 0) {
                            // Use a VStack to mimic Form sections
                            Group {
                                // Appearance
                                HStack {
                                    Text("Dark Mode")
                                        .foregroundColor(darkMode ? .white : .primary)
                                    Spacer()
                                    Toggle("", isOn: $darkMode)
                                        .labelsHidden()
                                }
                                .padding()
                                Divider()
                                // Browser
                                VStack(alignment: .leading, spacing: 0) {
                                    TextField("Default Home Page", text: $homePage)
                                        .foregroundColor(darkMode ? .white : .primary)
                                        .padding(.vertical, 8)
                                    Toggle("Auto-Detect Videos", isOn: $autoDetectVideos)
                                        .foregroundColor(darkMode ? .white : .primary)
                                        .padding(.vertical, 8)
                                    Button(role: .destructive) {
                                        showClearAlert = true
                                    } label: {
                                        Text("Clear Browsing Data")
                                            .foregroundColor(.red)
                                    }
                                    .alert("Clear all browsing data?", isPresented: $showClearAlert) {
                                        Button("Clear", role: .destructive) {
                                            clearWebViewDataTrigger.toggle()
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    }
                                }
                                .padding(.horizontal)
                                Divider()
                                // Device
                                VStack(alignment: .leading, spacing: 0) {
                                    Button(action: { showCastDevices = true }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Connected Device")
                                                    .foregroundColor(darkMode ? .white : .primary)
                                                if let device = connectedDevice {
                                                    Text(device.name)
                                                        .font(.subheadline)
                                                        .foregroundColor(.blue)
                                                } else {
                                                    Text("No device connected")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding(.horizontal)
                                Divider()
                                // About
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text("Version")
                                            .foregroundColor(darkMode ? .white : .primary)
                                        Spacer()
                                        Text(appVersion)
                                            .foregroundColor(.secondary)
                                    }
                                    Link(destination: feedbackURL) {
                                        Label("Send Feedback", systemImage: "envelope")
                                    }
                                    Link(destination: URL(string: "https://github.com/zabloncharles/CastAblePro")!) {
                                        Label("GitHub Repo", systemImage: "link")
                                    }
                                }
                                .padding(.horizontal)
                                Divider()
                                // Reset
                                Button(role: .destructive) {
                                    showResetAlert = true
                                } label: {
                                    Text("Reset All Settings")
                                        .foregroundColor(.red)
                                }
                                .alert("Reset all settings?", isPresented: $showResetAlert) {
                                    Button("Reset", role: .destructive) {
                                        UserDefaults.standard.removeObject(forKey: "darkMode")
                                        UserDefaults.standard.removeObject(forKey: "homePage")
                                        UserDefaults.standard.removeObject(forKey: "autoDetectVideos")
                                        // Add more keys if you add more settings
                                        darkMode = false
                                        homePage = "https://www.google.com"
                                        autoDetectVideos = true
                                    }
                                    Button("Cancel", role: .cancel) {}
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, -24)
                    .zIndex(1)
                    Spacer()
                }
            }
            .toolbarBackground(darkMode ? Color.black : Color(.systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(darkMode ? Color.black : Color(.systemGroupedBackground), for: .automatic)
            .navigationTitle("Settings")
            .sheet(isPresented: $showCastDevices) {
                CastDevicesView(rokuController: rokuController)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            StartPageView(watchlistManager: WatchlistManager())
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Promo Card
struct PromoCard: View {
    let accentBlue: Color
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Get 1 Month Free Premium")
                    .font(.headline).bold()
                    .foregroundColor(.white)
                Text("Unlock all features and stream unlimited movies.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                Button(action: {}) {
                    Text("Claim Now")
                        .font(.subheadline).bold()
                        .foregroundColor(accentBlue)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            Spacer()
            Image(systemName: "film.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .foregroundColor(.white.opacity(0.8))
                .padding(.trailing, 8)
        }
        .padding(18)
        .background(
            LinearGradient(gradient: Gradient(colors: [accentBlue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(18)
        .shadow(color: accentBlue.opacity(0.10), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var showCastDevices = false
    @ObservedObject var rokuController: RokuController
    
    let tabIcons = [
        (icon: "square.grid.2x2.fill", tag: 0),
        (icon: "bookmark", tag: 1),
        (icon: "sparkles.tv", tag: 99),
        (icon: "magnifyingglass", tag: 2),
        (icon: "person", tag: 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabIcons, id: \ .tag) { tab in
                if tab.tag == 99 {
                    // Cast button
                    Button(action: { showCastDevices = true }) {
                        ZStack {
                            Image(systemName: "sparkles.tv")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(rokuController.connectedDevice != nil ? Color.green : (selectedTab == 99 ? Color.accentColor : Color("invert")))
                                .frame(maxWidth: .infinity)
                            if rokuController.connectedDevice != nil {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 14, y: -14)
                            }
                        }
                        .frame(height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = tab.tag
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(selectedTab == tab.tag ? Color.accentColor : Color("invert"))
                                .frame(maxWidth: .infinity)
                            if selectedTab == tab.tag {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .frame(width: 24, height: 3)
                                    .padding(.top, 2)
                                    .transition(.scale)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(width: 24, height: 3)
                                    .padding(.top, 2)
                            }
                        }
                        .frame(height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, safeAreaBottomInset() - 40)
        .background(
            Color("dynamic")
                .edgesIgnoringSafeArea(.bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
                .offset(y: -0.5), alignment: .top
        )
        .sheet(isPresented: $showCastDevices) {
            CastDevicesView(rokuController: rokuController)
        }
    }
    
    private func safeAreaBottomInset() -> CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Cast Devices View
struct CastDevicesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var rokuController: RokuController
    @State private var isSearching = false
    @State private var searchRotation: Double = 0
    @State private var showManualAdd = false
    @State private var manualIP = ""
    @State private var manualError: String? = nil
    @State private var isConnecting = false
    
    var body: some View {
        NavigationView {
            List {
                if let connectedDevice = rokuController.connectedDevice {
                    Section("Connected Device") {
                        HStack {
                            Image(systemName: "tv.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(connectedDevice.name)
                                    .font(.headline)
                                Text(connectedDevice.ipAddress)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    rokuController.connectedDevice = nil
                                }
                            }) {
                                Text("Disconnect")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section {
                    if isSearching {
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "tv.and.radiowaves.left.and.right")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .rotationEffect(.degrees(searchRotation))
                                    .onAppear {
                                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                            searchRotation = 360
                                        }
                                    }
                                Text("Searching for devices...")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .scale))
                    } else if rokuController.discoveredDevices.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tv.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No devices found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Make sure your Roku device is turned on and connected to the same network")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button(action: {
                                withAnimation(.spring()) {
                                    isSearching = true
                                }
                                Task {
                                    await rokuController.discoverDevices()
                                    withAnimation(.spring()) {
                                        isSearching = false
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search for Devices")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                            Button(action: { showManualAdd = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Device Manually")
                                }
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        ForEach(rokuController.discoveredDevices) { device in
                            Button(action: {
                                withAnimation(.spring()) {
                                    rokuController.connectedDevice = device
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "tv")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(device.ipAddress)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if rokuController.connectedDevice?.id == device.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        Button(action: { showManualAdd = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Device Manually")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                } header: {
                    HStack {
                        Text("Available Devices")
                        Spacer()
                        if !rokuController.discoveredDevices.isEmpty {
                            Button(action: {
                                withAnimation(.spring()) {
                                    isSearching = true
                                }
                                Task {
                                    await rokuController.discoverDevices()
                                    withAnimation(.spring()) {
                                        isSearching = false
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                    .rotationEffect(.degrees(isSearching ? 360 : 0))
                                    .animation(isSearching ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSearching)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cast to Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showManualAdd) {
                NavigationView {
                    VStack(spacing: 18) {
                        Text("Enter Roku Device IP Address")
                            .font(.headline)
                        TextField("e.g. 192.168.1.160", text: $manualIP)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        if let error = manualError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        Button(action: {
                            manualError = nil
                            isConnecting = true
                            validateAndAddManualDevice(ip: manualIP)
                        }) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.horizontal)
                            } else {
                                Text("Connect")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isConnecting || manualIP.isEmpty)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Manual Add")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showManualAdd = false
                                manualError = nil
                                manualIP = ""
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func validateAndAddManualDevice(ip: String) {
        guard !ip.isEmpty else {
            manualError = "Please enter an IP address."
            isConnecting = false
            return
        }
        let urlString = "http://\(ip):8060/query/device-info"
        guard let url = URL(string: urlString) else {
            manualError = "Invalid IP address."
            isConnecting = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isConnecting = false
                if let error = error {
                    manualError = "Could not connect: \(error.localizedDescription)"
                    return
                }
                guard let data = data, let xml = String(data: data, encoding: .utf8), xml.contains("<device-info>") else {
                    manualError = "Not a Roku device or invalid response."
                    return
                }
                // Extract device name from XML (simple parse)
                let name = xml.components(separatedBy: "<user-device-name>").dropFirst().first?.components(separatedBy: "</user-device-name>").first ?? "Manual Roku"
                let device = RokuDevice(id: UUID().uuidString, name: name, ipAddress: ip)
                if !rokuController.discoveredDevices.contains(where: { $0.ipAddress == device.ipAddress }) {
                    rokuController.discoveredDevices.append(device)
                }
                rokuController.connectedDevice = device
                showManualAdd = false
                manualError = nil
                manualIP = ""
                dismiss()
            }
        }.resume()
    }
}

// MARK: - BrowserTabView
struct BrowserTabView: View {
    @Binding var url: URL
    @Binding var showCastModal: Bool
    @Binding var videoURL: String?
    @Binding var isCasting: Bool
    @ObservedObject var rokuController: RokuController
    @ObservedObject var webViewModel: WebViewModel
    var darkMode: Bool
    var autoDetectVideos: Bool
    @Binding var clearWebViewDataTrigger: Bool
    @FocusState var searchFocused: Bool
    @Binding var homePage: String
    @Binding var lastVisitedURL: String

    var body: some View {
        ZStack {
            (darkMode ? Color.black : Color.white).ignoresSafeArea(edges: .top)
            WebView(
                url: $url,
                showCastModal: $showCastModal,
                videoURL: $videoURL,
                viewModel: webViewModel,
                darkMode: darkMode,
                autoDetectVideos: autoDetectVideos,
                clearWebViewDataTrigger: $clearWebViewDataTrigger
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    searchBar
                }
            }
            // Cast Modal
            if showCastModal {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showCastModal = false
                    }
                CastModalView(isPresented: $showCastModal, videoURL: $videoURL, rokuController: rokuController)
                    .transition(.move(edge: .bottom))
            }
            // Remote Control
            if isCasting {
                VStack {
                    Spacer()
                    RemoteControlView(rokuController: rokuController)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            url = URL(string: lastVisitedURL) ?? URL(string: homePage) ?? URL(string: "https://www.google.com")!
        }
        .onChange(of: homePage) { newValue in
            url = URL(string: newValue) ?? URL(string: "https://www.google.com")!
        }
        .onChange(of: videoURL) { newValue in
            if newValue != nil {
                showCastModal = true
            }
        }
        .onChange(of: rokuController.currentVideo) { video in
            isCasting = video != nil
        }
        .onChange(of: webViewModel.urlString) { newValue in
            if let newURL = URL(string: newValue), newURL != url {
                url = newURL
            }
        }
        .onChange(of: url) { newValue in
            lastVisitedURL = newValue.absoluteString
        }
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                webViewModel.goBack()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(webViewModel.canGoBack ? .blue : .gray)
            }
            TextField("Search or enter website name", text: $webViewModel.urlString, onCommit: {
                if let newURL = webViewModel.formatAndLoadURL(webViewModel.urlString) {
                    url = newURL
                    searchFocused = false
                }
            })
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .frame(minHeight: 36)
            .focused($searchFocused)

            if searchFocused {
                Button(action: {
                    if let newURL = webViewModel.formatAndLoadURL(webViewModel.urlString) {
                        url = newURL
                        searchFocused = false
                    }
                }) {
                    Text("Go")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .transition(.opacity)
            } else {
                Button(action: {
                    webViewModel.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                Button(action: {
                    UIPasteboard.general.string = webViewModel.urlString
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(darkMode ? Color.black : Color(.white))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
        .padding(.bottom,5)
        .animation(.easeInOut(duration: 0.18), value: searchFocused)
    }
}

struct WatchlistView: View {
    @ObservedObject var watchlistManager: WatchlistManager
    var body: some View {
        ZStack {
            Color("dynamic").ignoresSafeArea()
            if watchlistManager.watchlist.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.accentColor)
                    Text("Your Watchlist is Empty")
                        .font(.title2).bold()
                        .foregroundColor(.primary)
                    Text("Add movies to your watchlist to see them here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("My Watchlist")
                            .font(.largeTitle).bold()
                            .padding(.horizontal)
                            .padding(.top, 18)
                        ForEach(watchlistManager.watchlist) { movie in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(movie.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(movie.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    watchlistManager.remove(movie.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// Add this struct at the bottom of the file
struct YouTubePlayerView: UIViewRepresentable {
    let videoKey: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let embedHTML = """
        <html><body style='margin:0;padding:0;'><iframe width='100%' height='560' src='https://www.youtube.com/embed/\(videoKey)?playsinline=1' frameborder='0' allow='autoplay; encrypted-media' allowfullscreen></iframe></body></html>
        """
        uiView.loadHTMLString(embedHTML, baseURL: nil)
    }
} 

