//
//  CarouselFlow.swift
//  CarouselFlow
//
//  Created by Joan Disho on 24.12.17.
//  Copyright © 2017 Joan Disho. All rights reserved.
//

import UIKit

class CarouselFlow: UICollectionViewFlowLayout {
    
    public var isPagingEnabled: Bool = true
    
    private var dynamicAnimator: UIDynamicAnimator!
    private var visibleIndexPaths: Set<IndexPath>!
    private let transformationMatrix = CATransform3D(m11: 1, m12: 0, m13: 0, m14: 0,
                                                     m21: 0, m22: 1, m23: 0, m24: 0,
                                                     m31: 0, m32: 0, m33: 1, m34: 0,
                                                     m41: 0, m42: 0, m43: 0, m44: 1)
    
    
    // MARK: Initialization
    
    override public init() {
        super.init()
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
        visibleIndexPaths = Set<IndexPath>()
    }
    
    // MARK: Public
    
    func resetLayout() {
        dynamicAnimator.removeAllBehaviors()
        prepare()
    }
    
    // MARK: Overrides
    
    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        
        let visibleRect = CGRect(origin: cv.bounds.origin,size: cv.frame.size)
        
        guard let visibleItems = super.layoutAttributesForElements(in: visibleRect) else { return }
        let indexPathsInVisibleRect = Set(visibleItems.map{ $0.indexPath })
        
        removeNoLongerVisibleBehaviors(indexPathsInVisibleRect: indexPathsInVisibleRect)
        
        let newlyVisibleItems = visibleItems.filter { item in
            return !visibleIndexPaths.contains(item.indexPath)
        }
        
        addBehaviors(for: newlyVisibleItems)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let latestOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        guard isPagingEnabled else {
            return latestOffset
        }
        
        let row = ((proposedContentOffset.y) / (itemSize.height + minimumLineSpacing)).rounded()
        
        let calculatedOffset = row * itemSize.height + row * minimumLineSpacing
        let targetOffset = CGPoint(x: latestOffset.x, y: calculatedOffset)
        return targetOffset
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let cv = collectionView else { return nil }
        let items = super.layoutAttributesForElements(in: rect)
        items?.forEach { item in
            let y = item.center.y - cv.contentOffset.y - sectionInset.top
            item.zIndex = item.indexPath.row
            transform(item: item, by: y)
        }
        return items
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        dynamicAnimator.behaviors
            .map { $0 as? UIAttachmentBehavior }
            .forEach { behavior in
                let attrs = behavior?.items.first as! UICollectionViewLayoutAttributes
                self.dynamicAnimator.updateItem(usingCurrentState: attrs)
        }
        return false
    }
    
    // MARK: - Utils
    
    private func addBehaviors(for items: [UICollectionViewLayoutAttributes]) {
        items.forEach { item in
            let behaviour = UIAttachmentBehavior(item: item, attachedToAnchor: item.center)
            self.dynamicAnimator.addBehavior(behaviour)
            self.visibleIndexPaths.insert(item.indexPath)
        }
    }
    
    private func removeNoLongerVisibleBehaviors(indexPathsInVisibleRect indexPaths: Set<IndexPath>) {
        
        let noLongerVisibleBehaviours = dynamicAnimator.behaviors.filter { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior,
                let item = behavior.items.first as? UICollectionViewLayoutAttributes else { return false }
            return !indexPaths.contains(item.indexPath)
        }
        
        noLongerVisibleBehaviours.forEach { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior,
                let item = behavior.items.first as? UICollectionViewLayoutAttributes else { return }
            self.dynamicAnimator.removeBehavior(behavior)
            self.visibleIndexPaths.remove(item.indexPath)
        }
    }
    
    private func transform(item: UICollectionViewLayoutAttributes, by y: CGFloat) {
        guard itemSize.height > 0, y < itemSize.height * 0.5 else {
            return
        }
        let scale = distributor(v: y, o: -itemSize.height * 5, t: itemSize.height/2)
        item.transform3D = CATransform3DTranslate(transformationMatrix, 0, yDelta(y), 0)
        item.transform3D = CATransform3DScale(item.transform3D, scale, scale, scale)
        item.alpha = distributor(v: y, o: -itemSize.height * 5, t: itemSize.height/2)
    }
    
    // MARK: Helpers
    
    private func distributor(v: CGFloat, o: CGFloat, t: CGFloat) -> CGFloat {
        guard t > o else {
            return 1
        }
        var d = (v - o)/(t - o)
        d = d <= 0 ? 0 : d
        let y = sqrt(d)
        return y > 1 ? 1 : y
    }
    
    private func yDelta(_ y: CGFloat) -> CGFloat {
        return itemSize.height/2 - y
    }
}
