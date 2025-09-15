//
//  Async.swift
//
//  Created by Tobias DM on 15/07/14.
//
//	OS X 10.10+ and iOS 8.0+
//	Only use with ARC
//
//	The MIT License (MIT)
//	Copyright (c) 2014 Tobias Due Munk
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import Foundation

// HACK: For Swift 1.0

private class GCD {
    
    /* dispatch_get_queue() */
    class func mainQueue() -> DispatchQueue {
        return DispatchQueue.main
        // Could use return dispatch_get_global_queue(qos_class_main().id, 0)
    }
    class func userInteractiveQueue() -> DispatchQueue {
        return DispatchQueue.global(qos:.userInteractive)
    }
    class func userInitiatedQueue() -> DispatchQueue {
        return DispatchQueue.global(qos:.userInitiated)
    }
    class func defaultQueue() -> DispatchQueue {
        return DispatchQueue.global(qos:.default)
    }
    class func utilityQueue() -> DispatchQueue {
        return DispatchQueue.global(qos:.utility)
    }
    class func backgroundQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .background)
    }
}


public struct Async {
    
    private let block: DispatchWorkItem
    
    private init(_ block: DispatchWorkItem) {
        self.block = block
    }
}


extension Async { // Static methods
    
    
    /* dispatch_async() */
    
    private static func async(block: DispatchWorkItem, inQueue queue: DispatchQueue) -> Async {
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see matching regular Async methods)
        // Create block with the "inherit" type
        let _block = DispatchWorkItem(flags: .inheritQoS, block: block.perform)
        //let _block = DispatchWorkItem(flags: .inheritQoS, block: block)
        // Add block to queue
        queue.async(execute: _block)
        // Wrap block in a struct since DispatchWorkItem can't be extended
        return Async(_block)
    }
    static func main(block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: GCD.mainQueue())
    }
    static func userInteractive(block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: GCD.userInteractiveQueue())
    }
    static func userInitiated(block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: GCD.userInitiatedQueue())
    }
    static func default_(block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: GCD.defaultQueue())
    }
    static func utility(block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: GCD.utilityQueue())
    }
    static func background(block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: GCD.backgroundQueue())
    }
    static func customQueue(queue: DispatchQueue, block: DispatchWorkItem) -> Async {
        return Async.async(block: block, inQueue: queue)
    }
    
    
    /* dispatch_after() */
    
    private static func after(seconds: Double, block: DispatchWorkItem, inQueue queue: DispatchQueue) -> Async {
        let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
        let time : DispatchTime = .now() +  .nanoseconds(Int(nanoSeconds))
        return at(time: time, block: block, inQueue: queue)
    }
    private static func at(time: DispatchTime, block: DispatchWorkItem, inQueue queue: DispatchQueue) -> Async {
        // See Async.async() for comments
        let _block = DispatchWorkItem(flags: .inheritQoS, block: block.perform)
        queue.asyncAfter(deadline: time, execute: _block)
        return Async(_block)
    }
    static func main(after: Double, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: GCD.mainQueue())
    }
    static func userInteractive(after: Double, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: GCD.userInteractiveQueue())
    }
    static func userInitiated(after: Double, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: GCD.userInitiatedQueue())
    }
    static func default_(after: Double, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: GCD.defaultQueue())
    }
    static func utility(after: Double, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: GCD.utilityQueue())
    }
    static func background(after: Double, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: GCD.backgroundQueue())
    }
    static func customQueue(after: Double, queue: DispatchQueue, block: DispatchWorkItem) -> Async {
        return Async.after(seconds: after, block: block, inQueue: queue)
    }
}


extension Async { // Regualar methods matching static once
    
    
    /* dispatch_async() */
    
    private func chain(block chainingBlock: DispatchWorkItem, runInQueue queue: DispatchQueue) -> Async {
        // See Async.async() for comments
        let _chainingBlock = DispatchWorkItem(flags: .inheritQoS, block: chainingBlock.perform)
        self.block.notify(queue: queue, execute: _chainingBlock)
        return Async(_chainingBlock)
    }
    
    func main(chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
    }
    func userInteractive(chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.userInteractiveQueue())
    }
    func userInitiated(chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.userInitiatedQueue())
    }
    func default_(chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.defaultQueue())
    }
    func utility(chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.utilityQueue())
    }
    func background(chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.backgroundQueue())
    }
    func customQueue(queue: DispatchQueue, chainingBlock: DispatchWorkItem) -> Async {
        return chain(block: chainingBlock, runInQueue: queue)
    }
    
    
    /* dispatch_after() */
    
    private func after(seconds: Double, block chainingBlock: DispatchWorkItem, runInQueue queue: DispatchQueue) -> Async {
        
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
        // Create block with the "inherit" type
        let _chainingBlock = DispatchWorkItem(flags: .inheritQoS, block: chainingBlock.perform)
        
        // Wrap block to be called when previous block is finished
        let chainingWrapperBlock = DispatchWorkItem(block: {
            // Calculate time from now
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            //let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), nanoSeconds)
            queue.asyncAfter(deadline: .now() + .nanoseconds(Int(nanoSeconds)), execute: _chainingBlock)
        })
        // Create a new block (Qos Class) from block to allow adding a notification to it later (see Async)
        // Create block with the "inherit" type
        let _chainingWrapperBlock = DispatchWorkItem(flags: .inheritQoS, block: chainingWrapperBlock.perform)
        // Add block to queue *after* previous block is finished
        self.block.notify(queue: queue, execute: _chainingWrapperBlock.perform)
        // Wrap block in a struct since DispatchWorkItem can't be extended
        return Async(_chainingBlock)
    }
    func main(after: Double, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: GCD.mainQueue())
    }
    func userInteractive(after: Double, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: GCD.userInteractiveQueue())
    }
    func userInitiated(after: Double, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: GCD.userInitiatedQueue())
    }
    func default_(after: Double, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: GCD.defaultQueue())
    }
    func utility(after: Double, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: GCD.utilityQueue())
    }
    func background(after: Double, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: GCD.backgroundQueue())
    }
    func customQueue(after: Double, queue: DispatchQueue, block: DispatchWorkItem) -> Async {
        return self.after(seconds: after, block: block, runInQueue: queue)
    }
    
    
    /* cancel */
    
    func cancel() {
        block.cancel()
    }
    
    
    /* wait */
    
    /// If optional parameter forSeconds is not provided, use DISPATCH_TIME_FOREVER
    func wait(seconds: Double = 0.0) {
        if seconds != 0.0 {
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            let time : DispatchTime = .now() + .nanoseconds(Int(nanoSeconds))
            block.wait(timeout: time)
        } else {
            block.wait(timeout: .distantFuture)
        }
    }
}


// Convenience
