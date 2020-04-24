//
//  ViewController.swift
//  WhatsApp4IPad
//
//  Created by Can Citoglu on 18.04.2020.
//  Copyright © 2020 Can Citoglu. All rights reserved.
//

import Foundation
import UIKit
import WebKit

enum Views {
       case Master
       case Detail
       case Both
   }
class WebViewController: UIViewController {
    var wkView: WKWebView? = nil
    private var observer: NSKeyValueObservation? = nil

    let controller = WKController()
   
    override func viewDidLoad() {
        let contentController = WKUserContentController()
        //    contentController.addUserScript(script)
        contentController.add(controller, name: "state")
        contentController.add(controller, name: "media")

        self.view.backgroundColor = .black
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.userContentController = contentController
        wkView = FullScreenWKWebView(frame: .zero, configuration: webViewConfiguration)

        wkView?.backgroundColor = .black

        // status = PageState.Undefined
        // statusView = Views.Both
        // frst = true
        super.viewDidLoad()
        if(view.layer.bounds.width < 650){
            self.controller.setView(state: Views.Master)
        }
        observer = view.layer.observe(\.bounds) { object, _ in
            if(object.bounds.width < 650.0) {
                self.controller.setView(state: Views.Master)
//                self.setTrigger()
            } else {
                self.controller.setView(state: Views.Both)
            }

            self.wkView?.frame = object.bounds
            self.wkView?.setNeedsLayout()
            self.wkView?.layoutIfNeeded()
            self.view.bounds = object.bounds
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

        }
        // wkView!.topAnchor.anchorWithOffset(to: view.topAnchor)

        wkView!.leftAnchor.anchorWithOffset(to: view.leftAnchor)
        wkView!.bottomAnchor.anchorWithOffset(to: view.bottomAnchor)
        wkView!.rightAnchor.anchorWithOffset(to: view.rightAnchor)
        wkView!.frame = self.view.bounds
        wkView!.setNeedsLayout()
        wkView!.layoutIfNeeded()

        wkView!.allowsBackForwardNavigationGestures = false
        wkView!.scrollView.isScrollEnabled = true
        wkView!.scrollView.bounces = false
        self.view.addSubview(wkView!)
        self.view.backgroundColor = UIColor.init(red: 35 / 255, green: 45 / 255, blue: 53 / 255, alpha: 1)
        wkView!.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            wkView!.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            wkView!.leftAnchor.constraint(equalTo: view.leftAnchor),
            wkView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wkView!.rightAnchor.constraint(equalTo: view.rightAnchor),
            ])


        wkView!.scrollView.delegate = self.controller
        wkView!.navigationDelegate = self.controller
        view.addInteraction(UIDropInteraction(delegate: self.controller))
        wkView?.uiDelegate = self.controller

        let url = URL(string: "https://web.whatsapp.com")!
       // let userAgent = "Mozilla/5.0 (X11; Linux i586; rv:31.0) Gecko/20100101 Firefox/71.0"
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1 Safari/605.1.15"

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        wkView!.customUserAgent = userAgent
        wkView!.load(request)


    }


}
class FullScreenWKWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
