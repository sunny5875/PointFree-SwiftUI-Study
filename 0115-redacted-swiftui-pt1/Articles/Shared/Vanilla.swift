import SwiftUI

class AppViewModel: ObservableObject {
  @Published var articles: [Article] = []
  @Published var isLoading = false
  @Published var readingArticle: Article?

  init() {
    self.isLoading = true

      // 네트워크를 모방하기 위해 4초후에 주는 걸로 설정
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
      self.articles = liveArticles
      self.isLoading = false
    }
  }

  func tapped(article: Article) {
    self.readingArticle = article
  }
}

// redaction reason 추가
extension RedactionReasons {
  static let loading = RedactionReasons(rawValue: 1)
}

struct VanillaArticlesView: View {
  @ObservedObject private var viewModel = AppViewModel()

  var body: some View {
    NavigationView {
      List {
        if self.viewModel.isLoading {
          ActivityIndicator()
            .frame(maxWidth: .infinity)
            .padding()
        }

        ForEach(
          self.viewModel.isLoading
            ? placeholderArticles
            : self.viewModel.articles.filter { !$0.isHidden }
        ) { article in
          Button(
            action: {
              guard !self.viewModel.isLoading else { return } // 2-3. article을 눌렀을 때 detail view가 보이지 않도록 막아주는 역할해줌
              self.viewModel.tapped(article: article)
            }
          ) {
            ArticleRowView(article: article)
          }
        }
        .redacted(reason: self.viewModel.isLoading ? .placeholder : []) // 1. 이걸로 로딩하도록 보여줌
        .disabled(self.viewModel.isLoading) //2. falseArcticle에는 눌리면 안되니까 뷰를 다 disabled해야 함
      }
      .sheet(item: self.$viewModel.readingArticle) { article in
        NavigationView {
          ArticleDetailView(article: article)
            .navigationTitle(article.title)
        }
      }
      .navigationTitle("Articles")
    }
  }
}

class ArticleViewModel: ObservableObject {
  @Published var article: Article

  init(article: Article) {
    self.article = article
  }

  func favorite() {
    // Make API request to favorite article on server
    self.article.isFavorite.toggle()
  }

  func readLater() {
    // Make API request to add article to read later list
    self.article.willReadLater.toggle()
  }

  func hide() {
    // Make API request to hide article so we never see it again
    self.article.isHidden.toggle()
  }
}

private struct ArticleRowView: View {
  @StateObject var viewModel: ArticleViewModel
    // 2-1. disable하기 위해 추가한 변수, environment에서 redactionReasons property를 가져와서 바인딩하는 의미
  @Environment(\.redactionReasons) var redactionReasons

  @State var value = 1

  init(article: Article) {
    self._viewModel = StateObject(wrappedValue: ArticleViewModel(article: article))
  }

  var body: some View {
    HStack(alignment: .top) {
      Image("")
        .frame(width: 80, height: 80)
        .background(Color.init(white: 0.9))
        .padding([.trailing])

      VStack(alignment: .leading) {
        Text(self.viewModel.article.title)
          .font(.title)

        Text(articleDateFormatter.string(from: self.viewModel.article.date))
          .bold()

        Text(self.viewModel.article.blurb)
          .padding(.top, 6)

        HStack {
          Spacer()

          Button(
            action: {
              guard self.redactionReasons.isEmpty else { return } // 2-2
              self.viewModel.favorite()
            }) {
            Image(systemName: "star.fill")
          }
          .buttonStyle(PlainButtonStyle())
          .foregroundColor(self.viewModel.article.isFavorite ? .red : .blue)
          .padding()

          Button(
            action: {
              guard self.redactionReasons.isEmpty else { return } // 2-2
              self.viewModel.readLater()
            }) {
            Image(systemName: "book.fill")
          }
          .buttonStyle(PlainButtonStyle())
          .foregroundColor(self.viewModel.article.willReadLater ? .yellow : .blue)
          .padding()

          Button(
            action: {
              guard self.redactionReasons.isEmpty else { return } // 2-2
              self.viewModel.hide()
            }) {
            Image(systemName: "eye.slash.fill")
          }
          .buttonStyle(PlainButtonStyle())
          .foregroundColor(.blue)
          .padding()
        }
      }
    }
    .padding([.top, .bottom])
    .buttonStyle(PlainButtonStyle())
  }
}

fileprivate struct ArticleDetailView: View {
  let article: Article

  var body: some View {
    Text(article.blurb)
  }
}
struct Vanilla_Previews: PreviewProvider {
  static var previews: some View {
    VanillaArticlesView()
  }
}
