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
    private var vDistance: CLLocationDistance
    private var vTitle: String
    private var vPhoto: UIImage
    private var vIdentifierIcon: UIImage?
    
    override init() {
        vDistance = CLLocationDistanceMax
        vTitle = "Lorem Ipsum"
        vPhoto = UIImage(named: "default-ico")!
        
        super.init()
    }
    
    init(title: String, photo: UIImage, identifierIcon: UIImage?, distance: CLLocationDistance) {
        vTitle = title
        vPhoto = photo
        vIdentifierIcon = identifierIcon
        vDistance = distance

        super.init()
    }
    
    func title() -> String {
        return vTitle
    }
    
    func photo() -> UIImage {
        return vPhoto
    }
    
    func identifierIcon() -> UIImage? {
        return vIdentifierIcon
    }
    
    func distance() -> CLLocationDistance {
        return vDistance
    }
    
    override var description: String {
        return "\(self.dynamicType): \(vTitle), \(vDistance)\n"
    }
}


class ViewController: UIViewController, RadarDataSource, RadarDelegate {
    
    var nameGeneator: NameGenerator = NameGenerator()
    var radarObjects: [RadarObjectProtocol] = []
    
    @IBOutlet weak var radarView: RadarView!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.initObjects()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initObjects()
    }
    
    internal func initObjects() {
        let limit = Int.random(5, 20)
        for var i = 0; i < limit; i++ {
            let object = ViewObject(title: nameGeneator.getName(), photo: UIImage(named: "default-ico")!, identifierIcon: nil, distance: Double.random(0, 2500))
            radarObjects.append(object)
        }
        NSLog("\(radarObjects)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        radarView.dataSource = self
        radarView.delegate = self
    }

    // MARK: - RadarDataSource
    
    func numberOfObjects(radar: RadarView) -> Int {
        return radarObjects.count;
    }
    
    func objectForIndex(radar: RadarView, index: Int) -> RadarObjectProtocol {
        return radarObjects[index]
    }
}

