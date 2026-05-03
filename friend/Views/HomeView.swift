import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingCreatePost = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea() // Set black background matching image
                
                VStack {
                    // Timeline
                    List(viewModel.posts) { post in
                        PostCardView(post: post)
                            .listRowBackground(Color.black)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                    .refreshable {
                        if let user = authManager.currentUser {
                            viewModel.fetchPosts(for: user)
                        }
                    }
                }
                
                // FAB: Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingCreatePost = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue.opacity(0.7)) // 0.7 opacity as requested
                                .cornerRadius(16) // Slightly rounded square like the image
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("相方探し掲示板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePost = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(authManager)
            }
            .onAppear {
                if let user = authManager.currentUser {
                    viewModel.fetchPosts(for: user)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
