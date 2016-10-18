//
//  LocalNotificationHelper.swift
//  LocalNotificationHelper
//
//  Created by Ivailo Kanev on 17/10/16.
//  Copyright © 2016 Kanev. All rights reserved.
//

import UIKit
import UserNotifications
public protocol LocalNotificationHelperDelegate: class {
    func authorizationDidChanged(authorization: Bool)
}
public class LocalNotificationHelper:NSObject, UNUserNotificationCenterDelegate  {
    
    private var status: Bool = false
    open static let `default` = LocalNotificationHelper()

    public weak var delegate: LocalNotificationHelperDelegate?
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    public func monitor(){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self 
        } else {
            // Fallback on earlier versions
        }
        
    }
    public static func register(completed: @escaping (_ status: Bool) -> Void?) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                `default`.status = granted
                completed(granted)
                
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    
    
    /// Sets a closure to be called periodically during the lifecycle of the request as data is read from the server.
    ///
    /// This closure returns authorization status
    ///
    /// - parameter closure: if authorized returns true, non authorized returns false
    ///
    public static func authorized(completed: @escaping (_ status: Bool) -> Void){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings(completionHandler: { (settings) in
                switch settings.authorizationStatus {
                case .authorized:
                    completed(true)
                case .denied:
                    completed(false)
                case .notDetermined:
                    register(completed: { (status) in
                        completed(status)
                    })
                }
            })
            
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    //MARK: - Private
    func applicationDidBecomeActive(){
        LocalNotificationHelper.authorized { (status) in
            if self.status != status {
                self.delegate?.authorizationDidChanged(authorization: status)
                self.status = status
            }
        }
    }
}
