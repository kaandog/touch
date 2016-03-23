//
//  ViewController.swift
//  TouchMobile
//
//  Created by Ilter Canberk on 3/15/16.
//  Copyright © 2016 ThemBoyz. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    let WS_URL = "http://touch-ws.herokuapp.com";
    let NODE_STORAGE_KEY = "node"

    @IBOutlet weak var nodesCollectionView: UICollectionView!
    @IBOutlet weak var resetBtn: UIButton!

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

    @IBOutlet weak var plusButton: UIButton!
    



    @IBAction func plusButtonTapped(sender: AnyObject) {
        
        let alertController = UIAlertController(title: "New Touch", message: "Please put the node identification number", preferredStyle: .Alert);

        
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler: {
            alert -> Void in
            
            let firstTextField = alertController.textFields![0] as UITextField
            let nodeName = firstTextField.text;
            self.storeNewNode(nodeName!);
            self.nodesCollectionView.reloadData();
            let nodes = self.retrieveAllNodes();
            print(nodes);
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })

        alertController.addTextFieldWithConfigurationHandler {(textField: UITextField!) in
            textField.placeholder = "Node id"
        };
        alertController.addAction(saveAction);
        alertController.addAction(cancelAction);

        
        self.presentViewController(alertController, animated: true, completion: nil)
    }


    func retrieveAllNodes () -> NSMutableArray {
        let defaults = NSUserDefaults.standardUserDefaults();

        //read
        if let nodesArray : AnyObject = defaults.objectForKey(NODE_STORAGE_KEY) {
            let readArray = nodesArray as! NSMutableArray;
            return readArray;
        }
        else {
            return [];
        }
    }

    // STORAGE

    func storeNewNode (nodeName:String) {
        let currentArray : NSMutableArray = self.retrieveAllNodes();
        let currentMutableArray = NSMutableArray(array: currentArray)
        currentMutableArray.addObject(nodeName);

        //save
        let defaults = NSUserDefaults.standardUserDefaults();
        defaults.setObject(currentMutableArray, forKey: NODE_STORAGE_KEY);
        defaults.synchronize();
    }
    
    func flushNodes () {
        //save
        let defaults = NSUserDefaults.standardUserDefaults();
        defaults.setObject([], forKey: NODE_STORAGE_KEY);
        defaults.synchronize();
    }

    
    ////////
    
    private let reuseIdentifier = "NodeCell"

    //1
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    //2
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let currentArray : NSMutableArray = self.retrieveAllNodes();
        return currentArray.count;
    }
    
    //3
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let currentArray : NSMutableArray = self.retrieveAllNodes();

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        cell.backgroundColor = UIColor.redColor();
        let label:UILabel = cell.viewWithTag(1) as! UILabel;
        label.text = currentArray[indexPath.item] as! String;
        // Configure the cell
        return cell
    }
    
    @IBAction func tappedResetBtn(sender: AnyObject) {
        flushNodes();
        self.nodesCollectionView.reloadData();
    }

    
}

