//
//  CastAppProApp.swift
//  CastAppPro
//
//  Created by Zablon Charles on 5/16/25.
//

import SwiftUI

@main
struct CastAppProApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Image("castablepro") // Use your asset name
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
        }
    }
}
