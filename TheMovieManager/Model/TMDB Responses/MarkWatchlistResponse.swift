//
//  MarkWatchlistResponse.swift
//  TheMovieManager
//
//  Created by Apple on 19/07/2019.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation

struct MarkWatchlistResponse: Codable {
    let statusCode: Int
    let statusMessage: String
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
