import ComposableArchitecture
import SwiftUI

// 1. domain modeling
struct ArticlesState: Equatable { // <- 여기서 struct, viewModel과 동일한 프로퍼티를 가짐
    var articles: [Article] = []
    var isLoading = false
    var readingArticle: Article?
}

// 2. action, application에서 일어날 수 있는 모든 액션들을 모음
enum ArticlesAction {
    case article(index: Int, action: ArticleAction)
    case articlesResponse([Article]?) // api response받고 나서의 액션
    case articleTapped(Article)
    case dismissArticle
    case onAppear
}
// child componentaction도 다있음
enum ArticleAction {
    case favoriteTapped
    case hideTapped
    case readLaterTapped
}

// 3. Reducer
let articlesReducer = Reducer<ArticlesState, ArticlesAction, Void> { state, action, environment in //environment에는 sideeffect와 관련된 것들이 나중에 들어갈거임
    switch action { // action마다 state를 바꾸면 됨
    case let .article(index: index, action: .favoriteTapped):
        state.articles[index].isFavorite.toggle()
        return .none
        
    case let .article(index: index, action: .hideTapped):
        //1-3. guard !state.isLoading else { return .none} 이렇게 매번 넣을 수는 있지만 안돼!!
         state.articles[index].isHidden.toggle()
        return .none
        
    case let .article(index: index, action: .readLaterTapped):
        state.articles[index].willReadLater.toggle()
        return .none
        
    case let .articlesResponse(articles):
        state.isLoading = false
        state.articles = articles ?? []
        return .none
        
    case let .articleTapped(article):
        state.readingArticle = article
        return .none
        
    case .dismissArticle:
        state.readingArticle = nil
        return .none
        
    case .onAppear:
        state.isLoading = true
//        state.articles = placeholderArticles // 1-2. redaction //1-5. 1-4로 인해 새로운 store을 주기 때문에 주석 처리함
        return Effect(value: .articlesResponse(liveArticles))
            .delay(for: 4, scheduler: DispatchQueue.main)
            .eraseToEffect()
    }
}

struct ComposableArticlesView: View {
    let store: Store<ArticlesState, ArticlesAction> // real brain이래 state가 바뀌면 다시 그려짐
    
    var body: some View {
        WithViewStore(self.store) { viewStore in // 이게 추가됨. state가 바뀌면 리랜더링됨
            NavigationView {
                List {
                    if viewStore.isLoading {
                        ActivityIndicator()
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    // 1-4. store 중에 일부만 전해주도록 변경
//                    ArticlesListView(store: self.store)
                    ArticlesListView(
                      store: viewStore.isLoading
                        ? Store(
                          initialState: .init(articles: placeholderArticles),
                          reducer: .empty, //아무런 effect이 없는 reducer 전달, fake logic과 real logic을
                          environment: ()
                        )
                        : self.store
                    )
                        .redacted(reason: viewStore.isLoading ? .placeholder : []) //1. redaction
                }
                .sheet(
                    item: viewStore.binding(get: \.readingArticle, send: .dismissArticle)
                ) { article in
                    NavigationView {
                        ArticleDetailView(article: article)
                            .navigationTitle(article.title)
                    }
                }
                .navigationTitle("Articles")
            }
            .onAppear { viewStore.send(.onAppear) }// viewStore은 action도 보낼 수 있음
        }
    }
}

struct ArticlesListView: View {
    let store: Store<ArticlesState, ArticlesAction>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            ForEachStore(
                self.store.scope(state: \.articles, action: ArticlesAction.article)
            ) { articleStore in
                WithViewStore(articleStore) { articleViewStore in
                    Button(action: { viewStore.send(.articleTapped(articleViewStore.state)) }) {
                        ArticleRowView(store: articleStore)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

private struct ArticleRowView: View {
    let store: Store<Article, ArticleAction>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            HStack(alignment: .top) {
                Image("")
                    .frame(width: 80, height: 80)
                    .background(Color(white: 0.9))
                    .padding([.trailing])
                
                VStack(alignment: .leading) {
                    Text(viewStore.title)
                        .font(.title)
                    
                    Text(articleDateFormatter.string(from: viewStore.date))
                        .bold()
                    
                    Text(viewStore.blurb)
                        .padding(.top, 6)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: { viewStore.send(.favoriteTapped) }) {
                            Image(systemName: "star.fill")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(viewStore.isFavorite ? .red : .blue)
                        .padding()
                        
                        Button(action: { viewStore.send(.readLaterTapped) }) {
                            Image(systemName: "book.fill")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(viewStore.willReadLater ? .yellow : .blue)
                        .padding()
                        
                        Button(action: { viewStore.send(.hideTapped) }) {
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
}

private struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        Text(self.article.blurb)
    }
}

struct Composable_Previews: PreviewProvider {
    static var previews: some View {
        ComposableArticlesView(
            store: Store(
                initialState: ArticlesState(),
                reducer: articlesReducer,
                environment: ()
            )
        )
    }
}
