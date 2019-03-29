//
//  ContainerViewController.swift
//  XMarksTheSpot
//
//  Created by Peter Liddle on 4/3/15.
//  Copyright (c) 2015 LiddSoft. All rights reserved.
//

import UIKit
import Foundation

open class ContainerViewController : UIViewController {
    
    var currentViewSegue : String?
    var currentController : UIViewController?
    var completedTransitionClosure: ((_ container : UIViewController, _ fromVC : UIViewController, _ toVC : UIViewController) -> Void)?
    var serialTransitionQueue : DispatchQueue
    
    var firstVC : UIViewController?
    var secondVC : UIViewController?
    
    public required init?(coder aDecoder: NSCoder) {
        self.serialTransitionQueue = DispatchQueue(label: "com.EmbeddedSwapping.queue");
        super.init(coder: aDecoder);
        
        completedTransitionClosure = { (container : UIViewController, fromVC : UIViewController, toVC : UIViewController) in
            
            fromVC.view.removeFromSuperview()
            fromVC.removeFromParent()
            
            container.view.addSubview(toVC.view)
            toVC.didMove(toParent: container)
            self.currentController = toVC
        }
    }
    
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC : UIViewController = segue.destination
        let destinationView : UIView = destinationVC.view
        
        if let cc = currentController {
            self.moveFromViewController(from: cc, to: destinationVC)
        }
        else {
            destinationVC.willMove(toParent: self)
            self.addChild(destinationVC as UIViewController)
            self.view.addSubview(destinationView)
            destinationVC.didMove(toParent:self)
        }
        
        self.currentController = destinationVC
        self.currentViewSegue = segue.identifier
    }
    
    
    func moveFromViewController(from : UIViewController, to : UIViewController){
        DispatchQueue.main.async {
            to.willMove(toParent: self)
            to.view?.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: self.view.frame.height))
            self.addChild(to)
            self.completedTransitionClosure?(self, from, to)
        }
    }
}
