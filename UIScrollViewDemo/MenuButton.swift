//
//  MenuButton.swift
//  UIScrollViewDemo
//
//  Created by Simon Gladman on 06/10/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import Foundation
import UIKit

class MenuButton: UIButton
{
    var alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
    
    let deleteAlertAction: UIAlertAction
    let makeNumericAction: UIAlertAction
    let makeOperatorAction: UIAlertAction
    
    override init(frame: CGRect)
    {
        func changeNodeType(value : UIAlertAction!) -> Void
        {
            NodesPM.changeSelectedNodeType(newType: NodeTypes(rawValue: value.title ?? "???")!)
        }
        
        func deleteSelectedNode(value : UIAlertAction!) -> Void
        {
            NodesPM.deleteSelectedNode()
        }
        
        makeOperatorAction = UIAlertAction(title: NodeTypes.Operator.rawValue, style: UIAlertActionStyle.default, handler: changeNodeType)
        makeNumericAction = UIAlertAction(title: NodeTypes.Number.rawValue, style: UIAlertActionStyle.default, handler: changeNodeType)
        deleteAlertAction = UIAlertAction(title: "Delete Selected Node", style: UIAlertActionStyle.default, handler: deleteSelectedNode)
        
        deleteAlertAction.isEnabled = false
        makeNumericAction.isEnabled = false
        makeOperatorAction.isEnabled = false
        
        alertController.addAction(deleteAlertAction)
        alertController.addAction(makeNumericAction)
        alertController.addAction(makeOperatorAction)
        
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview()
    {
        setTitle("Menu", for: UIControlState.normal)
        
        tintColor = UIColor.blue
        
        layer.borderWidth = 1
        layer.cornerRadius = 5
        layer.backgroundColor = UIColor.blue.cgColor
        layer.borderColor = UIColor.white.cgColor
        
        NodesPM.addObserver(observer: self, selector: #selector(selectedNodeChanged), notificationType: NodeNotificationTypes.NodeSelected)
        NodesPM.addObserver(observer: self, selector: #selector(selectedNodeChanged), notificationType: NodeNotificationTypes.NodeUpdated)
    }
    
    @objc func selectedNodeChanged(value: AnyObject)
    {
        if let selectedNode = NodesPM.selectedNode
        {
            deleteAlertAction.isEnabled = true
            makeNumericAction.isEnabled = selectedNode.nodeType == NodeTypes.Operator
            makeOperatorAction.isEnabled = selectedNode.nodeType == NodeTypes.Number
        }
        else
        {
            deleteAlertAction.isEnabled = false
            makeNumericAction.isEnabled = false
            makeOperatorAction.isEnabled = false
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let viewController = UIApplication.shared.keyWindow!.rootViewController
        {
            if let popoverPresentationController = alertController.popoverPresentationController
            {
                popoverPresentationController.sourceRect = frame
                popoverPresentationController.sourceView = viewController.view
                
                viewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}
