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
    var segmentIndex: Int!
    var objectIndex: Int!
    var group: Bool = false
   
    private var _indicatorView: UIImageView?
    private var indicatorView: UIImageView! {
        get {
            if (_indicatorView == nil) {
                _indicatorView = UIImageView(frame: CGRectZero)
                _indicatorView!.userInteractionEnabled = false
                addSubview(_indicatorView!)
            } else {
                bringSubviewToFront(_indicatorView!)
            }
            return _indicatorView!
        }
        set {
            _indicatorView?.removeFromSuperview()
            _indicatorView = nil
        }
    }
    
    private var _groupOverlayer: UIView?
    private var groupOverlayer: UIView! {
        get {
            if (_groupOverlayer == nil) {
                _groupOverlayer = UIView(frame: CGRectZero)
                _groupOverlayer?.backgroundColor = UIColor(red:0.498,  green:0.804,  blue:0.898, alpha:1)
                _groupOverlayer?.hidden = true
                _groupOverlayer?.alpha = 0.85
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
            
            let color = object.rv_titleColor()
            setTitle(object.rv_title(), forState: .Normal)
            
            //let distance = Int(object.distance())
            //setTitle("\(index) \(distance)", forState: .Normal)
            
            object.rv_photo(self)
            
            if group {
                titleLabel?.font = UIFont(name: "Avenir-Medium", size: 19)
                setTitleColor(UIColor.whiteColor(), forState: .Normal)
                indicatorView = nil
                groupOverlayer.hidden = false
                groupOverlayer.frame = (imageView?.bounds)!
            } else {
                titleLabel?.font = UIFont(name: "Avenir-Book", size: 14)
                setTitleColor(color == nil ? UIColor.blackColor() : color, forState: .Normal)
                let indicatorImage = object.rv_identifierIcon()
                if indicatorImage != nil {
                    indicatorView.image = indicatorImage
                } else {
                    indicatorView = nil
                }
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
    
    private let numberFormatter = NSNumberFormatter()
    
    private var backgroundView: UIImageView!
    /**
     @param Radar background image
     */
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
    public var minDistanceScale: CLLocationDistance = 1250.0
    private var roundDistance: Bool = false

    private var points: [Int: [Int: RadarObjectProtocol]] = [:]
    private var numberOfPoints: Int = 0
    private var visiblePoints: [RadarPointView] = []
    private var recycledPoints: Set<RadarPointView> = Set()
    
    weak var delegate: RadarDelegate?
    weak var dataSource: RadarDataSource? {
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
    
    private var figureNumberOfPoints: Int {
        return Int((frame.width - margin * 2) / (pointSize + margin * 2 + 5.0))
    }
    
    private var figureNumberOfSegments: Int {
        return Int((frame.height - margin * 2) / (pointSpacing))
    }
    
    private func initView() {
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        numberFormatter.maximumFractionDigits = 1
        
        backgroundColor = UIColor.whiteColor()

        backgroundView = UIImageView(frame: self.bounds)
        backgroundView.backgroundColor = backgroundColor
        backgroundView.contentMode = .Top
        addSubview(backgroundView)
        
        
        switch (UIScreen.mainScreen().bounds.width) {
        case 320:
            self.backgroundImage = UIImage(named: "bg_ip5")!
            self.pointSpacing = 100.0
            break;
        case 375:
            self.backgroundImage = UIImage(named: "bg_ip6")!
            self.pointSpacing = 100.0
            break;
        default:
            self.backgroundImage = UIImage(named: "bg_ip6plus")!
            self.pointSpacing = 113.0
            break;
        }

    }
    
    func circleLayer() -> CAShapeLayer {
        let circleRadius: CGFloat = self.bounds.size.width / 2;
        let circleLayer: CAShapeLayer = CAShapeLayer()
        circleLayer.frame = self.bounds;
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.strokeColor = UIColor(red:0.898, green:0.969, blue:0.980, alpha:1).CGColor
        circleLayer.lineWidth = 1
        
        let shape: UIBezierPath = UIBezierPath()
        let center: CGPoint = CGPoint(x: CGRectGetMidX(self.bounds), y: CGRectGetMinY(self.bounds) + 46.0);
        shape.moveToPoint(CGPoint(x: -40.0, y: center.y + circleRadius))
        shape.addCurveToPoint(CGPoint(x: circleLayer.frame.width + 40.0, y: center.y + circleRadius),
            controlPoint1: CGPoint(x: center.x - 60.0, y: center.y + circleRadius - 80),
            controlPoint2: CGPoint(x: center.x + 60.0, y: center.y + circleRadius - 80))
        
        circleLayer.path = shape.CGPath;
        circleLayer.shadowColor = UIColor(red:0.682, green:0.969, blue:0.961, alpha:1).CGColor
        circleLayer.shadowOpacity = 1;
        circleLayer.shadowOffset = CGSizeMake(0, 4);
        circleLayer.shadowRadius = 7;
        return circleLayer;
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.frame = self.bounds
        
        var needReload: Bool = false
        let pointsOnLine = figureNumberOfPoints
        let segments = figureNumberOfSegments
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
        if dataSource == nil || numberOfSegments == 0 {
            self.cleanUp()
            return;
        }
        //self.layer.addSublayer(self.circleLayer())
        NSLog("reloadData")
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
            let distance: CLLocationDistance = object.rv_distanceFromCurrentPosition()
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
        roundDistance = !(Int(maxDistance) / numberOfSegments > 1000) // round it when we have some distance in meters
        numberFormatter.maximumFractionDigits = roundDistance ? 1 : 0
        
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
                let distance = (object as! RadarObjectProtocol).rv_distanceFromCurrentPosition()
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
        //NSLog("\(segments)")
        
        // add views to radar
        let pointHeight = pointSize + titleHeight
        let marginY = floor(((frame.height - 50.0) - (pointSpacing * CGFloat(numberOfSegments))) / CGFloat(numberOfSegments))

        var numberVerify = 0
        var viewIndex = 0
        
        //let sortedPointsKeysAndValues = points.sort { $0.0 < $1.0 }
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
            
            // correction for label if we have more then 4
            var labelCorrection: Bool = false
            if evenCount && maxCount > 3 {
                labelCorrection = true
            }
            
            let sortedKeysAndValues = objects.sort { $0.0 < $1.0 }
            for (objectIndex, object) in sortedKeysAndValues {
                let view = visiblePoints[viewIndex];
                view.group = (objects.count > (maxPoints + 1) && Int(line) + 1 == maxPoints)
                view.segmentIndex = segmentIndex
                view.objectIndex = objectIndex
                view.object = object
                if view.group {
                    view.setTitle("+\(objects.count - maxPoints + 1)", forState: .Normal)
                }
                
                var offsetX: CGFloat = marginX + ((marginX + pointSize) * line)
                var correctionY: CGFloat = 0
                if evenCount {
                    if line == 0 || line == maxCount - 1 {
                        correctionY = curveCorrection
                        if labelCorrection {
                            correctionY += 5.0
                        }
                    }
                    
                    if labelCorrection {
                        if line < (maxCount / 2) {
                            offsetX -= 10.0
                        } else {
                            offsetX += 10.0
                        }
                    }
                } else if !evenCount && maxCount > 1 {
                    if line == 0 || line == maxCount - 1 {
                        correctionY = curveCorrection
                    }
                }
                if correctionY > 0 {
                    if frame.width > 320 {
                        correctionY += CGFloat(numberOfSegments - segmentIndex)
                        if frame.width > 375 && segmentIndex == 0 {
                            correctionY *= 2
                        }
                    }
                    
                    if maxCount > 2 {
                        if segmentIndex == 1 {
                            correctionY = correctionY * 1.5
                        } else if segmentIndex == 0 {
                            correctionY = correctionY * 1.6
                        }
                    }
                }
                //NSLog("s\(segmentIndex):\(line), \(correctionY), \(object.title())")
                view.frame = CGRectMake(offsetX, marginY + originY + correctionY, pointSize, pointHeight)
                addSubview(view)
                
                line++
                viewIndex++
                if Int(line) >= maxPoints {
                    break;
                }
            }
            numberVerify += objects.count
        }
        //NSLog("viewLimit \(viewLimit) vs viewIndex \(viewIndex)")
        //NSLog("points \(numberOfPoints) vs verify \(numberVerify), distance objects \(distanceObjects.count) == 0")
        
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
            let objects = points[view.segmentIndex]
            if objects == nil {
                return
            }
            var indexes: [Int] = []
            for (objectIndex, _) in objects! {
                if objectIndex >= view.objectIndex {
                    indexes.append(objectIndex)
                }
            }
            delegate?.didSelectGroupWithIndexes(self, indexes: indexes)
        } else {
            delegate?.didSelectObjectAtIndex(self, index: view.objectIndex)
        }
    }
    
    // MARK: -
    
    private func segmentLabelTitle(locationDistance: CLLocationDistance, segmentIndex: Int) -> String {
        let labelTitle: String!
        var distance: String = numberFormatter.stringFromNumber(locationDistance / 1000)!
        var unit = "km"
        if (Int(locationDistance / 1000) == 0 && segmentIndex != 0) {
            distance = numberFormatter.stringFromNumber(roundToTens(locationDistance))!
            unit = "m"
        }
        
        if segmentIndex == 0 {
            labelTitle = "Blízko"
        } else if segmentIndex + 1 == numberOfSegments {
            labelTitle = "\(distance) \(unit)\na dále"
        } else {
            labelTitle = "\(distance) \(unit)"
        }
        return labelTitle
    }
    
    func roundToTens(x : Double) -> Int {
        return 100 * Int(round(x / 100.0))
    }
}


public protocol RadarDataSource: class {
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

public protocol RadarDelegate: class {
    /**
     Is called when user selects single object
     
     @param radar Radar which invoked the delegate call
     @param index Index of object
     
     */
    func didSelectObjectAtIndex(radar: RadarView, index : Int)
    
    /**
     Is called when user selects group of objects
     
     @param radar Radar which invoked the delegate call
     @param indexes Array of indexes of objects which have been selected
     
     */
    func didSelectGroupWithIndexes(radar: RadarView, indexes: [Int])
}

public protocol RadarObjectProtocol: AnyObject {
    /**
     Title for object in radar
     
     @return String title
     */
    func rv_title() -> String
    
    /**
     Title color for object in radar
     
     @return UIColor title
     */
    func rv_titleColor() -> UIColor?
    
    /**
     UIImage for object in radar
     
     @return UIImage instance of photo
     */
    func rv_photo(button: UIButton)
    
    /**
     Identifier UIImage (identifies gender for example). Should be hidden if nil.
     
     @return optional UIImage instance of identifier image
     */
    func rv_identifierIcon() -> UIImage?
    
    /**
     Distance from current location. For layout purposes.
     
     @return distance to object as CLLocationDistance
     */
    func rv_distanceFromCurrentPosition() -> CLLocationDistance
}

