//
//  RequestTokenResponse.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Updated by Ramiz Raja on 14/07/19
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

struct RequestTokenResponse: Codable {
    let success: Bool
    let expiresAt: String
    let requestToken: String
    let statusMessage: String?
    let statusCode: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case expiresAt = "expires_at"
        case requestToken = "request_token"
        case statusMessage = "status_message"
        case statusCode = "status_code"
    }
}
