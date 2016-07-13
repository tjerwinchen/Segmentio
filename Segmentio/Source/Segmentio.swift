//
//  Segmentio.swift
//  Segmentio
//
//  Created by Dmitriy Demchenko
//  Copyright © 2016 Yalantis Mobile. All rights reserved.
//

import UIKit
import QuartzCore

public typealias SegmentioSelectionCallback = ((segmentio: Segmentio, selectedSegmentioIndex: Int) -> Void)

private let animationDuration: CFTimeInterval = 0.3

public class Segmentio: UIView {
    
    internal struct Points {
        var startPoint: CGPoint
        var endPoint: CGPoint
    }
    
    internal struct Context {
        var isFirstCell: Bool
        var isLastCell: Bool
        var isLastOrPrelastVisibleCell: Bool
        var isFirstOrSecondVisibleCell: Bool
        var isFirstIndex: Bool
    }
    
    internal struct ItemInSuperview {
        var collectionViewWidth: CGFloat
        var cellFrameInSuperview: CGRect
        var shapeLayerWidth: CGFloat
        var startX: CGFloat
        var endX: CGFloat
    }
    
    public var valueDidChange: SegmentioSelectionCallback?
    public var selectedSegmentioIndex = -1 {
        didSet {
            if selectedSegmentioIndex != oldValue {
                reloadSegmentio()
                valueDidChange?(segmentio: self, selectedSegmentioIndex: selectedSegmentioIndex)
            }
        }
    }
    
    private var segmentioCollectionView: UICollectionView?
    private var segmentioItems = [SegmentioItem]()
    private var segmentioOptions = SegmentioOptions()
    private var segmentioStyle = SegmentioStyle.ImageOverLabel
    private var isPerformingScrollAnimation = false
    
    private var topSeparatorView: UIView?
    private var bottomSeparatorView: UIView?
    private var indicatorLayer: CAShapeLayer?
    private var selectedLayer: CAShapeLayer?
    
    private var cachedOrientation: UIInterfaceOrientation? = UIApplication.shared().statusBarOrientation {
        didSet {
            if cachedOrientation != oldValue {
                reloadSegmentio()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        setupSegmentedCollectionView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(Segmentio.handleOrientationNotification),
            name: NSNotification.Name.UIDeviceOrientationDidChange,
            object: nil
        )
    }
    
    private func setupSegmentedCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsZero
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(
            frame: frameForSegmentCollectionView(),
            collectionViewLayout: layout
        )
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = true
        collectionView.isScrollEnabled = segmentioOptions.scrollEnabled
        collectionView.backgroundColor = UIColor.clear()
        
        segmentioCollectionView = collectionView
        
        if let segmentioCollectionView = segmentioCollectionView {
            addSubview(segmentioCollectionView, options: .Overlay)
        }
    }
    
    private func frameForSegmentCollectionView() -> CGRect {
        var separatorsHeight: CGFloat = 0
        var collectionViewFrameMinY: CGFloat = 0
        
        if let horizontalSeparatorOptions = segmentioOptions.horizontalSeparatorOptions {
            let separatorHeight = horizontalSeparatorOptions.height
            
            switch horizontalSeparatorOptions.type {
            case .top:
                collectionViewFrameMinY = separatorHeight
                separatorsHeight = separatorHeight
            case .bottom:
                separatorsHeight = separatorHeight
            case .topAndBottom:
                collectionViewFrameMinY = separatorHeight
                separatorsHeight = separatorHeight * 2
            }
        }
        
        return CGRect(
            x: 0,
            y: collectionViewFrameMinY,
            width: bounds.width,
            height: bounds.height - separatorsHeight
        )
    }
    
    // MARK: - Handle orientation notification
    
    @objc private func handleOrientationNotification() {
         cachedOrientation = UIApplication.shared().statusBarOrientation
    }
    
    // MARK: - Setups:
    // MARK: Main setup
    
    public func setup(content: [SegmentioItem], style: SegmentioStyle, options: SegmentioOptions?) {
        segmentioItems = content
        segmentioStyle = style
        
        selectedLayer?.removeFromSuperlayer()
        indicatorLayer?.removeFromSuperlayer()
        
        if let options = options {
            segmentioOptions = options
            segmentioCollectionView?.isScrollEnabled = segmentioOptions.scrollEnabled
            backgroundColor = options.backgroundColor
        }
        
        if segmentioOptions.states.selectedState.backgroundColor != UIColor.clear() {
            selectedLayer = CAShapeLayer()
            if let selectedLayer = selectedLayer, sublayer = segmentioCollectionView?.layer {
                setupShapeLayer(
                    shapeLayer: selectedLayer,
                    backgroundColor: segmentioOptions.states.selectedState.backgroundColor,
                    height: bounds.height,
                    sublayer: sublayer
                )
            }
        }
        
        if let indicatorOptions = segmentioOptions.indicatorOptions {
            indicatorLayer = CAShapeLayer()
            if let indicatorLayer = indicatorLayer {
                setupShapeLayer(
                    shapeLayer: indicatorLayer,
                    backgroundColor: indicatorOptions.color,
                    height: indicatorOptions.height,
                    sublayer: layer
                )
            }
        }
        
        if let _ = segmentioOptions.horizontalSeparatorOptions {
            setupHorizontalSeparator()
        }
        
        setupCellWithStyle(segmentioStyle)
        segmentioCollectionView?.reloadData()
    }
    
    // MARK: Collection view setup
    
    private func setupCellWithStyle(_ style: SegmentioStyle) {
        var cellClass: SegmentioCell.Type {
            switch style {
            case .OnlyLabel:
                return SegmentioCellWithLabel.self
            case .OnlyImage:
                return SegmentioCellWithImage.self
            case .ImageOverLabel:
                return SegmentioCellWithImageOverLabel.self
            case .ImageUnderLabel:
                return SegmentioCellWithImageUnderLabel.self
            case .ImageBeforeLabel:
                return SegmentioCellWithImageBeforeLabel.self
            case .ImageAfterLabel:
                return SegmentioCellWithImageAfterLabel.self
            }
        }
        
        segmentioCollectionView?.register(
            cellClass,
            forCellWithReuseIdentifier: segmentioStyle.rawValue
        )
        
        segmentioCollectionView?.layoutIfNeeded()
    }
    
    // MARK: Horizontal separators setup
    
    private func setupHorizontalSeparator() {
        topSeparatorView?.removeFromSuperview()
        bottomSeparatorView?.removeFromSuperview()
        
        guard let horizontalSeparatorOptions = segmentioOptions.horizontalSeparatorOptions else {
            return
        }
        
        let height = horizontalSeparatorOptions.height
        let type = horizontalSeparatorOptions.type
        
        if type == .top || type == .topAndBottom {
            topSeparatorView = UIView(frame: CGRect.zero)
            setupConstraintsForSeparatorView(
                separatorView: topSeparatorView,
                originY: 0
            )
        }
        
        if type == .bottom || type == .topAndBottom {
            bottomSeparatorView = UIView(frame: CGRect.zero)
            setupConstraintsForSeparatorView(
                separatorView: bottomSeparatorView,
                originY: frame.maxY - height
            )
        }
    }
    
    private func setupConstraintsForSeparatorView(separatorView: UIView?, originY: CGFloat) {
        guard let horizontalSeparatorOptions = segmentioOptions.horizontalSeparatorOptions, separatorView = separatorView else {
            return
        }
        
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = horizontalSeparatorOptions.color
        addSubview(separatorView)
        
        let topConstraint = NSLayoutConstraint(
            item: separatorView,
            attribute: .top,
            relatedBy: .equal,
            toItem: superview,
            attribute: .top,
            multiplier: 1,
            constant: originY
        )
        topConstraint.isActive = true
        
        let leadingConstraint = NSLayoutConstraint(
            item: separatorView,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self,
            attribute: .leading,
            multiplier: 1,
            constant: 0
        )
        leadingConstraint.isActive = true
        
        let trailingConstraint = NSLayoutConstraint(
            item: separatorView,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1,
            constant: 0
        )
        trailingConstraint.isActive = true
        
        let heightConstraint = NSLayoutConstraint(
            item: separatorView,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: horizontalSeparatorOptions.height
        )
        heightConstraint.isActive = true
    }
    
    // MARK: CAShapeLayers setup

    private func setupShapeLayer(shapeLayer: CAShapeLayer, backgroundColor: UIColor, height: CGFloat, sublayer: CALayer) {
        shapeLayer.fillColor = backgroundColor.cgColor
        shapeLayer.strokeColor = backgroundColor.cgColor
        shapeLayer.lineWidth = height
        layer.insertSublayer(shapeLayer, below: sublayer)
    }
    
    // MARK: - Actions:
    // MARK: Reload segmentio
    private func reloadSegmentio() {
        segmentioCollectionView?.reloadData()
        scrollToItemAtContext()
        moveShapeLayerAtContext()
    }

    // MARK: Move shape layer to item
    
    private func moveShapeLayerAtContext() {
        if let indicatorLayer = indicatorLayer, let options = segmentioOptions.indicatorOptions {
            let item = itemInSuperview(ratio: options.ratio)
            let context = contextForItem(item)
            
            let points = Points(
                context: context,
                item: item,
                pointY: indicatorPointY()
            )
            
            moveShapeLayer(
                indicatorLayer,
                startPoint: points.startPoint,
                endPoint: points.endPoint,
                animated: true
            )
        }
        
        if let selectedLayer = selectedLayer {
            let item = itemInSuperview()
            let context = contextForItem(item)
            
            let points = Points(
                context: context,
                item: item,
                pointY: bounds.midY
            )
            
            moveShapeLayer(
                selectedLayer,
                startPoint: points.startPoint,
                endPoint: points.endPoint,
                animated: true
            )
        }
    }
    
    // MARK: Scroll to item
    
    private func scrollToItemAtContext() {
        guard let numberOfSections = segmentioCollectionView?.numberOfSections() else {
            return
        }
        
        let item = itemInSuperview()
        let context = contextForItem(item)
        
        if context.isLastOrPrelastVisibleCell == true {
            let newIndex = selectedSegmentioIndex + (context.isLastCell ? 0 : 1)
            let newIndexPath = IndexPath(item: newIndex, section: numberOfSections - 1)
            segmentioCollectionView?.scrollToItem(
                at: newIndexPath,
                at: UICollectionViewScrollPosition(),
                animated: true
            )
        }
        
        if context.isFirstOrSecondVisibleCell == true {
            let newIndex = selectedSegmentioIndex - (context.isFirstIndex ? 1 : 0)
            let newIndexPath = IndexPath(item: newIndex, section: numberOfSections - 1)
            segmentioCollectionView?.scrollToItem(
                at: newIndexPath,
                at: UICollectionViewScrollPosition(),
                animated: true
            )
        }
    }
    
    // MARK: Move shape layer
    
    private func moveShapeLayer(_ shapeLayer: CAShapeLayer, startPoint: CGPoint, endPoint: CGPoint, animated: Bool = false) {
        var endPointWithVerticalSeparator = endPoint
        let isLastItem = selectedSegmentioIndex + 1 == segmentioItems.count
        endPointWithVerticalSeparator.x = endPoint.x - (isLastItem ? 0 : 1)
        
        let shapeLayerPath = UIBezierPath()
        shapeLayerPath.move(to: startPoint)
        shapeLayerPath.addLine(to: endPointWithVerticalSeparator)
        
        if animated == true {
            isPerformingScrollAnimation = true
            isUserInteractionEnabled = false
            
            CATransaction.begin()
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = shapeLayer.path
            animation.toValue = shapeLayerPath.cgPath
            animation.duration = animationDuration
            CATransaction.setCompletionBlock() {
                self.isPerformingScrollAnimation = false
                self.isUserInteractionEnabled = true
            }
            shapeLayer.add(animation, forKey: "path")
            CATransaction.commit()
        }
        
        shapeLayer.path = shapeLayerPath.cgPath
    }
    
    // MARK: - Context for item
    
    private func contextForItem(_ item: ItemInSuperview) -> Context {
        let cellFrame = item.cellFrameInSuperview
        let cellWidth = cellFrame.width
        let lastCellMinX = floor(item.collectionViewWidth - cellWidth)
        let minX = floor(cellFrame.minX)
        let maxX = floor(cellFrame.maxX)
        
        let isLastVisibleCell = maxX >= item.collectionViewWidth
        let isLastVisibleCellButOne = minX < lastCellMinX && maxX > lastCellMinX
        
        let isFirstVisibleCell = minX <= 0
        let isNextAfterFirstVisibleCell = minX < cellWidth && maxX > cellWidth
        
        return Context(
            isFirstCell: selectedSegmentioIndex == 0,
            isLastCell: selectedSegmentioIndex == segmentioItems.count - 1,
            isLastOrPrelastVisibleCell: isLastVisibleCell || isLastVisibleCellButOne,
            isFirstOrSecondVisibleCell: isFirstVisibleCell || isNextAfterFirstVisibleCell,
            isFirstIndex: selectedSegmentioIndex > 0
        )
    }
    
    // MARK: - Item in superview
    
    private func itemInSuperview(ratio: CGFloat = 1) -> ItemInSuperview {
        var collectionViewWidth: CGFloat = 0
        var cellWidth: CGFloat = 0
        var cellRect = CGRect.zero
        var shapeLayerWidth: CGFloat = 0
        
        if let collectionView = segmentioCollectionView {
            collectionViewWidth = collectionView.frame.width
            let maxVisibleItems = CGFloat(segmentioOptions.maxVisibleItems)
            cellWidth = floor(collectionViewWidth / maxVisibleItems)
            
            cellRect = CGRect(
                x: floor(CGFloat(selectedSegmentioIndex) * cellWidth - collectionView.contentOffset.x),
                y: 0,
                width: floor(collectionViewWidth / maxVisibleItems),
                height: collectionView.frame.height
            )
            
            shapeLayerWidth = floor(cellWidth * ratio)
        }
        
        return ItemInSuperview(
            collectionViewWidth: collectionViewWidth,
            cellFrameInSuperview: cellRect,
            shapeLayerWidth: shapeLayerWidth,
            startX: floor(cellRect.midX - (shapeLayerWidth / 2)),
            endX: floor(cellRect.midX + (shapeLayerWidth / 2))
        )
    }
    
    // MARK: - Indicator point Y
    
    private func indicatorPointY() -> CGFloat {
        var indicatorPointY: CGFloat = 0
        
        guard let indicatorOptions = segmentioOptions.indicatorOptions else {
            return indicatorPointY
        }
        
        switch indicatorOptions.type {
        case .top:
            indicatorPointY = (indicatorOptions.height / 2)
        case .bottom:
            indicatorPointY = frame.height - (indicatorOptions.height / 2)
        }
        
        guard let horizontalSeparatorOptions = segmentioOptions.horizontalSeparatorOptions else {
            return indicatorPointY
        }
        
        let separatorHeight = horizontalSeparatorOptions.height
        let isIndicatorTop = indicatorOptions.type == .top
        
        switch horizontalSeparatorOptions.type {
        case .top:
            indicatorPointY = isIndicatorTop ? indicatorPointY + separatorHeight : indicatorPointY
        case .bottom:
            indicatorPointY = isIndicatorTop ? indicatorPointY : indicatorPointY - separatorHeight
        case .topAndBottom:
            indicatorPointY = isIndicatorTop ? indicatorPointY + separatorHeight : indicatorPointY - separatorHeight
        }
        
        return indicatorPointY
    }
}

// MARK: - UICollectionViewDataSource

extension Segmentio: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return segmentioItems.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: segmentioStyle.rawValue,
            for: indexPath) as! SegmentioCell
        
        cell.configure(
            segmentioItems[(indexPath as NSIndexPath).row],
            style: segmentioStyle,
            options: segmentioOptions,
            isLastCell: (indexPath as NSIndexPath).row == segmentioItems.count - 1
        )
        
        cell.configure((indexPath as NSIndexPath).row == selectedSegmentioIndex)
        
        return cell
    }
    
}

// MARK: - UICollectionViewDelegate

extension Segmentio: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedSegmentioIndex = (indexPath as NSIndexPath).row
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout

extension Segmentio: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(
            width: floor(collectionView.frame.width / CGFloat(segmentioOptions.maxVisibleItems)),
            height: collectionView.frame.height
        )
    }
    
}

// MARK: - UIScrollViewDelegate

extension Segmentio: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isPerformingScrollAnimation == true {
            return
        }
        
        if let options = segmentioOptions.indicatorOptions, indicatorLayer = indicatorLayer {
            let item = itemInSuperview(ratio: options.ratio)
            moveShapeLayer(
                indicatorLayer,
                startPoint: CGPoint(x: item.startX, y: indicatorPointY()),
                endPoint: CGPoint(x: item.endX, y: indicatorPointY()),
                animated: false
            )
        }
        
        if let selectedLayer = selectedLayer {
            let item = itemInSuperview()
            moveShapeLayer(
                selectedLayer,
                startPoint: CGPoint(x: item.startX, y: bounds.midY),
                endPoint: CGPoint(x: item.endX, y: bounds.midY),
                animated: false
            )
        }
    }
    
}

extension Segmentio.Points {
    init(context: Segmentio.Context, item: Segmentio.ItemInSuperview, pointY: CGFloat) {
        let cellWidth = item.cellFrameInSuperview.width
        
        var startX = item.startX
        var endX = item.endX
        
        if context.isFirstCell == false && context.isLastCell == false {
            if context.isLastOrPrelastVisibleCell == true {
                let updatedStartX = item.collectionViewWidth - (cellWidth * 2) + ((cellWidth - item.shapeLayerWidth) / 2)
                startX = updatedStartX
                let updatedEndX = updatedStartX + item.shapeLayerWidth
                endX = updatedEndX
            }
            
            if context.isFirstOrSecondVisibleCell == true {
                let updatedEndX = (cellWidth * 2) - ((cellWidth - item.shapeLayerWidth) / 2)
                endX = updatedEndX
                let updatedStartX = updatedEndX - item.shapeLayerWidth
                startX = updatedStartX
            }
        }
        
        if context.isFirstCell == true {
            startX = (cellWidth - item.shapeLayerWidth) / 2
            endX = startX + item.shapeLayerWidth
        }
        
        if context.isLastCell == true {
            startX = item.collectionViewWidth - cellWidth + (cellWidth - item.shapeLayerWidth) / 2
            endX = startX + item.shapeLayerWidth
        }
        
        startPoint = CGPoint(x: startX, y: pointY)
        endPoint = CGPoint(x: endX, y: pointY)
    }
    
}
