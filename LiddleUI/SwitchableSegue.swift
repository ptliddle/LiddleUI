//
//  SwitchableSegue.swift
//  Pods
//
//  Created by Peter Liddle on 12/16/15.
//
//

import UIKit

public class SwitchableSegue: UIStoryboardSegue {

    override public func perform() {
        //We want to do nothing when the segue is performed as we're actually embedding the VC into another view
    }

    public func setAction(object : AnyObject){
        print("This needs to be here or custom segues fail on iOS8.4")
    }
}
