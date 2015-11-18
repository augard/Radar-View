//
//  RadarView.swift
//  MentosRadar
//
//  Created by Lukáš Foldýna on 18/11/15.
//  Copyright © 2015 The Funtasty. All rights reserved.
//

import UIKit
import CoreLocation


// Name of the radar class
@objc class RadarView : UIView {
    @IBOutlet weak var delegate: RadarDelegate!
    @IBOutlet weak var dataSource: RadarDataSource!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initView()
    }
    
    internal func initView() {
        self.backgroundColor = UIColor.redColor()
    }
    
    func reloadData() {
        
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
    var distance: CLLocationDistance { get }
}

