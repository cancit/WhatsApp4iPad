//
//  WKController.swift
//  WhatsApp4IPad
//
//  Created by Can Citoglu on 23.04.2020.
//  Copyright © 2020 Can Citoglu. All rights reserved.
//

import Foundation
import WebKit
import UIKit

class WKController: NSObject, WKNavigationDelegate, UIScrollViewDelegate, UIDropInteractionDelegate, WKUIDelegate, WKScriptMessageHandler {
    var state: Views = Views.Both
    var wkView: WKWebView?
    func setView(state: Views) {
        self.state = state
        if(wkView == nil) {
            return
        }
        switch(state) {
        case .Master:
            //    wkView?.evaluateJavaScript("document.querySelector(\"#side\").parentElement.parentElement.style.minWidth = \"0px\"", completionHandler: nil)
            wkView?.evaluateJavaScript("document.querySelector(\"#side\").parentElement.style.flex = \"0 0 100%\"", completionHandler: nil)
            break;
        case .Detail:
            wkView?.evaluateJavaScript("document.querySelector(\"#side\").parentElement.style.flex = \"0 0 0%\"", completionHandler: nil)
            self.addBackButton(wkView!)
            break;
        case .Both:
            wkView?.evaluateJavaScript("document.querySelector(\"#side\").parentElement.style.flex = \"0 0 35%\"", completionHandler: nil)
            break;
        }
    }
    func addBackButton(_ webView: WKWebView) {
        let jsString = """
                   if (document.getElementById('backbutton') == null) {
                       var backbtn = document.createElement('div');
                       backbtn.setAttribute('id', 'backbutton');
                       backbtn.style.marginRight = "10px";
                       backbtn.innerHTML = '<span><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path fill="#fff" d="M20 11H7.8l5.6-5.6L12 4l-8 8 8 8 1.4-1.4L7.8 13H20v-2z"></path></svg></span>';
                       var header = document.querySelector("#main > header");
                       header.insertBefore(backbtn, header.childNodes[0]);
                       document.getElementById('backbutton').addEventListener('click', function() {webkit.messageHandlers.state.postMessage("view:master");});
                   }
                   """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
        print("addBackButton")
    }
    func fixDoubleClickIssue(_ webView: WKWebView) {
        let jsString = """
        document.querySelectorAll(\"#pane-side\").forEach((d)=>{
            d.addEventListener(\"touchstart\",(e)=>{
             click=true
            })
            d.addEventListener(\"touchmove\",(e)=>{
            click=false
           })
          d.addEventListener(\"touchend\",(e)=>{
            if(click){
            e.target.dispatchEvent(new MouseEvent(\"mousedown\", e));
            webkit.messageHandlers.state.postMessage(\"view:detail\");
            }
           })
        })
        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
        print("fixDoubleClickIssue")
        self.checkHeaderLoaded(webView)
        self.checkEmptyScreen(webView)
        self.setView(state: self.state)
    }
    func checkEmptyScreen(_ webView: WKWebView) {
        // only run in detail
        if(self.state == Views.Detail) {
            let jsString = """
            (function() {
            const isConnectedScreenVisible = !!document.querySelector(\"#app > div > div > div._1-iDe.Wu52Z > div > div > div._2bBPp\")
            if(isConnectedScreenVisible){
                webkit.messageHandlers.state.postMessage(\"view:master\");
            }
            })();
            """
            webView.evaluateJavaScript(jsString, completionHandler: nil)
            print("checkEmptyScreen")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.checkEmptyScreen(webView)
        }
    }
    func bindNewChatButton(_ webView: WKWebView) {
        let jsString = """
        document.querySelectorAll(\"#side > header > div._3euVJ > div > span > div:nth-child(2)\")[0].addEventListener(\"click\",(e)=>{
          webkit.messageHandlers.state.postMessage(\"action:newChatOpen\");
        })
        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
        print("bindNewChatButton")
    }
    func checkChatOpen(_ webView: WKWebView) {
        let jsString2 = """
                       document.querySelectorAll(\"#app > div > div > div.YD4Yw > div._1-iDe._1xXdX > span > div > span > div > div._1qDvT._2wPpw > div:nth-child(2) > div > div > div \").forEach((d)=>{
                         d.addEventListener(\"click\",(e)=>{
                           e.target.dispatchEvent(new MouseEvent(\"mousedown\", e));
                           webkit.messageHandlers.state.postMessage(\"view:detail\");
                          })
                       })
                       """
        webView.evaluateJavaScript(jsString2, completionHandler: nil)
        print("checkChatOpen")

    }
    func addUserMediaListener(_ webView: WKWebView) {
        // For experimental microphone support
        let jsString = """
        (function() {
          if (!window.navigator) window.navigator = {mediaDevices:{}};
          window.navigator.mediaDevices.getUserMedia = function() {
            webkit.messageHandlers.media.postMessage(JSON.stringify(arguments));
          }
        })();
        """
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    func checkChatsLoaded(_ webView: WKWebView) {
        let jsString = "document.querySelectorAll(\"#pane-side\").length"
        webView.evaluateJavaScript(jsString) { (result, error) in
            let i = result as! Int
            if(i > 0) {
                self.fixDoubleClickIssue(webView)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.checkChatsLoaded(webView)
                }
            }
        }
        print("checkChatsLoaded")
    }
    func checkHeaderLoaded(_ webView: WKWebView) {
        let jsString = "document.querySelectorAll(\"#side > header > div._3euVJ > div > span > div:nth-child(2)\").length"
        webView.evaluateJavaScript(jsString) { (result, error) in
            let i = result as! Int
            if(i > 0) {
                self.bindNewChatButton(webView)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.checkHeaderLoaded(webView)
                }
            }
        }
        print("checkHeaderLoaded")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.wkView = webView
        //   addUserMediaListener(webView)
        insertContentsOfCSSFile(into: webView) // 2
        checkChatsLoaded(webView)
    }
    func userContentController(_ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage) {
        print(message.name)
        print(message.body)
        switch message.name {
        case "state":
            let body = message.body as! String
            if(state != Views.Both) {
                if(body == "view:detail") {
                    self.setView(state: Views.Detail)
                } else if(body == "view:master") {
                    self.setView(state: Views.Master)
                }
            }
            if(body == "action:newChatOpen") {
                self.checkChatOpen(self.wkView!)
            }
        default:
            print(message.name)
            print(message.body)
        }

    }

    func webView(_ webView: WKWebView, shouldStartLoadWith request: URLRequest, navigationType: Any) -> Bool {
        if request.url?.scheme == "logger" {
            guard let data = request.url?.query?.removingPercentEncoding?.data(using: .utf8) else { return true }
            guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) else { return true }
            guard let jsonData = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted) else { return true }
            guard let json = String(data: jsonData, encoding: .utf8) else { return true }
            print(json)
        }
        return true
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                print(url)
                print("Redirected to browser. No need to open it locally")
                decisionHandler(.cancel)
            } else {
                print("Open it locally")
                decisionHandler(.cancel)
            }
        } else {
            print("not a user click")
            decisionHandler(.allow)
        }
    }
    func insertContentsOfCSSFile(into webView: WKWebView) {
        guard let path = Bundle.main.path(forResource: "styles", ofType: "css") else { return }
        let cssString = try! String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: "")
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))

        // present(alertController, animated: true, completion: nil)
    }


    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        //    present(alertController, animated: true, completion: nil)
    }


    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))

        //      present(alertController, animated: true, completion: nil)
    }
}

