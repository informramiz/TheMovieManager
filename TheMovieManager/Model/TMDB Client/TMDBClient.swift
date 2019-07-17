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
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken
                + "?redirect_to=" + AppDelegate.appBaseUrl + ":" + AppDelegate.authenticateEndpointPath
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
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
    class func taskForGetRequest<ResponseType: Decodable>(url: URL,
                                                          responseType: ResponseType.Type,
                                                          completionHandler: @escaping (ResponseType?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            handleResponse(data: data, error: error, responseType: responseType, completionHandler: completionHandler)
        }
        task.resume()
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
            callCompletionHandler(nil, error)
        }
    }
}
