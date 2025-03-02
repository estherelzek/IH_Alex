//
//  NetworkServer.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation
import Reachability
import Alamofire

class NetworkService {
    let reach = try! Reachability()
    static let shared = NetworkService()
    let reachability = try! Reachability()
    
   func getResultsStrings<M: Codable>(APICase: API,decodingModel: M.Type, completed: @escaping (Result<String,ErorrMessage> ) -> Void) {
//       if APICase.request.url?.absoluteString.contains("add_pm_visit") || APICase.request.url?.absoluteString.contains("add_am_visit") ||  APICase.request.url?.absoluteString.contains("report_pm_visiting_day") ||   APICase.request.url?.absoluteString.contains("report_am_visiting_day") {
//
//   }
       var request: URLRequest = APICase.request
        request.httpMethod = APICase.method.rawValue
       reachability.whenUnreachable = { _ in
           print("Not reachable")
           switch APICase {
           
           default:
               completed((.failure(.InvalidRequest)))
           }
       }

       do {
           try reachability.startNotifier()
       } catch {
           print("Unable to start notifier")
       }
       switch APICase {
           
       default:
           break
       }
       //print("request astora:",request.url?.absoluteString)
      // print("request astora:",request.httpBody)
       if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
           print("request body string :",bodyString)
       }
//       UserDefaults.standard.set("add_am_visit", forKey: <#T##String#>)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error =  error {
                print("❌ Error: ",error)
                completed((.failure(.InvalidData)))
            }
            
            guard let data = data else {
                print("❌ Error in data: ",data ?? "")
                completed((.failure(.InvalidData)))
                return
            }
            
            guard let response =  response  as? HTTPURLResponse ,response.statusCode == 200 else {
                print("❌ Error in response: ",response ?? "")
                completed((.failure(.InvalidResponse)))
                return
            }
//            let decoder = JSONDecoder()
            do
            {
                guard let str = String(data: data, encoding: .utf8) else { return }
//                let results = try decoder.decode(M.self, from: data)
                print("✅ Results: ",str)
                completed((.success(str)))
                
            } catch {
                print(error)
                completed((.failure(.InvalidData)))
            }
        }
        task.resume()
    }
    
    enum APIError: Error {
        case invalidRequest
        case invalidData
        case invalidResponse
    }
    
    func getResults<M: Codable>(APICase: API, decodingModel: M.Type, completed: @escaping (Result<M, APIError>) -> Void) {
        var request: URLRequest = APICase.request
        request.httpMethod = APICase.method.rawValue

        print("Request URL: \(request.url?.absoluteString ?? "Invalid URL")")

        reachability.whenUnreachable = { _ in
            print("Not reachable")
            switch APICase {
            default:
                completed(.failure(.invalidRequest))
            }
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }

        switch APICase {
        default:
            break
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("❌ Error: ", error)
                completed(.failure(.invalidData))
                return
            }
            
            guard let data = data else {
                print("❌ Error in data")
                completed(.failure(.invalidData))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("❌ Error in response")
                completed(.failure(.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(M.self, from: data)
                print("✅ Results: ", result)
                completed(.success(result))
            } catch {
                print("❌ Error decoding data: ", error)
                completed(.failure(.invalidData))
            }
        }
        task.resume()
    }


//    func getResults<M: Codable>(APICase: API,decodingModel: M.Type, completed: @escaping (Result<M,ErorrMessage> ) -> Void) {
//
//        let request : URLRequest = APICase.request ?? URLRequest(url: URL(string: "https://example.com")!)
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            if let error =  error {
//                completed((.failure(.InvalidData)))
//            }
//            guard let data = data else {
//                completed((.failure(.InvalidData)))
//                return
//            }
//            guard let response =  response  as? HTTPURLResponse ,response.statusCode == 200 else{
//                completed((.failure(.InvalidResponse)))
//                return
//            }
//            let decoder = JSONDecoder()
//            do
//            {
//
////                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                let results = try decoder.decode(M.self, from: data)
//                print(results)
//                completed((.success(results)))
//
//            }catch {
//                print(error)
//                completed((.failure(.InvalidData)))
//            }
//
//        }
//        task.resume()
//    }
//
    
    //With String
    func getResultsStrings<M: Codable>(urlStr :String, decodingModel: M.Type, completed: @escaping (Result<String,ErorrMessage> ) -> Void) {

        guard let url = URL(string: urlStr) else { return }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
             if let error =  error {
                 print("❌ Error: ",error)
                 completed((.failure(.InvalidData)))
             }
             guard let data = data else {
                 print("❌ Error in data: ")
                 completed((.failure(.InvalidData)))
                 return
             }
             
             guard let response =  response  as? HTTPURLResponse ,response.statusCode == 200 else {
                 print("❌ Error in response: ")
                 completed((.failure(.InvalidResponse)))
                 return
             }
             do
             {
                 guard let str = String(data: data, encoding: .utf8) else { return }
                 print("✅ Results: ",str)
                 
                 completed((.success(str)))
                 
             } catch {
                 print(error)
                 completed((.failure(.InvalidData)))
             }
             
         }
         task.resume()
     }
}
extension NetworkService {
   
}
