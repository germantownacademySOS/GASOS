//
//  ViewController.swift
//  GASOS
//
//  Created by Perry Fraser on 2/4/17.
//  Copyright © 2017 Perry Fraser. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var buttonMakeRounded: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        buttonMakeRounded.layer.masksToBounds = true
        
        buttonMakeRounded.layer.cornerRadius = buttonMakeRounded.bounds.size.width / 2
        
        buttonMakeRounded.backgroundColor = UIColor.blue

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startMonitor(_ sender: UIButton) {
        // May the games begin
    }

}

