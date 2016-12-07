//
//  AppDelegate.swift
//  PhotoBrowserDemo
//
//  Created by Eduardo Callado on 11/27/16.
//
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var viewController: UIViewController?
}

// MARK: - Application State

extension AppDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		
		self.window = UIWindow.init(frame: UIScreen.main.bounds)
		
		let menuVC = MenuViewController.init(style: .grouped)
		
		self.viewController = UINavigationController.init(rootViewController: menuVC)
		
		self.window?.rootViewController = self.viewController
		self.window?.makeKeyAndVisible()
		
		return true
	}
}
