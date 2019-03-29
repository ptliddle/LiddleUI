//
//  SwitchableViewControllerContainerViewController.swift
//  Pods
//
//  Created by Peter Liddle on 12/16/15.
//
//

import UIKit

@IBDesignable open class SwitchableViewControllerContainerViewController: UIViewController {
    
    @IBInspectable public var defaultSegueIdentifier : String?
    
    open var defaultSegueCallback : ((_ segue: UIStoryboardSegue) -> ())? {
        set(newCallback) {
            if let id = defaultSegueIdentifier {
                segueCallbacks?[id] = newCallback
            }
            else {
                printSetDefaultSegueError()
            }
        }
        get {
            if let id = defaultSegueIdentifier {
                return segueCallbacks?[id]
            }
            
            return nil
        }
    }
    
    public var currentVC : UIViewController?
    
    var segueCallbacks : [String : (UIStoryboardSegue)->()]? = [:]
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        //If the parent view controller is a navigation view
        if(self.parent is UINavigationController) {
            replaceBackButton()
        }
        
        if let id = defaultSegueIdentifier {
            self.performSegue(withIdentifier: id, sender: nil)
        }
        else {
            printSetDefaultSegueError()
        }
    }
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let _identifier = segue.identifier {
            if let callback = segueCallbacks?[_identifier] {
                callback(segue)
            }
        }
        
        var existingInstance: UIViewController?
        for childViewController in children {
            if childViewController.isKind(of: type(of: segue.destination)) {
                existingInstance = childViewController
            }
        }
        
        let newCurrentVC: UIViewController
        if let existingInstance = existingInstance {
            newCurrentVC = existingInstance
            self.view.bringSubviewToFront(newCurrentVC.view)

        } else {
            newCurrentVC = segue.destination
            self.addChild(newCurrentVC)
            newCurrentVC.view.frame = self.view.bounds
            self.view.addSubview(newCurrentVC.view)
        }
        
        newCurrentVC.view.isHidden = false
        hideAllViews(exceptViewFoVC: newCurrentVC)

        
        // TODO find a way to not call this if it will already get called
        newCurrentVC.viewWillAppear(false)
        currentVC = newCurrentVC
    }
    
    private func hideAllViews(exceptViewFoVC vcToShow : UIViewController) {
        self.children.forEach({ vc in
            if(vc != vcToShow) {
                vc.view.isHidden = true
            }
        })
    }
    
    func replaceBackButton() {
        let backBtn = UIBarButtonItem(title: "TEST", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = backBtn
    }
    
    
    public func switchToViewControllerWithSegueIdentifier(identifier : String, segueCallback: ((UIStoryboardSegue) -> ())? = nil ) {
        segueCallbacks?[identifier] = segueCallback
        
        self.performSegue(withIdentifier: identifier, sender: nil)
    }
    
    private func printSetDefaultSegueError() {
        debugPrint("Please set the identifier of the default SwitchableSegue")
    }
}
