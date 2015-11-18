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
    private var indicatorView: UIImageView!
    
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
        
        backgroundColor = UIColor.blueColor()
        
        titleLabel?.font = UIFont(name: "Avenir-Book", size: 14)
        titleLabel?.textAlignment = .Center
        titleLabel?.lineBreakMode = .ByTruncatingTail
        setTitleColor(UIColor.blackColor(), forState: .Normal)
        
        imageView?.layer.masksToBounds = true
        imageView?.contentMode = .ScaleAspectFill
    }
    
    var object: RadarObjectProtocol! {
        didSet {
            let distance = Int(object.distance())
            //setTitle(object.title(), forState: .Normal)
            setTitle("\(distance)", forState: .Normal)
            setImage(object.photo(), forState: .Normal)
            indicatorView.image = object.identifierIcon()
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
    }
    
    override private func titleRectForContentRect(contentRect: CGRect) -> CGRect {
        let width = contentRect.width
        return CGRectMake(0.0, width, width, contentRect.height - width)
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
@objc class RadarView : UIView {
    private let margin: CGFloat = 10.0
    private let titleHeight: CGFloat = 30.0
    
    var pointSize: CGFloat = 60.0 {
        didSet {
            setNeedsLayout()
        }
    }
    private var maxPointsOnLine: Int!
    
    private var numberOfSegments: Int!
    private var segments: [Int: CLLocationDistance] = [:]

    private var points: [Int: [Int: RadarObjectProtocol]] = [:]
    private var numberOfPoints: Int = 0
    private var visiblePoints: [RadarPointView] = []
    private var recycledPoints: Set<RadarPointView> = Set()
    
    @IBOutlet weak var delegate: RadarDelegate!
    @IBOutlet weak var dataSource: RadarDataSource! {
        didSet {
            reloadData()
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
    
    private func calcNumberOfPoints() -> Int {
        return Int((frame.width - margin * 2) / (pointSize + margin * 2 + 5.0))
    }
    
    private func calcNumberOfSegments() -> Int {
        return Int((frame.height - margin * 2) / (pointSize + titleHeight + margin * 2))
    }
    
    private func initView() {
        backgroundColor = UIColor.grayColor()
        
        maxPointsOnLine = calcNumberOfPoints()
        numberOfSegments = calcNumberOfSegments()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var needReload: Bool = false
        let pointsOnLine = calcNumberOfPoints()
        let segments = calcNumberOfSegments()
        NSLog("Radar layout, max points on line \(pointsOnLine), max rows \(segments)")
        
        if maxPointsOnLine != pointsOnLine {
            maxPointsOnLine = pointsOnLine
            needReload = true
        }
        
        if numberOfSegments != segments {
            numberOfSegments = segments
            needReload = true
        }
        
        if needReload {
            self.reloadData()
        }
    }
    
    func reloadData() {
        NSLog("reloadData")
        if dataSource == nil {
            return;
        }
        let limit = dataSource.numberOfObjects(self)
        
        // clean up views
        if numberOfPoints > limit {
            recycledPoints.removeAll()
            let removeLimit = numberOfPoints - limit
            for var i = 0; i < removeLimit; i++ {
                if recycledPoints.count < 5 {
                    recyclePointView(visiblePoints.last!)
                } else {
                    removePointView(visiblePoints.last!)
                }
                visiblePoints.removeLast()
            }
        } else {
            let insertLimit = limit - numberOfPoints
            for var i = 0; i < insertLimit; i++ {
                visiblePoints.append(dequeueRecycledPointView())
            }
        }
        
        numberOfPoints = limit
        segments.removeAll()
        points.removeAll()
        
        if limit == 0 {
            return;
        }
        
        // prepare objects positions
        let sourceObjects: NSMutableArray = NSMutableArray(capacity: limit)
        var minDistance: CLLocationDistance = CLLocationDistanceMax
        var maxDistance: CLLocationDistance = 0
        
        for var i = 0; i < limit; i++ {
            let object = dataSource.objectForIndex(self, index: i);
            let distance: CLLocationDistance = object.distance()
            if distance < minDistance {
                minDistance = distance
            }
            if distance > maxDistance {
                maxDistance = distance
            }
            sourceObjects.addObject(object)
        }
        
        let avargeDistance: Int = Int(ceil(maxDistance / Double(numberOfSegments)))
        var lastDistance: CLLocationDistance = 0
        let distanceObjects: NSMutableArray = sourceObjects.mutableCopy() as! NSMutableArray
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
                }
            }
            lastDistance = currentDistance
        }
        NSLog("\(segments)")
        NSLog("\(distanceObjects)")
        
        // add views to radar
        let pointHeight = pointSize + titleHeight
        let marginX = floor((frame.width - margin * 2 - (pointSize * CGFloat(maxPointsOnLine))) / CGFloat(maxPointsOnLine - 1))
        let marginY = floor((frame.height - margin * 2 - (pointHeight * CGFloat(numberOfSegments))) / CGFloat(numberOfSegments - 1))

        var numberVerify = 0
        
        for (row, objects) in points {
            var line: CGFloat = 0
            //let displayGroupView = objects.count > maxPointsOnLine
            
            for (index, object) in objects {
                let view = visiblePoints[index];
                view.object = object
                view.frame = CGRectMake(margin + ((marginX + pointSize) * line), margin + ((marginY + pointHeight) * CGFloat(numberOfSegments - row - 1)), pointSize, pointHeight)
                addSubview(view)
                
                line++
                if Int(line) >= maxPointsOnLine {
                    break;
                }
            }
            numberVerify += objects.count
        }
        NSLog("points \(numberOfPoints) vs verify \(numberVerify), distance objects \(distanceObjects.count) == 0")
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
        let index = visiblePoints.indexOf(sender as! RadarPointView)
        if index != nil {
            delegate.didSelectObjectAtIndex?(self, index: index!)
        }
    }
}


@objc protocol RadarDataSource {
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

@objc protocol RadarDelegate {
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

@objc protocol RadarObjectProtocol {
    /**
     Title for object in radar
     
     @return String title
     */
    func title() -> String
    
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

