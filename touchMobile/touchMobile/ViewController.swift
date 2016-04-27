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
import Parse
import SwiftyJSON
import pop

let WS_URL = "http://touch-ws.herokuapp.com";
let NODE_STORAGE_KEY = "node"

class Node {
    var name:String = "Unnamed"
    var macAddress:String = ""
    var objectId:String = ""
}

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
    @IBOutlet weak var alarmsTableView: UITableView!

    var nodesArray = [Node]()
    var alarmsViewController:AlarmsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.alarmsViewController = AlarmsViewController()

        self.alarmsTableView.delegate = alarmsViewController
        self.alarmsTableView.dataSource = alarmsViewController
        self.alarmsViewController!.alarmsTableView = self.alarmsTableView
        retrieveAllNodes()
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
        Alamofire.request(.GET, WS_URL + "/m/" + nodeName + "/" + String(distance));
    }

    func tappedView(sender:DopeRecognizer){
    
        let cell:NodeCell = sender.view?.superview?.superview as! NodeCell;
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
                swiped(cell.node?.macAddress, distance: Int(distance));
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
            let secondTextField = alertController.textFields![1] as UITextField
            let macAddress = secondTextField.text;
            self.storeNewNode(nodeName!, macAddress: macAddress!);
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
        alertController.addTextFieldWithConfigurationHandler {(textField: UITextField!) in
            textField.placeholder = "Mac address"
        };
        alertController.addAction(saveAction);
        alertController.addAction(cancelAction);

        
        self.presentViewController(alertController, animated: true, completion: nil)
    }


    func retrieveAllNodes () {
        
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            
            PFCloud.callFunctionInBackground("getAllNodes", withParameters: [:]) {
                (nodes, error) in
                if (error == nil) {
                    self.transformNodeResults(nodes!)
                    self.nodesCollectionView.reloadData()
                }
                else {
                    print("Error with getting nodes")
                }
            }

        } else {
            dispatch_async(dispatch_get_main_queue()){
                
                self.performSegueWithIdentifier("displayLoginView", sender: self)
                
            }
        }
    }
    
    func transformNodeResults (nodes:AnyObject) {
        self.nodesArray = [Node]()
        let nodesJSON = JSON(nodes);
        
        for (_,node) in nodesJSON {
            let n = Node()
            n.name = node["name"].stringValue
            n.macAddress = node["macAddress"].stringValue
            n.objectId = node["objectId"].stringValue
            self.nodesArray.append(n)
        }
    }

    // STORAGE

    func storeNewNode (nodeName:String, macAddress:String) {
        PFCloud.callFunctionInBackground("createNewNode", withParameters:
            ["name": nodeName, "macAddress": macAddress]) {
            (nodes, error) in
            if (error == nil) {
                self.transformNodeResults(nodes!);
                self.nodesCollectionView.reloadData()
            }
            else {
                print("Error with getting nodes")
            }
        }
        
        let newNode = Node()
        newNode.name = nodeName
        newNode.macAddress = macAddress
        self.nodesArray.append(newNode)
    }

    
    ////////
    
    private let reuseIdentifier = "NodeCell"

    //1
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    //2
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.nodesArray.count;
    }
    
    //3
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let currentArray : [Node] = self.nodesArray

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! NodeCell
        cell.nodeName = currentArray[indexPath.item].name
        cell.nameLabel.text = currentArray[indexPath.item].name
        cell.parentViewController = self
        cell.node = currentArray[indexPath.item]
        let gestureRec = DopeRecognizer()
        gestureRec.addTarget(self, action: #selector(ViewController.tappedView(_:)));
        gestureRec.delegate = self;
        gestureRec.minimumPressDuration = 0.05;
        gestureRec.numberOfTouchesRequired = 1;
        cell.touchAreaView.addGestureRecognizer(gestureRec);
        // Configure the cell
        return cell
    }

    func gestureRecognizer(sender:UIGestureRecognizer, movedWithTouches touches:Set<UITouch>, Event event:UIEvent) {
        
        let cell:NodeCell = sender.view?.superview?.superview as! NodeCell;
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
//        self.showAlarmsViewForNode(nil)
    }
    
    var alarmModeOn = false
    var prevPosition:CGFloat = 0.0

    func toggleAlarmsViewForNode (node:Node) -> Bool {
        
        if (!alarmModeOn) {
        // animation position over 1.0 second duration
            let curFrame = self.nodesCollectionView.frame
            prevPosition = curFrame.origin.y
            
            let springAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            springAnimation.toValue =  NSValue(CGPoint: CGPointMake(10, 10));
            springAnimation.velocity = NSValue(CGPoint: CGPointMake(1.1, 1.1))
            springAnimation.springBounciness = 20.0
            self.self.nodesCollectionView.pop_addAnimation(springAnimation, forKey: "springAnimation")
            
            alarmsViewController!.updateForNode(node)
            alarmModeOn = true;
        }
        else {

            let springAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            springAnimation.toValue =  NSValue(CGPoint: CGPointMake(10, prevPosition));
            springAnimation.velocity = NSValue(CGPoint: CGPointMake(1.1, 1.1))
            springAnimation.springBounciness = 20.0
            self.self.nodesCollectionView.pop_addAnimation(springAnimation, forKey: "springAnimation")
    
            alarmModeOn = false;
        }
        
        return alarmModeOn
    }

}


class NodeCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    var node:Node?;
    var nodeName = "";
    var parentViewController:ViewController?;
    @IBOutlet weak var touchDotImg: UIImageView!
    @IBOutlet var addAlarmBtn: UIButton!
    @IBOutlet var touchAreaView: UIView!
    
    
    @IBAction func tappedAddAlarm(sender: AnyObject) {
        let isOnAlarmsMode:Bool = (self.parentViewController?.toggleAlarmsViewForNode(self.node!))!
        
        if (isOnAlarmsMode == true) {
            addAlarmBtn.setTitle("Done", forState: UIControlState.Normal)
        }
        else {
            addAlarmBtn.setTitle("Set Alarms", forState: UIControlState.Normal)
        }
    }

}

