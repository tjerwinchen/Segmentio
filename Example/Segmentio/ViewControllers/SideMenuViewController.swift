//
//  SideMenuViewController.swift
//  Segmentio
//
//  Created by Dmitriy Demchenko
//  Copyright © 2016 Yalantis Mobile. All rights reserved.
//

import UIKit
import Segmentio

typealias SideMenuHandler = ((style: SegmentioStyle) -> Void)

private let animationDuration: TimeInterval = 0.3
private let selectedCheckboxImage = UIImage(named: "selectedCheckbox")
private let defaultCheckboxImage = UIImage(named: "defaultCheckbox")

class SideMenuViewController: UIViewController {
    
    var sideMenuDidHide: SideMenuHandler?
    
    @IBOutlet private weak var shadowView: UIView!
    @IBOutlet private weak var menuTableView: UITableView!
    @IBOutlet private weak var menuTableViewWidthConstraint: NSLayoutConstraint!
    
    private var menuItems = SegmentioStyle.allStyles
    private var currentStyle = SegmentioStyle.OnlyImage
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTableView.isHidden = true
        view.isHidden = true
        menuTableViewWidthConstraint.constant = UIScreen.main().bounds.width * 0.7
        setupGestureRecognizers()
    }
    
    // MARK: - Public functions
    
    class func create() -> SideMenuViewController {
        let board = UIStoryboard(name: "Main", bundle: nil)
        return board.instantiateViewController(withIdentifier: String(self)) as! SideMenuViewController
    }
    
    func showSideMenu(_ viewController: UIViewController, currentStyle: SegmentioStyle, sideMenuDidHide: SideMenuHandler?) {
        self.currentStyle = currentStyle
        self.sideMenuDidHide = sideMenuDidHide
        self.modalPresentationStyle = .overCurrentContext
        let size = view.frame.size
        viewController.present(self, animated: false) { [weak self] in
            self?.view.isHidden = false
            self?.menuTableView.frame.origin = CGPoint(x: -size.width, y: 0)
            UIView.animate(
                withDuration: animationDuration,
                animations: {
                    self?.view.backgroundColor = UIColor.black().withAlphaComponent(0.63)
                    self?.slideAnimationToPoint(CGPoint.zero)
                    self?.menuTableView.isHidden = false
                }
            )
        }
    }
    
    // MARK: - Private functions
    
    private func setupGestureRecognizers() {
        let dissmisSideMenuSelector = #selector(SideMenuViewController.dissmisSideMenu)
        
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: dissmisSideMenuSelector
        )
        tapRecognizer.delegate = self
        shadowView.addGestureRecognizer(tapRecognizer)
        
        let swipeRecognizer = UISwipeGestureRecognizer(
            target: self,
            action: dissmisSideMenuSelector
        )
        swipeRecognizer.direction = .left
        swipeRecognizer.delegate = self
        view.addGestureRecognizer(swipeRecognizer)
    }
    
    private func didSelectItemAtIndexPath(_ indexPath: IndexPath) {
        currentStyle = SegmentioStyle.allStyles[indexPath.row]
        dissmisSideMenu()
    }
    
    @objc private func dissmisSideMenu() {
        let size = view.frame.size
        
        UIView.animate(
            withDuration: animationDuration,
            animations: {
                self.slideAnimationToPoint(CGPoint(x: -size.width, y: 0))
                self.view.backgroundColor = UIColor.clear()
            },
            completion: { _ in
                self.view.isHidden = true
                self.menuTableView.isHidden = true
                self.sideMenuDidHide?(style: self.currentStyle)
            }
        )
    }
    
    private func slideAnimationToPoint(_ point: CGPoint) {
        UIView.animate(withDuration: animationDuration) {
            self.menuTableView.frame.origin = point
        }
    }
    
    private func uncheckCurrentStyle() {
        guard let currentStyleIndex = menuItems.index(of: currentStyle) else {
            return
        }
        
        let activeIndexPath = IndexPath(
            row: currentStyleIndex,
            section: menuTableView.numberOfSections - 1
        )
        
        let activeCell = menuTableView.cellForRow(at: activeIndexPath)
        activeCell?.imageView?.image = defaultCheckboxImage
    }
    
}

extension SideMenuViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        let isCurrentStyle = currentStyle == menuItems[indexPath.row]
        
        cell!.textLabel?.text = menuItems[indexPath.row].rawValue.stringFromCamelCase()
        cell!.imageView?.image = isCurrentStyle ? selectedCheckboxImage : defaultCheckboxImage
        
        return cell!
    }
    
}

extension SideMenuViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        if currentStyle != menuItems[indexPath.row] {
            uncheckCurrentStyle()
            cell?.imageView?.image = selectedCheckboxImage
        }
        didSelectItemAtIndexPath(indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
}

extension SideMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
