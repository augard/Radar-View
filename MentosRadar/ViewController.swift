//
//  ViewController.swift
//  MentosRadar
//
//  Created by Lukáš Foldýna on 18/11/15.
//  Copyright © 2015 The Funtasty. All rights reserved.
//

import UIKit
import CoreLocation


@objc class ViewObject: NSObject, RadarObjectProtocol {
    var distance: CLLocationDistance
    
    override init() {
        distance = 0
        
        super.init()
    }
    
    func title() -> String {
        return "title"
    }
    
    func photo() -> UIImage {
        return UIImage(named: "")!
    }
    
    func identifierIcon() -> UIImage? {
        return UIImage(named: "")
    }
}


class ViewController: UIViewController, RadarDataSource, RadarDelegate {
    
    @IBOutlet weak var radarView: RadarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        radarView.dataSource = self
        radarView.delegate = self
    }

    // MARK: - RadarDataSource
    
    func numberOfObjects(radar: RadarView) -> Int {
        return 0;
    }
    
    func objectForIndex(radar: RadarView, index: Int) -> RadarObjectProtocol {
        return ViewObject()
    }
}

