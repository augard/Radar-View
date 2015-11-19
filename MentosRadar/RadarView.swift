//
//  RadarView.swift
//  MentosRadar
//
//  Created by Lukáš Foldýna on 18/11/15.
//  Copyright © 2015 The Funtasty. All rights reserved.
//

import UIKit
import CoreLocation


private class RadarPointView: UIButton {
    var segment: Int!
    var index: Int!
    var group: Bool = false
    
    private var indicatorView: UIImageView!
    
    private var _groupOverlayer: UIView?
    private var groupOverlayer: UIView! {
        get {
            if (_groupOverlayer == nil) {
                _groupOverlayer = UIView(frame: CGRectZero)
                _groupOverlayer?.backgroundColor = UIColor(red:0.498,  green:0.804,  blue:0.898, alpha:1)
                _groupOverlayer?.hidden = true
                _groupOverlayer?.alpha = 0.65
                imageView?.addSubview(_groupOverlayer!)
            } else {
                imageView?.bringSubviewToFront(_groupOverlayer!)
            }
            return _groupOverlayer!
        }
        set {
            _groupOverlayer?.removeFromSuperview()
            _groupOverlayer = nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initView()
    }
    
    private func initView() {
        indicatorView = UIImageView(frame: CGRectZero)
        indicatorView.userInteractionEnabled = false
        addSubview(indicatorView)
        
        //backgroundColor = UIColor.blueColor()
        
        titleLabel?.font = UIFont(name: "Avenir-Book", size: 14)
        titleLabel?.textAlignment = .Center
        titleLabel?.lineBreakMode = .ByTruncatingTail
        
        imageView?.layer.masksToBounds = true
        imageView?.contentMode = .ScaleAspectFill
    }
    
    var object: RadarObjectProtocol! {
        didSet {
            if object == nil {
                setImage(nil, forState: .Normal)
                indicatorView.image = nil
                return;
            }
            
            let color = object.titleColor()
            setTitle(object.title(), forState: .Normal)
            
            //let distance = Int(object.distance())
            //setTitle("\(index) \(distance)", forState: .Normal)
            
            setImage(object.photo(), forState: .Normal)
            
            if group {
                titleLabel?.font = UIFont(name: "Avenir-Medium", size: 19)
                setTitleColor(UIColor.whiteColor(), forState: .Normal)
                indicatorView.image = nil
                groupOverlayer.hidden = false
                groupOverlayer.frame = (imageView?.bounds)!
            } else {
                titleLabel?.font = UIFont(name: "Avenir-Book", size: 14)
                setTitleColor(color == nil ? UIColor.blackColor() : color, forState: .Normal)
                indicatorView.image = object.identifierIcon()
                groupOverlayer = nil
            }
            indicatorView.hidden = indicatorView.image == nil
            
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if indicatorView.image != nil {
            let imageSize = indicatorView.image!.size
            indicatorView.frame = CGRectMake(frame.width - imageSize.width - 2.0, 2.0, imageSize.width, imageSize.height)
        }
        
        if _groupOverlayer != nil {
            groupOverlayer.frame = (imageView?.bounds)!
        }
    }
    
    override private func titleRectForContentRect(contentRect: CGRect) -> CGRect {
        let width = contentRect.width
        if group {
            return CGRectMake(0.0, 0.0, width, width)
        } else {
            return CGRectMake(0.0, width, width, contentRect.height - width)
        }
    }
    
    override private func imageRectForContentRect(contentRect: CGRect) -> CGRect {
        let width = contentRect.width
        if width == 0 {
            return CGRectZero
        }
        imageView?.layer.cornerRadius = width / 2
        return CGRectMake(0.0, 0.0, width, width)
    }
    
}


// Name of the radar class
@objc public class RadarView : UIView {
    private let margin: CGFloat = 10.0
    private let titleHeight: CGFloat = 30.0
    private let curveCorrection: CGFloat = 12.0
    
    var backgroundView: UIImageView!
    var backgroundImage: UIImage? {
        didSet {
            backgroundView.image = backgroundImage
        }
    }
    
    /**
     @param How much space keep between points
     */
    var pointSpacing: CGFloat = 100.0 {
        didSet {
            reloadData()
        }
    }
    
    /**
     @param Size of points
     */
    var pointSize: CGFloat = 60.0 {
        didSet {
            setNeedsLayout()
        }
    }
    private var maxPointsOnLine: Int = 0
    
    private var numberOfSegments: Int = 0
    private var segments: [Int: CLLocationDistance] = [:]
    private var segmentsLabel: [UILabel] = []
    
    /**
     @param Min distance for radar scale (m)
     */
    public var minDistanceScale: CLLocationDistance = 5000.0

    private var points: [Int: [Int: RadarObjectProtocol]] = [:]
    private var numberOfPoints: Int = 0
    private var visiblePoints: [RadarPointView] = []
    private var recycledPoints: Set<RadarPointView> = Set()
    
    @IBOutlet weak var delegate: RadarDelegate?
    @IBOutlet weak var dataSource: RadarDataSource? {
        didSet {
            reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        initView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initView()
    }
    
    private func calcNumberOfPoints() -> Int {
        return Int((frame.width - margin * 2) / (pointSize + margin * 2 + 5.0))
    }
    
    private func calcNumberOfSegments() -> Int {
        return Int((frame.height - margin * 2) / (pointSpacing))
    }
    
    private func initView() {
        backgroundColor = UIColor.whiteColor()

        backgroundView = UIImageView(frame: self.bounds)
        backgroundView.backgroundColor = backgroundColor
        backgroundView.contentMode = .Top
        addSubview(backgroundView)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.frame = self.bounds
        
        var needReload: Bool = false
        let pointsOnLine = calcNumberOfPoints()
        let segments = calcNumberOfSegments()
        NSLog("Radar layout, max points on line \(pointsOnLine), max rows \(segments)")
        
        if maxPointsOnLine != pointsOnLine {
            maxPointsOnLine = pointsOnLine
            needReload = true
        }
        
        if numberOfSegments != segments {
            if numberOfSegments > segments {
                while segmentsLabel.count != segments {
                    segmentsLabel.last?.removeFromSuperview()
                    segmentsLabel.removeLast()
                }
            } else if (numberOfSegments < segments) {
                while segmentsLabel.count != segments {
                    let label: UILabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 40.0))
                    label.textAlignment = .Center
                    label.textColor = UIColor(red:0.663,  green:0.878,  blue:0.925, alpha:1)
                    label.font = UIFont(name: "Avenir-Heavy", size: 10)
                    label.numberOfLines = 2
                    //label.backgroundColor = UIColor.purpleColor()
                    addSubview(label)
                    segmentsLabel.append(label)
                }
            }
            numberOfSegments = segments
            needReload = true
        }
        
        if needReload {
            self.reloadData()
        }
    }
    
    private func cleanUp() {
        for visiblePoint in visiblePoints {
            if recycledPoints.count < 5 {
                recyclePointView(visiblePoint)
            } else {
                removePointView(visiblePoint)
            }
        }
        visiblePoints.removeAll()
    }
    
    private func cleanUpAndCreateViews(oldLimit: Int, limit: Int) {
        // clean up views
        if oldLimit > limit {
            recycledPoints.removeAll()
            let removeLimit = oldLimit - limit
            for _ in 0..<removeLimit {
                if recycledPoints.count < 5 {
                    recyclePointView(visiblePoints.last!)
                } else {
                    removePointView(visiblePoints.last!)
                }
                visiblePoints.removeLast()
            }
        } else {
            let insertLimit = limit - oldLimit
            for _ in 0..<insertLimit {
                visiblePoints.append(dequeueRecycledPointView())
            }
        }
    }
    
    func reloadData() {
        NSLog("reloadData")
        if dataSource == nil || numberOfSegments == 0 {
            self.cleanUp()
            return;
        }
        numberOfPoints = dataSource!.numberOfObjects(self)
        segments.removeAll()
        points.removeAll()
        
        if numberOfPoints == 0 {
            self.cleanUp()
            return;
        }
        
        // prepare objects positions
        let sourceObjects: NSMutableArray = NSMutableArray(capacity: numberOfPoints)
        var minDistance: CLLocationDistance = CLLocationDistanceMax
        var maxDistance: CLLocationDistance = 0
        
        for i in 0..<numberOfPoints {
            let object = dataSource!.objectForIndex(self, index: i);
            let distance: CLLocationDistance = object.distance()
            if distance < minDistance {
                minDistance = distance
            }
            if distance > maxDistance {
                maxDistance = distance
            }
            sourceObjects.addObject(object)
        }
        if minDistanceScale > maxDistance {
            maxDistance = minDistanceScale
        }
        let avargeDistance: Int = Int(ceil(maxDistance / Double(numberOfSegments)))
        var lastDistance: CLLocationDistance = 0
        let distanceObjects: NSMutableArray = sourceObjects.mutableCopy() as! NSMutableArray
        var viewLimit = 0
        while segments.count < numberOfSegments {
            let currentIndex = segments.count
            let currentDistance = CLLocationDistance(avargeDistance * (currentIndex + 1));
            segments[currentIndex] = currentDistance
            let objects: NSArray = distanceObjects.copy() as! NSArray
            for object in objects {
                let objectIndex = sourceObjects.indexOfObject(object)
                let distance = object.distance()
                if lastDistance <= distance && distance <= currentDistance {
                    if points[currentIndex] == nil {
                        points[currentIndex] = [:]
                    }
                    points[currentIndex]![objectIndex] = object as? RadarObjectProtocol
                    distanceObjects.removeObject(object)
                    if (currentIndex == 0 && points[currentIndex]!.count <= (maxPointsOnLine - 1)) {
                        viewLimit++;
                    } else if (currentIndex > 0 && points[currentIndex]!.count <= maxPointsOnLine) {
                        viewLimit++;
                    }
                }
            }
            lastDistance = currentDistance
        }
        self.cleanUpAndCreateViews(self.visiblePoints.count, limit: viewLimit)
        NSLog("\(segments)")
        
        // add views to radar
        let pointHeight = pointSize + titleHeight
        let marginY = floor(((frame.height - 50.0) - (pointSpacing * CGFloat(numberOfSegments))) / CGFloat(numberOfSegments))

        var numberVerify = 0
        var viewIndex = 0
        
        for (segmentIndex, objects) in points {
            var line: CGFloat = 0
            var maxPoints = maxPointsOnLine
            if segmentIndex == 0 {
                maxPoints--
            }
            let maxCount: CGFloat = CGFloat(objects.count > maxPoints ? maxPoints : objects.count)
            let evenCount: Bool = maxCount % 2 == 0
            let marginX: CGFloat = floor((frame.width - (pointSize * maxCount)) / (maxCount + 1))
            let originY: CGFloat = 17.0 + (pointSpacing * CGFloat(numberOfSegments - segmentIndex - 1))
            
            let sortedKeysAndValues = objects.sort { $0.0 < $1.0 }
            for (objectIndex, object) in sortedKeysAndValues {
                let view = visiblePoints[viewIndex];
                view.group = (objects.count > (maxPoints + 1) && Int(line) + 1 == maxPoints)
                view.segment = segmentIndex
                view.index = objectIndex
                view.object = object
                if view.group {
                    view.setTitle("+\(objects.count - maxPoints)", forState: .Normal)
                }
                
                var correctionY: CGFloat = 0
                if evenCount {
                    if line == 0 || line == maxCount - 1 {
                        correctionY = curveCorrection
                    }
                } else if !evenCount && maxCount > 1 {
                    if line == 0 || line == maxCount - 1 {
                        correctionY = curveCorrection
                    }
                }
                if correctionY > 0 {
                    if frame.width > 320 {
                        correctionY += CGFloat(numberOfSegments - segmentIndex)
                    }
                    if segmentIndex == 0 || segmentIndex == 1 {
                        correctionY = curveCorrection * 2
                    }
                }
                view.frame = CGRectMake(marginX + ((marginX + pointSize) * line), marginY + originY + correctionY, pointSize, pointHeight)
                addSubview(view)
                
                line++
                viewIndex++
                if Int(line) >= maxPoints {
                    break;
                }
            }
            numberVerify += objects.count
        }
        NSLog("viewLimit \(viewLimit) vs viewIndex \(viewIndex)")
        NSLog("points \(numberOfPoints) vs verify \(numberVerify), distance objects \(distanceObjects.count) == 0")
        
        for segmentIndex in 0..<numberOfSegments {
            let originY: CGFloat = 17.0 + (pointSpacing * CGFloat(numberOfSegments - segmentIndex - 1)) - 13.0
            let label = segmentsLabel[segmentIndex]
            label.text = segmentLabelTitle(CLLocationDistance(segmentIndex * avargeDistance), segmentIndex: segmentIndex)
            label.frame = CGRectMake((frame.width - label.frame.width) / 2, marginY + originY + ((pointHeight - label.frame.height) / 2),
            label.frame.width, label.frame.height)
            //bringSubviewToFront(label)
        }
    }
    
    private func dequeueRecycledPointView() -> RadarPointView {
        var view = recycledPoints.first
        if view == nil {
            view = RadarPointView()
            view?.addTarget(self, action: "didTapPoint:", forControlEvents: .TouchUpInside)
        } else {
            recycledPoints.remove(view!)
        }
        return view!
    }
    
    private func removePointView(view: RadarPointView) {
        view.object = nil
        view.removeFromSuperview()
    }
    
    private func recyclePointView(view: RadarPointView) {
        removePointView(view)
        recycledPoints.insert(view)
    }
    
    // MARK: - Actions
    
    internal func didTapPoint(sender: AnyObject) {
        if delegate == nil {
            return;
        }
        let view: RadarPointView = sender as! RadarPointView
        if view.group {
            let objects = points[view.segment]
            if objects == nil {
                return
            }
            var indexes: [Int] = []
            for (objectIndex, _) in objects! {
                if objectIndex >= view.index {
                    indexes.append(objectIndex)
                }
            }
            delegate!.didSelectGroupWithIndexes?(self, indexes: indexes)
        } else {
            delegate!.didSelectObjectAtIndex?(self, index: view.index)
        }
    }
    
    // MARK: -
    
    private func segmentLabelTitle(distance: CLLocationDistance, segmentIndex: Int) -> String {
        let labelTitle: String!
        let distance: Int = Int(distance / 1000)
        if segmentIndex == 0 {
            labelTitle = "Blízko"
        } else if segmentIndex + 1 == numberOfSegments {
            labelTitle = "\(distance) km\na dále"
        } else {
            labelTitle = "\(distance) km"
        }
        return labelTitle
    }
}


@objc public protocol RadarDataSource {
    /**
     Number of objects in radar.
     
     @param radar Radar which invoked the delegate call
     
     @return Number of objects
     */
    func numberOfObjects(radar: RadarView) -> Int
    
    /**
     Object for given index.
     
     @param radar Radar which invoked the delegate call
     @param index Index of object
     
     @return Object confirming RadarObjectProtocol
     */
    func objectForIndex(radar: RadarView, index : Int) -> RadarObjectProtocol
}

@objc public protocol RadarDelegate {
    /**
     Is called when user selects single object
     
     @param radar Radar which invoked the delegate call
     @param index Index of object
     
     */
    optional func didSelectObjectAtIndex(radar: RadarView, index : Int)
    
    /**
     Is called when user selects group of objects
     
     @param radar Radar which invoked the delegate call
     @param indexes Array of indexes of objects which have been selected
     
     */
    optional func didSelectGroupWithIndexes(radar: RadarView, indexes: [Int])
}

@objc public protocol RadarObjectProtocol {
    /**
     Title for object in radar
     
     @return String title
     */
    func title() -> String
    
    /**
     Title color for object in radar
     
     @return UIColor title
     */
    func titleColor() -> UIColor?
    
    /**
     UIImage for object in radar
     
     @return UIImage instance of photo
     */
    func photo() -> UIImage
    
    /**
     Identifier UIImage (identifies gender for example). Should be hidden if nil.
     
     @return optional UIImage instance of identifier image
     */
    func identifierIcon() -> UIImage?
    
    /**
     Distance from current location. For layout purposes.
     
     @return distance to object as CLLocationDistance
     */
    func distance() -> CLLocationDistance
}

