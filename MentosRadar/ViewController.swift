//
//  ViewController.swift
//  MentosRadar
//
//  Created by Lukáš Foldýna on 18/11/15.
//  Copyright © 2015 The Funtasty. All rights reserved.
//

import UIKit
import CoreLocation


class ViewObject: RadarObjectProtocol, CustomStringConvertible {
    private var vDistance: CLLocationDistance
    private var vTitle: String
    private var vPhoto: UIImage
    private var vIdentifierIcon: UIImage?
    
    init(title: String, photo: UIImage, identifierIcon: UIImage?, distance: CLLocationDistance) {
        vTitle = title
        vPhoto = photo
        vIdentifierIcon = identifierIcon
        vDistance = distance
    }
    
    func rv_title() -> String {
        return vTitle
    }
    
    func rv_titleColor() -> UIColor? {
        return nil
    }
    
    func rv_photo(button: UIButton) {
        button.setImage(vPhoto, forState: .Normal)
    }
    
    func rv_identifierIcon() -> UIImage? {
        return vIdentifierIcon
    }
    
    func rv_distanceFromCurrentPosition() -> CLLocationDistance {
        return vDistance
    }
    
    var description: String {
        return "\(self.dynamicType): \(vTitle), \(vDistance)\n"
    }
}


class ViewController: UIViewController, UITabBarDelegate, RadarDataSource, RadarDelegate {
    
    var nameGeneator: NameGenerator = NameGenerator()
    var radarObjects: [RadarObjectProtocol] = []
    
    @IBOutlet weak var radarView: RadarView!
    @IBOutlet weak var tabBar: UITabBar!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        initObjects()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initObjects()
    }
    
    private func initObjects() {
        radarObjects.removeAll()
        
        let limit = Int.random(3, 25)
        let distanceMax = Double.random(3500, 25000)
        //let distanceMax = Double.random(1500, 100) // min distance
        for _ in 0..<limit {
            let famale = Int.random(0, 1)
            let object = ViewObject(title: nameGeneator.getName(true, male: famale == 0, prefix: true, postfix: true).componentsSeparatedByString(" ").first!,
                photo: UIImage(named: "default-ico")!,
                identifierIcon: UIImage(named: famale == 1 ? "gender_female" : "gender_male")!,
                distance: Double.random(0, distanceMax))
            radarObjects.append(object)
        }
        NSLog("\(radarObjects)\n num: \(radarObjects.count)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch (view.frame.width) {
        case 320:
            radarView.backgroundImage = UIImage(named: "bg_ip5")!
            radarView.pointSpacing = 100.0
            break;
        case 375:
            radarView.backgroundImage = UIImage(named: "bg_ip6")!
            radarView.pointSpacing = 100.0
            break;
        default:
            radarView.backgroundImage = UIImage(named: "bg_ip6plus")!
            radarView.pointSpacing = 113.0
            break;
        }
        radarView.dataSource = self
        radarView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBar.selectedItem = tabBar.items?.first
    }

    // MARK: - RadarDataSource
    
    func numberOfObjects(radar: RadarView) -> Int {
        return radarObjects.count;
    }
    
    func objectForIndex(radar: RadarView, index: Int) -> RadarObjectProtocol {
        return radarObjects[index]
    }
    
    // MARK: - RadarDelegate
    
    func didSelectObjectAtIndex(radar: RadarView, index : Int) {
         NSLog("didSelectObjectAtIndex \(index)")
    }
    
    func didSelectGroupWithIndexes(radar: RadarView, indexes: [Int]) {
        NSLog("didSelectGroupWithIndexes \(indexes)")
    }
    
    // MARK: - UITabBarDelegate
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        let index = tabBar.items?.indexOf(item)
        
        if index == 1 {
            tabBar.selectedItem = tabBar.items?.first
            initObjects()
            radarView.reloadData()
        }
    }
}

