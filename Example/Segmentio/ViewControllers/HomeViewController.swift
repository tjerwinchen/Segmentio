//
//  HomeViewController.swift
//  Segmentio
//
//  Created by Dmitriy Demchenko
//  Copyright © 2016 Yalantis Mobile. All rights reserved.
//

import UIKit
import Segmentio

class HomeViewController: UIViewController {
    
    private var currentStyle = SegmentioStyle.OnlyImage
    private var containerViewController: EmbedContainerViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: AnyObject?) -> Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == String(EmbedContainerViewController.self) {
            containerViewController = segue.destinationViewController as? EmbedContainerViewController
            containerViewController?.style = currentStyle
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func showMenu(_ sender: UIBarButtonItem) {
        SideMenuViewController.create().showSideMenu(
            self,
            currentStyle: currentStyle,
            sideMenuDidHide: { [weak self] style in
                self?.dismiss(
                    animated: false,
                    completion: {
                        if self?.currentStyle != style {
                            self?.currentStyle = style
                            self?.containerViewController?.swapViewControllers(style)
                        }
                    }
                )
            }
        )
    }
    
}
