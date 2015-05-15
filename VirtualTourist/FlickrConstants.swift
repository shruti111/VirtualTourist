//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Shruti Pawar on 10/05/15.
//  Copyright (c) 2015 ShapeMyApp Software Solutions Pvt. Ltd. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    //MARK:- Constants to call Flickr webAPI
    struct Constant {
        static let ApiKey: String = "2b1f8191c2e24fc2a806f12040878581"
        static let BaseURL: String = "https://api.flickr.com/services/rest/"
        static let Safesearch = "1"
        static let Extras = "url_m"
        static let DataFormat = "json"
        static let No_JSON_CALLBACK = "1"
        static let photosPerPage = 21
    }
    
    //MARK:- Flickr methods to download data
    struct Methods {
    static let SearchPhotosbyLatLon = "flickr.photos.search"
    }
    
    // MARK: - Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Safesearch = "safe_search"
        static let Extras = "extras"
        static let Dataformat = "format"
        static let NOJSONCallback = "nojsoncallback"
        static let pageNumber = "page"
        static let photosPerPage = "per_page"

    }
    // MARK: - JSON Response Keys
    struct JSONResponseKeys {
        static let Photos = "photos"
        static let TotalPages = "pages"
        static let Photo = "photo"
        static let Message = "msg"

    }
    
}