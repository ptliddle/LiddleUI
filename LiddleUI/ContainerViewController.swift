//
//  ContainerViewController.swift
//  XMarksTheSpot
//
//  Created by Peter Liddle on 4/3/15.
//  Copyright (c) 2015 LiddSoft. All rights reserved.
//

import UIKit
import Foundation

class ContainerViewController : UIViewController {
    
    var currentViewSegue : String?
    var currentController : UIViewController?
    var closureName: ((_ container : UIViewController, _ fromVC : UIViewController, _ toVC : UIViewController) -> Void)?
    var serialTransitionQueue : DispatchQueue
    
    var firstVC : UIViewController?
    var secondVC : UIViewController?
    
    required init?(coder aDecoder: NSCoder) {
        self.serialTransitionQueue = DispatchQueue(label: "com.EmbeddedSwapping.queue");
        super.init(coder: aDecoder);
        
        closureName = { (container : UIViewController, fromVC : UIViewController, toVC : UIViewController) in
            
            fromVC.view.removeFromSuperview()
            fromVC.removeFromParentViewController()
            
            container.view.addSubview(toVC.view)
            toVC.didMove(toParentViewController: container)
            self.currentController = toVC
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC : UIViewController = segue.destination
        let destinationView : UIView = destinationVC.view
        
        if let cc = currentController {
            self.moveFromViewController(from: cc, to: destinationVC)
        }
        else {
            destinationVC.willMove(toParentViewController: self)
            self.addChildViewController(destinationVC as UIViewController)
            self.view.addSubview(destinationView)
            destinationVC.didMove(toParentViewController:self)
        }
        
        self.currentController = destinationVC
        self.currentViewSegue = segue.identifier
    }
    
    
    func moveFromViewController(from : UIViewController, to : UIViewController){
        serialTransitionQueue.sync {
            DispatchQueue.main.sync {
                to.willMove(toParentViewController: self)
                to.view?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                self.addChildViewController(to)
                self.closureName!(self, from, to)
            }
        }
        
        
//        dispatch_async(serialTransitionQueue, { () -> Void in
//            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
//                to.willMoveToParentViewController(self)
//                to.view?.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
//                self.addChildViewController(to)
//                self.closureName!(container:self, fromVC:from, toVC:to)
//                //TODO - add animation block
//            })
//        })
    }
}
