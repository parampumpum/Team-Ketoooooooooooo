//
//  FirebaseTableViewCell.swift
//  FirebaseDemo
//
//  Created by Jett Anderson on 4/23/18.
//  Copyright © 2018 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

class FirebaseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.textLabel?.text = ""
        //label.text = nil
        print("Preparing for reuse")
    }
}
