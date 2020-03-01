//
//  Extensions.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/04.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return nil
    }
}

extension Dictionary {
    var JSONData: Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return nil
        }
        return data
    }
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}

extension UIViewController {
    func embedView(_ addingView: UIView, into containerView: UIView) {
        containerView.addSubview(addingView)
        addingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view": addingView]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view": addingView]))
        containerView.layoutIfNeeded()
    }
}
