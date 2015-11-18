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
            setTitle(object.title(), forState: .Normal)
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
    private var numberOfSegments: Int = 3
    private var segments: [CLLocationDistance: [RadarObjectProtocol]]!

    private var numberOfPoints: Int = 0
    private var visiblePoints: [RadarPointView] = []
    private var recycledPoints: Set<RadarPointView> = Set()
    
    var pointSize: CGFloat = 60.0 {
        didSet {
            reloadData()
        }
    }
    
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
    
    private func initView() {
        backgroundColor = UIColor.grayColor()
    }
    
    func reloadData() {
        let limit = dataSource.numberOfObjects(self)
        
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
        let pointHeight = Int(pointSize) + 30
        
        for var i = 0; i < limit; i++ {
            let object = dataSource.objectForIndex(self, index: i);
            let view = visiblePoints[i];
            view.object = object
            view.frame = CGRectMake(10.0, CGFloat(10 + ((pointHeight + 10) * i)), pointSize, CGFloat(pointHeight))
            addSubview(view)
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
    
    private func didTapPoint(sender: RadarPointView) {
        if delegate == nil {
            return;
        }
        let index = visiblePoints.indexOf(sender)
        if index != nil {
            delegate.didSelectObjectAtIndex!(self, index: index!)
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

