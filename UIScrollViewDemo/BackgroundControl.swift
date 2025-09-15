//
//  BackgroundControl.swift
//  UIScrollViewDemo
//
//  Created by Simon Gladman on 28/09/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

class BackgroundControl: UIControl
{
    let backgroundLayer = BackgroundGrid()
    let curvesLayer = RelationshipCurvesLayer()

    var nodeWidgetPendingDelete: NodeWidget?
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)

        backgroundColor = NodeConstants.backgroundColor
        
        backgroundLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(backgroundLayer)
        
        backgroundLayer.frame = bounds.insetBy(dx: 0, dy: 0)
        backgroundLayer.drawGrid()
        
        curvesLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(curvesLayer)
        curvesLayer.frame = bounds.insetBy(dx: 0, dy: 0)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longHoldHandler))
        addGestureRecognizer(longPress)
        
        addTarget(self, action: #selector(backgroundPress), for: UIControlEvents.touchUpInside)
        
        NodesPM.addObserver(observer: self, selector: #selector(nodeCreated), notificationType: .NodeCreated)
        NodesPM.addObserver(observer: self, selector: #selector(renderRelationships), notificationType: .RelationshipsChanged)
        NodesPM.addObserver(observer: self, selector: #selector(renderRelationships), notificationType: .NodesMoved)
        NodesPM.addObserver(observer: self, selector: #selector(nodeDeleted), notificationType: .NodeDeleted)
        NodesPM.addObserver(observer: self, selector: #selector(relationshipCreationModeChanged), notificationType: NodeNotificationTypes.RelationshipCreationModeChanged)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
    }
    
    @objc func relationshipCreationModeChanged()
    {
        let targetColor = NodesPM.relationshipCreationMode ? UIColor.darkGray : NodeConstants.backgroundColor
        
        UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.backgroundColor = targetColor})
    }
    
    @objc func backgroundPress()
    {
        NodesPM.relationshipCreationMode = false
    }
    
    @objc func longHoldHandler(recognizer: UILongPressGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.began
        {
            let gestureLocation = recognizer.location(in: self)
            
            if self.hitTest(gestureLocation, with: nil) is BackgroundControl
            {
                let widgetHeight = CGFloat(NodeConstants.WidgetRowHeight * 2)
                
                NodesPM.createNewNode(origin: CGPoint(x: gestureLocation.x - NodeConstants.WidgetWidthCGFloat / 2, y: gestureLocation.y - widgetHeight / 2))
            }
        }
    }
    
    @objc func nodeDeleted(value: AnyObject)
    {
        let deletedNode = value.object as! NodeVO
        
        for (idx, widget) in subviews.enumerated()
        {
            if widget is NodeWidget && (widget as! NodeWidget).node == deletedNode
            {
                nodeWidgetPendingDelete = widget as? NodeWidget
                
                UIView.animate(withDuration: NodeConstants.animationDuration, animations: {self.nodeWidgetPendingDelete!.alpha = 0}, completion: deleteAnimationComplete)
            }
        }
    }
    
    func deleteAnimationComplete(value: Bool)
    {
        if (value && nodeWidgetPendingDelete != nil)
        {
            nodeWidgetPendingDelete?.removeFromSuperview()
            nodeWidgetPendingDelete = nil
        }
    }
    
    @objc func renderRelationships()
    {
        curvesLayer.redrawRelationshipCurves()
    }
    
    @objc func nodeCreated(value : AnyObject)
    {
        let newNode = value.object as! NodeVO
        
        let originX = Int( newNode.position.x )
        let originY = Int( newNode.position.y )
        
        let widgetHeight = newNode.getInputCount() * NodeConstants.WidgetRowHeight + (NodeConstants.WidgetRowHeight * 2)
        
        let nodeWidget = NodeWidget(frame: CGRect(x: originX, y: originY, width: NodeConstants.WidgetWidthInt, height: widgetHeight), node: newNode)
        
        addSubview(nodeWidget)
    }
}
