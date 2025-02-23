//
//  EndPoint.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

fileprivate let requestTimeOut: Double = 60
enum HTTPMethod: String{
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

protocol EndPoint{
    var baseURL: String { get }
    var method: HTTPMethod { get }
    var urlSubFolder: String { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var body: [String: Any]? {get}
}
extension EndPoint {
    var urlComponents: URLComponents {
        var components = URLComponents(string: baseURL)!
        components.path = urlSubFolder + "/" + path
        components.queryItems = queryItems
        
        print("Urlllllllll", components.url)
        
        return components
    }
    
    var request: URLRequest {
        let url = urlComponents.url!
        var request =  URLRequest(url: url,timeoutInterval: requestTimeOut)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if body != nil {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return request
    }
    
}
