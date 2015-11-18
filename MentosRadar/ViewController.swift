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
    
    func titleColor() -> UIColor? {
        return nil
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

        initObjects()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initObjects()
    }
    
    private func initObjects() {
        let indicator = UIImage(named: "indicator")
        let limit = Int.random(3, 25)
        let distanceMax = Double.random(3500, 25000)
        for _ in 0..<limit {
            let object = ViewObject(title: nameGeneator.getName().componentsSeparatedByString(" ").first!,
                photo: UIImage(named: "default-ico")!,
                identifierIcon: Int.random(0, 1) == 1 ? indicator : nil,
                distance: Double.random(0, distanceMax))
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

