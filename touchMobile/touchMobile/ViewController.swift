//
//  ViewController.swift
//  TouchMobile
//
//  Created by Ilter Canberk on 3/15/16.
//  Copyright © 2016 ThemBoyz. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import Alamofire

let WS_URL = "http://touch-ws.herokuapp.com";
let NODE_STORAGE_KEY = "node"



class DopeRecognizer: UILongPressGestureRecognizer
{
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event);
        let delegate = self.delegate as! DopeRecognizerDelegate;
        delegate.gestureRecognizer(self, movedWithTouches: touches, Event: event);
    }
}


protocol DopeRecognizerDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizer(_:UIGestureRecognizer, movedWithTouches touches:Set<UITouch>, Event event:UIEvent);
}


class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,DopeRecognizerDelegate {

    @IBOutlet weak var nodesCollectionView: UICollectionView!
    @IBOutlet weak var resetBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func draggedView(sender:UIPanGestureRecognizer){
        print("Dragged veiw");
     
    }

    var initialTranslation:CGPoint? = nil;
    let bufferTranslation = 0;
    
    func tappedUp(nodeName: String) {
        print( WS_URL + "/up/" + nodeName)
        Alamofire.request(.GET, WS_URL + "/up/" + nodeName);
    }
    
    func tappedDown(nodeName: String) {
        print( WS_URL + "/down/" + nodeName)
        Alamofire.request(.GET, WS_URL + "/down/" + nodeName);
    }
    
    func swiped(nodeName: String, distance:Int) {
        Alamofire.request(.GET, WS_URL + "/swipe/" + nodeName + "/" + distance);
    }

    func tappedView(sender:DopeRecognizer){

        let cell:NodeCell = sender.view as! NodeCell;
        let translation = sender.locationInView(cell);
        cell.touchDotImg.frame.origin.x =  translation.x - cell.touchDotImg.frame.width/2;
        cell.touchDotImg.frame.origin.y = translation.y - cell.touchDotImg.frame.height/2;

        // do other task
        if sender.state == .Began {

            UIView.animateWithDuration(0.15, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.touchDotImg.alpha = 1.0
            }, completion: nil)
            
            initialTranslation = translation;
        }
        
        if sender.state == .Changed
        {
            if initialTranslation != nil {
                let distance = initialTranslation!.y - translation.y;
                print(distance);
                
                if (distance > 50) {
                    //send up
                    initialTranslation = translation;
                }
                else if (distance < -50) {
                    //send down
                    initialTranslation = translation;
                    tappedDown(cell.nodeName);
                }
                
            }
        }
        if sender.state == .Ended {
            print("ended")
            if initialTranslation != nil {
                let distance = initialTranslation!.y - translation.y;
                swiped(cell.nodeName, distance);
            }
    
            let frame: CGRect = CGRect.init(x: cell.touchDotImg.center.x, y: cell.touchDotImg.center.y, width: 0, height: 0);

            UIView.animateWithDuration(0.15, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.touchDotImg.alpha = 0.0
            }, completion: nil)
            
            initialTranslation = nil;
        }
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

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! NodeCell;
        cell.nodeName = currentArray[indexPath.item] as! String;
        cell.nameLabel.text = currentArray[indexPath.item] as! String;
        
        let gestureRec = DopeRecognizer()
        gestureRec.addTarget(self, action: Selector("tappedView:"));
        gestureRec.delegate = self;
        gestureRec.minimumPressDuration = 0.05;
        gestureRec.numberOfTouchesRequired = 1;
        cell.addGestureRecognizer(gestureRec);
        // Configure the cell
        return cell
    }

    func gestureRecognizer(sender:UIGestureRecognizer, movedWithTouches touches:Set<UITouch>, Event event:UIEvent) {
        
        let cell:NodeCell = sender.view as! NodeCell;
        print(touches.count);
        for touch in touches {

            var size:CGFloat = 80.00;
            if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available
            {
                size = size + (touch.force/touch.maximumPossibleForce) * 120;
            }

            let frame: CGRect =
                CGRectMake( cell.touchDotImg.frame.origin.x , cell.touchDotImg.frame.origin.y, size, size);
            cell.touchDotImg.frame = frame;
            
        }
    }


    @IBAction func tappedResetBtn(sender: AnyObject) {
        flushNodes();
        self.nodesCollectionView.reloadData();
    }

}


class NodeCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!

    var nodeName = "";

    @IBOutlet weak var touchDotImg: UIImageView!


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

    @IBAction func tappedUpBtn(sender: UIButton) {
        tappedUp(self.nodeName);
    }

    @IBAction func tappedDownBtn(sender: UIButton) {
        tappedDown(self.nodeName);
    }

}

