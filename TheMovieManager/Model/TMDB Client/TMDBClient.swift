//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Updated by Ramiz Raja on 14/07/19
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    //TODO: Remove it and move it to somewhere safe
    static let apiKey = "8a7b4cf5ff65fb391c470a670b052a4b"
    
    //TODO: This should be saved using persistence (user settings) but
    //because I (Ramiz) am only interested in practicing API authentication so
    //I am not going to bother
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getFavorites
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case search(query: String)
        case addToWatchList
        case markFavorite
        case downloadImage(path: String)
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken
                + "?redirect_to=" + AppDelegate.appBaseUrl + ":" + AppDelegate.authenticateEndpointPath
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=" + (query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
            case .addToWatchList: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .markFavorite: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .downloadImage(let path): return "https://image.tmdb.org/t/p/w500" + path
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) { (movieResults, error) in
            if let movieResults = movieResults {
                completion(movieResults.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func getFavorites(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getFavorites.url, responseType: MovieResults.self) { (movieResults, error) in
            if let movieResults = movieResults {
                completion(movieResults.results, nil)
            } else {
                completion([], nil)
            }
        }
    }
    
    class func search(query: String, completion: @escaping ([Movie], Error?) -> Void) -> URLSessionTask {
        return taskForGetRequest(url: Endpoints.search(query: query).url, responseType: MovieResults.self) { (movieResults, error) in
            if let movieResults = movieResults {
                completion(movieResults.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func watchlist(mediaId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let watchlistRequest = MarkWatchlist(mediaType: MediaType.movie, mediaId: mediaId, watchlist: watchlist)
        taskForPostRequest(url: Endpoints.addToWatchList.url, request: watchlistRequest, responseType: TMDBResponse.self) { (result, error) in
            if let result = result {
                completion(result.isSuccess, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func markFavorite(mediaId: Int, favorite: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let markFavoriteRequest = MarkFavorite(mediaType: MediaType.movie, mediaId: mediaId, favorite: favorite)
        taskForPostRequest(url: Endpoints.markFavorite.url, request: markFavoriteRequest, responseType: TMDBResponse.self) { (result, error) in
            if let result = result {
                completion(result.isSuccess, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func downloadImage(posterPath: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.downloadImage(path: posterPath).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
    class func getRequestToken(completionHandler: @escaping (Bool, Error?) -> Void) {
        taskForGetRequest(url: Endpoints.getRequestToken.url, responseType: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    class func login(username: String, password: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        let loginRequest = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        taskForPostRequest(url: Endpoints.login.url, request: loginRequest, responseType: RequestTokenResponse.self) { (response, error) in
            if let _ = response {
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    class func createSessionId(completionHandler: @escaping (Bool, Error?) -> Void) {
        let request = PostSession(requestToken: Auth.requestToken)
        taskForPostRequest(url: Endpoints.createSessionId.url, request: request, responseType: SessionResponse.self) { (sessionResponse, error) in
            if let sessionResponse = sessionResponse {
                Auth.sessionId = sessionResponse.sessionId
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
        
    }
    
    class func logout(completionHandler: @escaping () -> Void) {
        var urlRequest = URLRequest(url: Endpoints.logout.url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try! JSONEncoder().encode(LogoutRequest(sessionId: Auth.sessionId))
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            //clear data no matter what the API result because user will be logged out anyway
            Auth.requestToken = ""
            Auth.sessionId = ""
            completionHandler()
        }
        task.resume()
    }
    
    /*
     We need parameter `response: ResponseType.Type` so that we can receive type information from the call regarding the
     generic type `ResponseType`. We need this because in Swift we can't specialize functions by writing them like `taskForGetRequest<MyType>(...)`
     as this syntax is invalid in Swift. So the only way to receive type info is to pass type info as param
     */
    @discardableResult class func taskForGetRequest<ResponseType: Decodable>(url: URL,
                                                          responseType: ResponseType.Type,
                                                          completionHandler: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            handleResponse(data: data, error: error, responseType: responseType, completionHandler: completionHandler)
        }
        task.resume()
        return task
    }
    
    /*
     We need parameter `response: ResponseType.Type` so that we can receive type information from the call regarding the
     generic type `ResponseType`. We need this because in Swift we can't specialize functions by writing them like `taskForPostRequest<MyType>(...)`
     as this syntax is invalid in Swift. So the only way to receive type info is to pass type info as param
     */
    class func taskForPostRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL,
                                                                                   request: RequestType,
                                                                                   responseType: ResponseType.Type,
                                                                                   completionHandler: @escaping (ResponseType?, Error?) -> Void) {
        //build http body
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try! JSONEncoder().encode(request)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            handleResponse(data: data, error: error, responseType: responseType, completionHandler: completionHandler)
        }
        task.resume()
    }
    
    private class func handleResponse<ResponseType: Decodable>(data: Data?,
                                                          error: Error?,
                                                          responseType: ResponseType.Type,
                                                          completionHandler: @escaping (ResponseType?, Error?) -> Void) {
        let callCompletionHandler = { (response: ResponseType?, error: Error?) in
            DispatchQueue.main.async {
                completionHandler(response, error)
            }
        }
        
        guard let data = data else {
            callCompletionHandler(nil, error)
            return
        }
        
        do {
            let response = try JSONDecoder().decode(ResponseType.self, from: data)
            callCompletionHandler(response, nil)
        } catch {
            handleError(data, callCompletionHandler)
        }
    }
    
    private class func handleError<ResponseType: Decodable>(_ data: Data,
                                                            _ callCompletionHandler: (ResponseType?, Error?) -> ()) {
        //try parsing the error to TMDB error object
        do {
            let errorResponse = try JSONDecoder().decode(TMDBResponse.self, from: data)
            callCompletionHandler(nil, errorResponse)
        } catch {
            callCompletionHandler(nil, error)
        }
    }
}
