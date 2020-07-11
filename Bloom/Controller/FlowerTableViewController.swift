//
//  FlowerTableViewController.swift
//  Bloom
//
//  Created by Su Min Kim on 7/11/20.
//  Copyright © 2020 Su Min Kim. All rights reserved.
//

import UIKit
import RealmSwift
import SDWebImage

class FlowerTableViewController: UITableViewController {
    
    let realm = try! Realm()
    
    var totalFlowers: Results<Flower>?

    override func viewDidLoad() {
        super.viewDidLoad()
        getFlowers()
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalFlowers?.count ?? 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "flowerCell", for: indexPath)
        
        if let flower = totalFlowers?[indexPath.row] {
            cell.textLabel?.text = flower["name"] as? String

            let thumbnailSize = CGSize(width: 300, height: 300)

            cell.imageView?.sd_setImage(with: URL(string: flower["imageURL"] as! String), placeholderImage: UIImage(named: "BloomDefault"), context: [.imageThumbnailPixelSize : thumbnailSize])
            
            if let image = cell.imageView?.image {
                let croppedImage = image.sd_croppedImage(with: CGRect(x: image.size.width/2, y: image.size.height/2, width: 60, height: 60))
                
                cell.imageView?.image = croppedImage
                cell.imageView?.layer.cornerRadius = (croppedImage?.size.height)!/2
                cell.imageView?.clipsToBounds = true
            }

        } else {
            cell.textLabel?.text = "No flowers mastered yet"
        }
        
        return cell
    }


    func getFlowers() {
        totalFlowers = realm.objects(Flower.self).sorted(byKeyPath: "name", ascending: true)
        tableView.reloadData()
    }

}
