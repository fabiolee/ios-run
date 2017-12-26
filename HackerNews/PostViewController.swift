//
//  PostViewController.swift
//  HackerNews
//
//  Created by Fabio on 09/12/2017.
//  Copyright © 2017 Amit Burstein. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
    // MARK: Properties
  
    @IBOutlet weak var postTitle: UILabel!
  @IBOutlet weak var postContent: UITextView!
    var retrievingPost: Bool!
    var path: String!
  
  // MARK: Initialization
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    retrievingPost = false
  }

    override func viewDidLoad() {
        super.viewDidLoad()
        retrievePost()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
  
  // MARK: Private Functions
  
  private func retrievePost() {
    if retrievingPost! {
      return
    }
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    retrievingPost = true
    
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    let url = URL(string: "https://www.googleapis.com/blogger/v3/blogs/9027509069015616506/posts/bypath?key=AIzaSyDGktXyn4O-hKkVkVFna7NQOrEOxfcwqTA&path=" + path)!
    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
    let task = session.dataTask(with: request) { (data, response, error) in
      if error != nil {
        print(error as Any)
      } else {
        if let urlContent = data {
          do {
            let jsonContent = try (JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers)) as AnyObject
            DispatchQueue.main.async() {
              self.postTitle.text = jsonContent["title"] as? String
              
              let htmlText = jsonContent["content"] as? String ?? ""
              let modifiedFont = String(format:"<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: \(self.postContent.font!.pointSize)\">%@</span>", htmlText)
              let htmlData = modifiedFont.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
              let attributedString = try! NSAttributedString(data: htmlData!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
              self.postContent.attributedText = attributedString
              
              self.retrievingPost = false
              UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
          }
          catch {
            print("Couldn't access JSON data")
          }
        }
      }
    }
    task.resume()
  }

}
