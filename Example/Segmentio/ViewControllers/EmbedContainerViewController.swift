//
//  EmbedContainerViewController.swift
//  Segmentio
//
//  Created by Dmitriy Demchenko
//  Copyright © 2016 Yalantis Mobile. All rights reserved.
//

import UIKit
import Segmentio

private let animateDuration: TimeInterval = 0.6

class EmbedContainerViewController: UIViewController {
    
    var style = SegmentioStyle.OnlyImage
    
    private var currentViewController: UIViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentController(controller(style))
    }
    
    // MARK: - Private functions
    
    private func presentController(_ controller: UIViewController) {
        if let _ = currentViewController {
            removeCurrentViewController()
        }
        
        addChildViewController(controller)
        view.addSubview(controller.view)
        currentViewController = controller
        controller.didMove(toParentViewController: self)
    }
    
    private func controller(_ style: SegmentioStyle) -> ExampleViewController {
        let controller = ExampleViewController.create()
        controller.segmentioStyle = style
        controller.view.frame = view.bounds
        return controller
    }
    
    private func removeCurrentViewController() {
        currentViewController?.willMove(toParentViewController: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParentViewController()
    }
    
    private func swapCurrentController(_ controller: UIViewController) {
        currentViewController?.willMove(toParentViewController: nil)
        addChildViewController(controller)
        view.addSubview(controller.view)
        
        UIView.animate(
            withDuration: animateDuration,
            animations: {
                controller.view.alpha = 1
                self.currentViewController?.view.alpha = 0
            },
            completion: { _ in
                self.currentViewController?.view.removeFromSuperview()
                self.currentViewController?.removeFromParentViewController()
                self.currentViewController = controller
                self.currentViewController?.didMove(toParentViewController: self)
            }
        )
    }
    
    // MARK: - Public functions
    
    func swapViewControllers(_ style: SegmentioStyle) {
        swapCurrentController(controller(style))
    }
    
}
