//
//  SegmentioCellWithLabel.swift
//  Segmentio
//
//  Created by Dmitriy Demchenko
//  Copyright © 2016 Yalantis Mobile. All rights reserved.
//

import UIKit

final class SegmentioCellWithLabel: SegmentioCell {
    
    override func setupConstraintsForSubviews() {
        guard let segmentTitleLabel = segmentTitleLabel else {
            return
        }
        
        let views = ["segmentTitleLabel": segmentTitleLabel]
        
        // main constraints
        
        let segmentTitleLabelHorizontConstraint = NSLayoutConstraint.constraints(
            withVisualFormat: "|-[segmentTitleLabel]-|",
            options: [],
            metrics: nil,
            views: views
        )
        NSLayoutConstraint.activate(segmentTitleLabelHorizontConstraint)
        
        // custom constraints
        
        topConstraint = NSLayoutConstraint(
            item: segmentTitleLabel,
            attribute: .top,
            relatedBy: .equal,
            toItem: contentView,
            attribute: .top,
            multiplier: 1,
            constant: padding
        )
        topConstraint?.isActive = true
        
        bottomConstraint = NSLayoutConstraint(
            item: contentView,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: segmentTitleLabel,
            attribute: .bottom,
            multiplier: 1,
            constant: padding
        )
        bottomConstraint?.isActive = true
    }

}
