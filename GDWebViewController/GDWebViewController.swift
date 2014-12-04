//
//  GDWebViewController.swift
//  GDWebBrowserClient
//
//  Created by Alex G on 03.12.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit
import WebKit

enum GDWebViewControllerProgressIndicatorStyle {
    case ActivityIndicator
    case ProgressView
    case Both
    case None
}

@objc protocol GDWebViewControllerDelegate {
}

class GDWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    // MARK: Public Properties
    weak var delegate: GDWebViewControllerDelegate?
    var progressIndicatorStyle: GDWebViewControllerProgressIndicatorStyle? = .Both
    
    // MARK: Private Properties
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var progressView: UIProgressView!
    private var toolbarContainer: UIView!
    private var toolbarHeightConstraint: NSLayoutConstraint!
    private var toolbar: UIToolbar!
    
    // MARK: Public Methods
    
    func loadURLWithString(URLString: String) {
        if let URL = NSURL(string: URLString) {
            if (URL.scheme != nil) && (URL.host != nil) {
                loadURL(URL)
                return
            } else {
                loadURLWithString("http://\(URLString)")
                return
            }
        }
    }
    
    func loadURL(URL: NSURL, cachePolicy: NSURLRequestCachePolicy = .UseProtocolCachePolicy, timeoutInterval: NSTimeInterval = 0) {
        webView.loadRequest(NSURLRequest(URL: URL, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval))
    }
    
    func showToolbar(show: Bool, animated: Bool) {
        if show && (toolbar == nil) {
            toolbar = UIToolbar()
            toolbar.setTranslatesAutoresizingMaskIntoConstraints(false)
            toolbarContainer.addSubview(toolbar)
            toolbarContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[toolbar]-0-|", options: nil, metrics: nil, views: ["toolbar": toolbar]))
            toolbarContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[toolbar]-0-|", options: nil, metrics: nil, views: ["toolbar": toolbar]))
            
            // Set up toolbar
            let backButtonItem = UIBarButtonItem(title: "\u{25C0}\u{FE0E}", style: UIBarButtonItemStyle.Plain, target: self, action: "goBack")
            let forwardButtonItem = UIBarButtonItem(title: "\u{25B6}\u{FE0E}", style: UIBarButtonItemStyle.Plain, target: self, action: "goForward")
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            let refreshButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "refresh")
            toolbar.setItems([backButtonItem, forwardButtonItem, flexibleSpace, refreshButtonItem], animated: false)
        }
        
        UIView.animateWithDuration(animated ? 0.2 : 0, animations: { () -> Void in
            self.toolbarHeightConstraint.constant = show ? 44 : 0
        })
    }
    
    // MARK: Navigation Methods
    func goBack() {
    }
    
    func goForward() {
    }
    
    func refresh() {
    }
    
    // MARK: WKNavigationDelegate Methods
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        animateActivityIdicator(false)
        showError(error.localizedDescription)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        animateActivityIdicator(false)
        showError(error.localizedDescription)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        animateActivityIdicator(false)
    }
    
    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if (progressIndicatorStyle == .ActivityIndicator) || (progressIndicatorStyle == .Both) {
            animateActivityIdicator(true)
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.Allow)
    }
    
    // MARK: Some Private Methods
    
    private func showError(errorString: String?) {
        var alertView = UIAlertController(title: "Error", message: errorString, preferredStyle: .Alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    private func animateActivityIdicator(animate: Bool) {
        if animate {
            if activityIndicator == nil {
                activityIndicator = UIActivityIndicatorView()
                activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.2)
                activityIndicator.activityIndicatorViewStyle = .WhiteLarge
                activityIndicator.hidesWhenStopped = true
                activityIndicator.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.view.addSubview(activityIndicator!)
                
                self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[activityIndicator]-0-|", options: nil, metrics: nil, views: ["activityIndicator": activityIndicator]))
                self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[activityIndicator]-0-|", options: nil, metrics: nil, views: ["activityIndicator": activityIndicator]))
            }
            
            activityIndicator.startAnimating()
        } else if activityIndicator != nil {
            activityIndicator.stopAnimating()
        }
    }
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {        
        if keyPath == "estimatedProgress" {
            if (progressIndicatorStyle == .ProgressView) || (progressIndicatorStyle == .Both) {
                if let newValue = change[NSKeyValueChangeNewKey] as? NSNumber {
                    if progressView == nil {
                        progressView = UIProgressView()
                        progressView.setTranslatesAutoresizingMaskIntoConstraints(false)
                        self.view.addSubview(progressView)
                        
                        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[progressView]-0-|", options: nil, metrics: nil, views: ["progressView": progressView]))
                        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[progressView(2)]", options: nil, metrics: nil, views: ["progressView": progressView]))
                    }
                    
                    progressView.progress = newValue.floatValue
                    if progressView.progress == 1 {
                        progressView.progress = 0
                        UIView.animateWithDuration(0.2, animations: { () -> Void in
                            self.progressView.alpha = 0
                        })
                    } else if progressView.alpha == 0 {
                        UIView.animateWithDuration(0.2, animations: { () -> Void in
                            self.progressView.alpha = 1
                        })
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up toolbarContainer
        self.view.addSubview(toolbarContainer)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[toolbarContainer]-0-|", options: nil, metrics: nil, views: ["toolbarContainer": toolbarContainer]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[toolbarContainer]-0-|", options: nil, metrics: nil, views: ["toolbarContainer": toolbarContainer]))
        toolbarHeightConstraint = NSLayoutConstraint(item: toolbarContainer, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 0)
        toolbarContainer.addConstraint(toolbarHeightConstraint)
        
        // Set up webView
        self.view.addSubview(webView)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[webView]-0-|", options: nil, metrics: nil, views: ["webView": webView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[webView]-0-[toolbarContainer]|", options: nil, metrics: nil, views: ["webView": webView, "toolbarContainer": toolbarContainer]))
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override init() {
        super.init()
        
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.UIDelegate = self
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        toolbarContainer = UIView()
        toolbarContainer.setTranslatesAutoresizingMaskIntoConstraints(false)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

}