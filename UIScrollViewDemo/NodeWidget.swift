//
//  Node.swift
//  UIScrollViewDemo
//
//  Created by Simon Gladman on 28/09/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

class NodeWidget: UIControl, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate
{
    var node: NodeVO!
    
    let operatorLabel = UILabel(frame: CGRectZero)
    let outputLabel = UILabel(frame: CGRectZero)
    let colorSwatch = UIControl(frame: CGRectZero)
    
    var previousPanPoint = CGPointZero
    var inputLabels = [UILabel]()
    
    required init(frame: CGRect, node: NodeVO)
    {
        super.init(frame: frame)
        
        self.node = node
        
        self.clipsToBounds = true
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    deinit
    {
        NodesPM.removeObserver(observer: self)
    }
    
    override func didMoveToSuperview()
    {
        alpha = 0

        layer.borderColor = NodeConstants.curveColor.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 10
        
        setUpPersistentLabels()
        populateLabels()
        addSubview(operatorLabel)
        addSubview(outputLabel)
        addSubview(colorSwatch)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        pan.delegate = self
        addGestureRecognizer(pan)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longHoldHandler))
        addGestureRecognizer(longPress)
     
        NodesPM.addObserver(observer: self, selector: #selector(nodeUpdated), notificationType: .NodeUpdated)
        NodesPM.addObserver(observer: self, selector: #selector(nodeSelected), notificationType: .NodeSelected)
        NodesPM.addObserver(observer: self, selector: #selector(nodeUpdated), notificationType: .NodeCreated)
        NodesPM.addObserver(observer: self, selector: #selector(relationshipCreationModeChanged), notificationType: .RelationshipCreationModeChanged)
        NodesPM.addObserver(observer: self, selector: #selector(relationshipsChanged), notificationType: .RelationshipsChanged)
        
        UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.alpha = 1}, completion: fadeInComplete)
    }
    
    func setUpPersistentLabels()
    {
        operatorLabel.textAlignment = NSTextAlignment.center
        operatorLabel.layer.backgroundColor = UIColor.white.cgColor
        operatorLabel.alpha = 0.75
        operatorLabel.layer.cornerRadius = 5
        operatorLabel.textColor = UIColor.blue
        operatorLabel.font = UIFont.boldSystemFont(ofSize: 20)
        operatorLabel.adjustsFontSizeToFitWidth = true
        
        outputLabel.textAlignment = NSTextAlignment.right
        outputLabel.textColor = UIColor.white
        outputLabel.font = UIFont.boldSystemFont(ofSize: 20)
        outputLabel.adjustsFontSizeToFitWidth = true
        
        colorSwatch.layer.borderColor = UIColor.blue.cgColor
        colorSwatch.layer.cornerRadius = 10
        colorSwatch.layer.borderWidth = 2
    }
    
    func fadeInComplete(value: Bool)
    {
        if value
        {
            frame.offsetBy(dx: 0, dy: 0);
            
            NodesPM.moveSelectedNode(position: CGPoint(x: frame.origin.x, y: frame.origin.y))
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
    
    
    // to do - move to PM and prevent circular relationships
    var relationshipCreationCandidate: Bool = false
    {
        didSet
        {
            if NodesPM.relationshipCreationMode
            {
                if relationshipCreationCandidate && !(NodesPM.selectedNode! == node)
                {
                    enableLabelsAsButtons()
                }
                else
                {
                    UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.alpha = 0.5})
                    isEnabled = false
                }
            }
            else
            {
                UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.alpha = 1.0})
                isEnabled = true
            
                enableLabelsAsButtons()
                setWidgetColors()
            }
        }
    }
    
    func enableLabelsAsButtons()
    {
        for (idx, inputLabel) in inputLabels.enumerated()
        {
            if relationshipCreationCandidate && NodesPM.relationshipCreationMode
            {
                let isValidInput = node.getInputTypes()[idx] == NodesPM.selectedNode?.getOutputType()
                
                inputLabel.isEnabled = isValidInput
                
                inputLabel.textColor = UIColor.blue
                inputLabel.layer.borderWidth = 1
                inputLabel.layer.cornerRadius = 5
                inputLabel.layer.borderColor = UIColor.blue.cgColor
                inputLabel.layer.backgroundColor = isValidInput ? UIColor.yellow.cgColor : UIColor(red: 0.75, green: 0.75, blue: 0.0, alpha: 1.0).cgColor
            }
            else
            {
                inputLabel.isEnabled = true
                
                inputLabel.textColor = UIColor.white
                inputLabel.layer.borderWidth = 0
                inputLabel.layer.backgroundColor = UIColor.clear.cgColor
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        
        if NodesPM.relationshipCreationMode && relationshipCreationCandidate
        {
            if NodesPM.zoomScale > 0.75
            {
                var targetIndex = -1
                let touch: UITouch = touches.first!
                
                for (i, inputLabel) in inputLabels.enumerated()
                {
                    let touchLocationInView = touch.location(in: inputLabel)
                    
                    if inputLabel.isEnabled && touchLocationInView.x > 0 && touchLocationInView.y > 0 && touchLocationInView.x < inputLabel.frame.width && touchLocationInView.y < inputLabel.frame.height
                    {
                        targetIndex = i
                    }
                }
                
                if targetIndex != -1
                {
                    NodesPM.preferredInputIndex = targetIndex
                    NodesPM.selectedNode = node
                }
                else
                {
                    NodesPM.relationshipCreationMode = false
                }
            }
            else
            {
                displayInputSelectPopOver()
            }
        }
        else if !NodesPM.relationshipCreationMode
        {
            NodesPM.selectedNode = node
            NodesPM.isDragging = true
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        NodesPM.isDragging = false
    }
    
    @objc func relationshipCreationModeChanged(value : AnyObject)
    {
        _ = value.object as! Bool
        
        relationshipCreationCandidate = node.nodeType == NodeTypes.Operator
    }
    
    @objc func relationshipsChanged(value: AnyObject)
    {
        populateLabels()
    }

    var targetHeight: CGFloat = 0
    
    @objc func nodeUpdated(value: AnyObject)
    {
        let updatedNode = value.object as! NodeVO
        
        if updatedNode == node
        {
            targetHeight = CGFloat(node.getInputCount() * NodeConstants.WidgetRowHeight + (NodeConstants.WidgetRowHeight * 2))
            
            if targetHeight != frame.size.height
            {
                NodesPM.resizingNode = node
            
                UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.doResize()}, completion: resizeComplete)
            }
            
            populateLabels()
        }
    }
    
    func doResize()
    {
        frame.size.height = targetHeight
        populateLabels()
    }
    
    func resizeComplete(value: Bool)
    {
        NodesPM.resizingNode = nil
    }
    
    func displayInputSelectPopOver()
    {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertController.message = "Select Input Channel"
        alertController.popoverPresentationController?.delegate = self
        
        func inputSelectHandler(value : UIAlertAction!) -> Void
        {
            var targetIndex: Int = -1
            
            for (idx, action) in alertController.actions.enumerated()
            {
                if action === value
                {
                    targetIndex = idx
                }
            }
            
            if targetIndex != -1
            {
                NodesPM.preferredInputIndex = targetIndex
                NodesPM.selectedNode = node
            }
            else
            {
                NodesPM.relationshipCreationMode = false
            }
        }
        
        for i: Int in 0 ..< node.getInputCount()
        {
            let style = node.inputNodes[i] == nil ? UIAlertActionStyle.default : UIAlertActionStyle.destructive
            
            let inputSelectAction = UIAlertAction(title: node.getInputLabelOfIndex(idx: i), style: style, handler: inputSelectHandler)
            
            let isValidInput = node.getInputTypes()[i] == NodesPM.selectedNode?.getOutputType()
            inputSelectAction.isEnabled = isValidInput
            
            alertController.addAction(inputSelectAction)
        }
        
        if let viewController = UIApplication.shared.keyWindow!.rootViewController
        {
            if let popoverPresentationController = alertController.popoverPresentationController
            {
                popoverPresentationController.sourceRect = CGRect(x: frame.origin.x * NodesPM.zoomScale - NodesPM.contentOffset.x, y: frame.origin.y * NodesPM.zoomScale - NodesPM.contentOffset.y, width: frame.width * NodesPM.zoomScale, height: frame.height * NodesPM.zoomScale)
                popoverPresentationController.sourceView = viewController.view
                
                
                
                viewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController)
    {
         NodesPM.relationshipCreationMode = false
    }
    
    func populateLabels()
    {
        if inputLabels.count != node.getInputCount()
        {
            for oldLabel in inputLabels
            {
                oldLabel.removeFromSuperview()
            }
            
            inputLabels = [UILabel]()
            
            for i in 0..<node.getInputCount()
            {
                let label = UILabel(frame: CGRect(x: 0, y: i * NodeConstants.WidgetRowHeight + NodeConstants.WidgetRowHeight, width: Int(frame.width), height: NodeConstants.WidgetRowHeight).insetBy(dx: 5, dy: 2))
                
                label.textColor = UIColor.white
                label.font = UIFont.boldSystemFont(ofSize: 20)
                label.adjustsFontSizeToFitWidth = true
                
                addSubview(label)
                inputLabels.append(label)
            }
        }
        
        for i in 0..<node.getInputCount()
        {
            let label = inputLabels[i]
            
            label.text = node.getInputLabelOfIndex(idx: i)
        }
        
        if node.nodeType == NodeTypes.Operator && node.getOutputType() == InputOutputTypes.Color
        {
            colorSwatch.frame = CGRect(x: 0, y: NodeConstants.WidgetRowHeight + node.getInputCount() * NodeConstants.WidgetRowHeight, width: NodeConstants.WidgetRowHeight * 2, height: NodeConstants.WidgetRowHeight)
            colorSwatch.alpha = 1
            colorSwatch.backgroundColor = node.colorValue
        }
        else
        {
            colorSwatch.alpha = 0
        }
        
        
        operatorLabel.frame = CGRect(x: 2, y: 0, width: Int(frame.width - 4), height: NodeConstants.WidgetRowHeight)
        operatorLabel.text = node.nodeType == NodeTypes.Operator ? node.nodeOperator.rawValue : node.nodeType.rawValue
        
        outputLabel.frame = CGRect(x: 0, y: NodeConstants.WidgetRowHeight + node.getInputCount() * NodeConstants.WidgetRowHeight, width: Int(frame.width) - 5, height: NodeConstants.WidgetRowHeight)
        outputLabel.textAlignment = NSTextAlignment.right
        outputLabel.adjustsFontSizeToFitWidth = true
        
        outputLabel.text = node.getOutputLabel()
    }
   
    @objc func nodeSelected(value: AnyObject?)
    {
        setWidgetColors()
    }
    
    func setWidgetColors()
    {
        var isSelected = !(NodesPM.selectedNode == nil)
        
        if isSelected
        {
            isSelected = NodesPM.selectedNode! == node 
        }
        
        let targetColor = isSelected ? NodeConstants.selectedNodeColor : NodeConstants.unselectedNodeColor
        
        UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.backgroundColor = targetColor})
    }
    
    @objc func longHoldHandler(recognizer: UILongPressGestureRecognizer)
    {
        NodesPM.relationshipCreationMode = true
    }
    
    @objc func panHandler(recognizer: UIPanGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.began
        {
            if !(NodesPM.selectedNode! == node)
            {
                NodesPM.selectedNode = node
            }
            
            previousPanPoint = recognizer.location(in: UIApplication.shared.keyWindow)
            
            NodesPM.isDragging = true
        }
        else if recognizer.state == UIGestureRecognizerState.changed || recognizer.state == UIGestureRecognizerState.ended
        {
            let gestureLocation = recognizer.location(in: UIApplication.shared.keyWindow)
            
            let deltaX = (gestureLocation.x - previousPanPoint.x) / NodesPM.zoomScale
            let deltaY = (gestureLocation.y - previousPanPoint.y) / NodesPM.zoomScale
            
            let newPosition = CGPoint(x: frame.origin.x + deltaX, y: frame.origin.y + deltaY)
            
            frame.origin.x = newPosition.x
            frame.origin.y = newPosition.y
            
            NodesPM.moveSelectedNode(position: CGPoint(x: newPosition.x, y: newPosition.y))
            
            previousPanPoint = recognizer.location(in: UIApplication.shared.keyWindow)
            
            if recognizer.state == UIGestureRecognizerState.ended
            {
                NodesPM.isDragging = false
            }
        }
    }
    
}
