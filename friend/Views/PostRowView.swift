import SwiftUI

struct PostRowView: View {
    let post: Post
    var body: some View {
        PostCardView(post: post)
    }
}
