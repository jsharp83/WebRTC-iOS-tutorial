//
//  TurnClient.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/01.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation

struct TurnClient {
    let turnClientUrl = URL(string: "https://appr.tc/params")!
    
    func request() {
        let task = URLSession.shared.dataTask(with: turnClientUrl) {(data, response, error) in
            guard let data = data else {
                if let error = error {
                    print("[TurnClient] Reuqest Error \(error)")
                }
                return
            }
            do {
                let resultDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let ice_server_url = resultDict?["ice_server_url"] as? String,
                    let iceURL = URL(string: ice_server_url) {
                    self.makeTurnServerRequest(iceURL: iceURL)
                }
            } catch let error {
                print("[TurnClient] Serialization Error \(error)")
            }
        }
        
        task.resume()
    }
    
    func makeTurnServerRequest(iceURL: URL) {
        var request = URLRequest(url: iceURL)
        request.httpMethod = "POST"
        request.addValue("https://appr.tc", forHTTPHeaderField: "referer")
        let task = URLSession.shared.dataTask(with: iceURL) { (data, response, error) in
            guard let data = data else { return }
            
            do {
                let resultDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print(resultDict)
            } catch let error {
                print("[TurnClient] Serialization Error \(error)")
            }
        }
        task.resume()
    }
}

