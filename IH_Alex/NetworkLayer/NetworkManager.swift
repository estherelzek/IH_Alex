//
//  NetworkManager.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private init() {}
    private let baseURL = "https://agenda-new.ark-technology.com/api.php?"
    var defaultHeaders: [String: String] {
           return [
               "Content-Type": "application/json",
               "Authorization": "Bearer \(UserDefaults.standard.string(forKey: "authToken") ?? "")"
           ]
       }

    func createURL(with path: String, queryParams: [String: String] = [:]) -> URL? {
            var urlString = baseURL
            if !path.isEmpty {
                urlString += "/" + path
            }
            if !queryParams.isEmpty {
                let queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
                var urlComponents = URLComponents(string: urlString)
                urlComponents?.queryItems = queryItems
                return urlComponents?.url
            }
            print("the link in fetch : \(urlString)")
            return URL(string: urlString)
        }
        
        func createRequest(with url: URL, httpMethod: String = "GET", parameters: [String: String]? = nil) -> URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            if let parameters = parameters {
                let parameterArray = parameters.map { "\($0.key)=\($0.value)" }
                let postDataString = parameterArray.joined(separator: "&")
                request.httpBody = postDataString.data(using: .utf8)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
            request.allHTTPHeaderFields = defaultHeaders
            return request
        }
    
    func sendPostRequest(with params: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        var urlString = "https://agenda-new.ark-technology.com/api.php?"
        for (key, value) in params {
            urlString += "\(key)=\(value)&"
        }
        urlString.removeLast() // Remove trailing "&"
        print("the link is : \(urlString)")
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.statusCode(httpResponse.statusCode)))
                return
            }
            
            if let data = data, let message = String(data: data, encoding: .utf8) {
                completion(.success(message))
            } else {
                completion(.failure(NetworkError.invalidData))
            }
        }
        task.resume()
    }
    
    func sendPostRequest(with params: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        var urlString = "https://agenda-new.ark-technology.com/api.php?"
        for (key, value) in params {
            urlString += "\(key)=\(value)&"
        }
        urlString.removeLast()
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        print("the link is : \(urlString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.statusCode(httpResponse.statusCode)))
                return
            }
            
            if let data = data, let message = String(data: data, encoding: .utf8) {
                completion(.success(message))
            } else {
                completion(.failure(NetworkError.invalidData))
            }
        }
        
        task.resume()
    }
    func sendPostRequestOfCustomerAnswes(with request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            
            guard let data = data, let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            if let message = String(data: data, encoding: .utf8) {
                completion(.success(message))
            } else {
                completion(.failure(NetworkError.invalidData))
            }
        }
        task.resume()
    }

//    func sendLoginRequest(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let request = API.userLoginID(email: email, password: password).request else {
//            completion(.failure(NetworkError.invalidURL))
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(NetworkError.invalidResponse))
//                return
//            }
//            
//            guard (200...299).contains(httpResponse.statusCode) else {
//                completion(.failure(NetworkError.statusCode(httpResponse.statusCode)))
//                return
//            }
//            
//            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
//                completion(.failure(NetworkError.invalidData))
//                return
//            }
//            
//            completion(.success(responseString))
//        }
//        
//        task.resume()
//    }
//    
    func getResultsStrings(APICase: API, decodingModel: Decodable.Type, completion: @escaping (Result<String, Error>) -> Void) {
        // Construct URL based on API case
        guard let url = URL(string: APICase.baseURL + "/" + APICase.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        print("URL : \(url)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                completion(.success(responseString))
            } else {
                completion(.failure(NSError(domain: "Failed to decode response", code: -1, userInfo: nil)))
            }
        }
        task.resume()
    }
  
//
    func sendDeleteRequest(queryParams: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        // Construct the URL with baseURL and queryParams
        guard let url = createURL(with: "", queryParams: queryParams) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = createRequest(with: url)
        request.httpMethod = "GET"
        
        print("URL for DELETE request: \(url)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request Error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])
                print("Invalid response data")
                completion(.failure(error))
                return
            }
            
            print("Response Data: \(responseString)")
            completion(.success(responseString))
        }
        
        task.resume()
    }

    
    func sendCancel(queryParams: [String: String], completion: @escaping (Result<String, Error>) -> Void) {
        // Assuming you are using URLSession or similar
        var urlComponents = URLComponents(string: "https://agenda-new.ark-technology.com/api.php")!
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status Code: \(httpResponse.statusCode)")
            }
            
            if let data = data, let responseData = String(data: data, encoding: .utf8) {
                print("Raw Response Data: \(responseData)")
                completion(.success(responseData))
            } else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
            }
        }
        task.resume()
    }


    func sendGetRequest(with queryParams: [String: String], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = createURL(with: "", queryParams: queryParams) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // Print the API URL for debugging
        print("API URL: \(url.absoluteString)")

        let request = createRequest(with: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }

}


enum NetworkError: Error {
    case invalidURL
    case jsonSerializationFailed
    case invalidResponse
    case statusCode(Int)
    case invalidData
    case noData
    case responseParsingError
    case decodingError
    case missingMemberId
}
