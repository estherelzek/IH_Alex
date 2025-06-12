//
//  ErrorModel.swift
//  IH_Alex
//
//  Created by esterelzek on 17/02/2025.
//

import Foundation

enum ErorrMessage : String,Error {
    case InvalidData = "Sorry ,Something went wrong try agian."
    case InvalidRequest = "Sorry ,This url isn't good enough ,Try agian later."
    case InvalidResponse = " Server Error ,Modify your search and try agian."
}
enum APIError: Error {
    case invalidRequest
    case invalidData
}
