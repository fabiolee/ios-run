//
//  PageViewController.swift
//  HackerNews
//
//  Copyright (c) 2015 Amit Burstein. All rights reserved.
//  See LICENSE for licensing information.
//

import Firebase
import SafariServices
import SwiftSoup
import UIKit

class PageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
  
  // MARK: Properties
  
  let PostCellIdentifier = "PostCell"
  let ShowBrowserIdentifier = "ShowBrowser"
  let ShowPostIdentifier = "ShowPost"
  let PullToRefreshString = "Pull to Refresh"
  let FetchErrorMessage = "Could Not Fetch Posts"
  let ErrorMessageLabelTextColor = UIColor.gray
  let ErrorMessageFontSize: CGFloat = 16
  let FirebaseRef = "https://hacker-news.firebaseio.com/v0/"
  let ItemChildRef = "item"
  let StoryTypeChildRefMap = [StoryType.top: "topstories", .new: "newstories", .show: "showstories"]
  let StoryLimit: UInt = 30
  let DefaultStoryType = StoryType.top
  
  var firebase: Firebase!
  var stories: [Story]! = []
  var storyType: StoryType!
  var retrievingStories: Bool!
  var refreshControl: UIRefreshControl!
  var errorMessageLabel: UILabel!
  
  @IBOutlet weak var tableView: UITableView!
  
  // MARK: Enums
  
  enum StoryType {
    case top, new, show
  }
  
  // MARK: Structs
  
  struct Story {
    let title: String
    let url: String?
    let by: String
    let score: Int
  }
  
  // MARK: Initialization
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    firebase = Firebase(url: FirebaseRef)
    stories = []
    storyType = DefaultStoryType
    retrievingStories = false
    refreshControl = UIRefreshControl()
  }
  
  // MARK: UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
    retrieveStories()
  }
  
  // MARK: Functions
  
  func configureUI() {
    refreshControl.addTarget(self, action: #selector(PageViewController.retrieveStories), for: .valueChanged)
    refreshControl.attributedTitle = NSAttributedString(string: PullToRefreshString)
    tableView.insertSubview(refreshControl, at: 0)
    
    // Have to initialize this UILabel here because the view does not exist in init() yet.
    errorMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
    errorMessageLabel.textColor = ErrorMessageLabelTextColor
    errorMessageLabel.textAlignment = .center
    errorMessageLabel.font = UIFont.systemFont(ofSize: ErrorMessageFontSize)
  }
  
  func retrieveStories() {
    if retrievingStories! {
      return
    }
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    retrievingStories = true
    
    let url = URL(string: "https://www.googleapis.com/blogger/v3/blogs/9027509069015616506/pages/6337578441124076615?key=AIzaSyDGktXyn4O-hKkVkVFna7NQOrEOxfcwqTA")!
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      if error != nil {
        self.loadingFailed(error)
      } else {
        if let urlContent = data {
          do {
            let jsonContent = try (JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers)) as AnyObject
              DispatchQueue.main.async() {
                self.stories = self.extractStoryArray(jsonContent)
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
                self.retrievingStories = false
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
  
  func extractStoryArray(_ jsonContent: AnyObject) -> [Story] {
    var storyArray = [Story]()
    let title = jsonContent["title"] as? String ?? ""
    do{
      if let content = jsonContent["content"] as? String {
        let elements: Elements = try SwiftSoup.parse(content).select("ul li")
        for element: Element in elements.array() {
          let title: String = try element.text()
          let url: String = try element.select("a").attr("href")
          storyArray.append(Story(title: title, url: url, by: "Fabio", score: 0))
        }
      } else {
        loadingFailed(nil)
      }
    }catch Exception.Error( _, let message){
      print(message)
    }catch{
      print("error")
    }
    return storyArray
  }
  
  func loadingFailed(_ error: Error?) -> Void {
    self.retrievingStories = false
    self.stories.removeAll()
    self.tableView.reloadData()
    self.refreshControl.endRefreshing()
    self.showErrorMessage(self.FetchErrorMessage)
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }
  
  func showErrorMessage(_ message: String) {
    errorMessageLabel.text = message
    self.tableView.backgroundView = errorMessageLabel
    self.tableView.separatorStyle = .none
  }
  
  // MARK: Segues
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == ShowPostIdentifier {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let story = stories[indexPath.row]
        let controller = segue.destination as! PostViewController
        let url = URL(string: story.url!)
        controller.path = url?.path
      }
    }
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return stories.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let story = stories[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: PostCellIdentifier) as UITableViewCell!
    cell?.textLabel?.text = story.title
    return cell!
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    //let story = stories[indexPath.row]
    //if let url = story.url {
    //  let webViewController = SFSafariViewController(url: URL(string: url)!)
    //  webViewController.delegate = self
    //  present(webViewController, animated: true, completion: nil)
    //}
  }
  
  // MARK: SFSafariViewControllerDelegate
  
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
  
  // MARK: IBActions
  
  @IBAction func changeStoryType(_ sender: UISegmentedControl) {
    if sender.selectedSegmentIndex == 0 {
      storyType = .top
    } else if sender.selectedSegmentIndex == 1 {
      storyType = .new
    } else if sender.selectedSegmentIndex == 2 {
      storyType = .show
    } else {
      print("Bad segment index!")
    }
    
    retrieveStories()
  }
}
