//
//  ViewController.swift
//  UIScrollViewDemo
//
//  Created by Simon Gladman on 28/09/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//
// With help from: 
//
//  http://www.raywenderlich.com/76436/use-uiscrollview-scroll-zoom-content-swift
//  http://www.rockhoppertech.com/blog/swift-dragging-a-uiview-with-snap/

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate, UIToolbarDelegate
{
    let scrollView = UIScrollView(frame: CGRectZero)
    let backgroundControl = BackgroundControl(frame: CGRect(x: 0, y: 0, width: 6000, height: 6000))
    let toolbar = Toolbar(frame: CGRectZero)
    let menuButton = MenuButton(frame: CGRectZero)
  
    override func viewDidLoad()
    {        
        super.viewDidLoad()
   
        createScrollView()
        
        createToolbar()
        
        menuButton.layer.shadowColor = UIColor.black.cgColor
        menuButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuButton.layer.shadowOpacity = 1
        view.addSubview(menuButton)
        
        view.backgroundColor = UIColor.darkGray
        
        NodesPM.addObserver(observer: self, selector: #selector(draggingChangedHandler), notificationType: .DraggingChanged)
        NodesPM.addObserver(observer: self, selector: #selector(relationshipCreationModeChanged), notificationType: .RelationshipCreationModeChanged)
        
        scrollView.contentOffset = CGPoint(x: 500, y: 500)
    }

    func createScrollView()
    {
        view.addSubview(scrollView)
        scrollView.addSubview(backgroundControl)
        
        scrollView.contentSize = backgroundControl.frame.size;
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 2
        scrollView.zoomScale = 1
    
        scrollView.delegate = self
        
        scrollView.frame = CGRect(x: 0, y: topLayoutGuide.length, width: view.frame.width, height: view.frame.height - topLayoutGuide.length)
    }
    
    func createToolbar()
    {
        toolbar.layer.shadowColor = UIColor.black.cgColor
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 0)
        toolbar.layer.shadowOpacity = 1
        
        view.addSubview(toolbar)
    }
    
    @objc func relationshipCreationModeChanged()
    {
        scrollView.isScrollEnabled = !NodesPM.relationshipCreationMode
    }
    
    @objc func draggingChangedHandler(value: AnyObject)
    {
        let isDragging = value.object as! Bool
        
        scrollView.isScrollEnabled = !isDragging
    }
    
    private func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        NodesPM.contentOffset = scrollView.contentOffset
    }
    
    private func scrollViewDidZoom(_ scrollView: UIScrollView)
    {
        NodesPM.zoomScale = scrollView.zoomScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
    {
        return backgroundControl
    }

    override func viewDidLayoutSubviews()
    {
        menuButton.frame = CGRect(x: 5, y: topLayoutGuide.length + 5, width: 70, height: 40)
        
        toolbar.frame = CGRect(x: 0, y: view.frame.height - 80, width: view.frame.width, height: 80)
        
        scrollView.frame = CGRect(x: 0, y: topLayoutGuide.length, width: view.frame.width, height: view.frame.height - topLayoutGuide.length)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.landscape
    }
}

