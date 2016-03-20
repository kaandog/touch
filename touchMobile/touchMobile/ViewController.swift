//
//  ViewController.swift
//  TouchMobile
//
//  Created by Ilter Canberk on 3/15/16.
//  Copyright © 2016 ThemBoyz. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    let WS_URL = "http://touch-ws.herokuapp.com";

    @IBOutlet weak var upBtn: UIButton!
    @IBOutlet weak var downBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func tappedUp(sender: AnyObject) {
        print( WS_URL + "/up/" + "ilter")
        Alamofire.request(.GET, WS_URL + "/up/" + "ilter").responseJSON { response in
            print(response.data)     // server data
            print(response.result)

            if let JSON = response.result.value {
                print("JSON: \(JSON)")
            }
        }
    }

    @IBAction func tappedDown(sender: AnyObject) {
        Alamofire.request(.GET, WS_URL + "/down/" + "ilter")
    }

}

