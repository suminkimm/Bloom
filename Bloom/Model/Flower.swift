//
//  Flower.swift
//  Bloom
//
//  Created by Su Min Kim on 7/11/20.
//  Copyright © 2020 Su Min Kim. All rights reserved.
//

import Foundation
import RealmSwift

class Flower: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var imageURL: String = ""
    @objc dynamic var flowerDescription: String = ""
    
    override static func primaryKey() -> String? {
        return "name"
    }
}
