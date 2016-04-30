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

let WS_URL = "http://touch-mobile-cloud.herokuapp.com";
let PI_URL = "http://touchpi.wv.cc.cmu.edu:5000";

class Node {
    var name:String = "Unnamed"
    var macAddress:String = ""
    var objectId:String = ""
    var position:Int = 0
    var lowPowerOn:Bool = false
    var isLowBattery:Bool = false
    var isFound:Bool = true
    var range:Int = 100
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
    @IBOutlet var addAlarmBtn: UIButton!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var saveAlarmBtn: UIButton!

    var nodesArray = [Node]()
    var alarmsViewController:AlarmsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.alarmsViewController = AlarmsViewController()

        self.alarmsTableView.delegate = alarmsViewController
        self.alarmsTableView.dataSource = alarmsViewController
        self.alarmsViewController!.alarmsTableView = self.alarmsTableView
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "retrieveAllNodes", userInfo: nil, repeats: true)

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
    

    func moveToPosition(node: Node, position:CGFloat) {
        var pos = Int(position)
        let buffer = ((100 - node.range) / 2) * 4;
        if (pos < buffer) { pos = buffer }
        if (pos > (400-buffer)) { pos = (400-buffer) }
        
        print(position)

        Alamofire.request(.GET, PI_URL + "/p/" + String(pos) + "/" + node.macAddress);
        print("/p/" + String(pos) + "/" + node.macAddress)
        node.position = Int(position)
    }
    
    func savePosition(node: Node, position:CGFloat) {
        print(position)
        var pos:Int = Int(position)
        let buffer = (100 - node.range) / 2;
        if (pos < buffer) { pos = buffer }
        if (pos > (400-buffer)) { pos = (400-buffer) }
        
        PFCloud.callFunctionInBackground("updateNodePosition", withParameters: ["nodeId":node.objectId, "position": pos]) {
            (result, error) in

            if (error == nil) {
//                self.transformNodeResults(nodes!)
//                self.nodesCollectionView.reloadData()
            }
            else {
                print("Error with getting nodes")
            }

        }
    }

    func tappedView(sender:DopeRecognizer){
    
        let cell:NodeCell = sender.view?.superview?.superview as! NodeCell;
        let translation = sender.locationInView(cell);
        cell.touchDotImg.frame.origin.x =  translation.x - cell.touchDotImg.frame.width/2;
        cell.touchDotImg.frame.origin.y = translation.y - cell.touchDotImg.frame.height/2;
        let pos = translation.y;

        // do other task
        if sender.state == .Began {

            UIView.animateWithDuration(0.15, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.touchDotImg.alpha = 1.0
            }, completion: nil)
            
            self.moveToPosition(cell.node!, position: pos);
        }
        
        if sender.state == .Changed
        {
            
            if (pos % 20 == 0) {
                self.moveToPosition(cell.node!, position: pos);
            }
        }
        if sender.state == .Ended {

            self.moveToPosition(cell.node!, position: pos);
            self.savePosition(cell.node!, position: pos);

            UIView.animateWithDuration(0.15, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.touchDotImg.alpha = 0.5
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
            let thirdTextField = alertController.textFields![2] as UITextField
            let range = Int(thirdTextField.text!);
            self.storeNewNode(nodeName!, macAddress: macAddress!, range: range!);
            self.nodesCollectionView.reloadData();
            
            self.retrieveAllNodes();
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
        alertController.addTextFieldWithConfigurationHandler {(textField: UITextField!) in
            textField.placeholder = "Range"
        };
        alertController.addAction(saveAction);
        alertController.addAction(cancelAction);

        
        self.presentViewController(alertController, animated: true, completion: nil)
    }


    func retrieveAllNodes () {
        print("Retrieving")
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
            n.position = node["position"].intValue
            n.lowPowerOn = node["isLowPowerOn"].boolValue
            n.isLowBattery = node["lowBattery"].boolValue
            n.isFound = node["isFound"].boolValue
            n.range = node["range"].intValue

            self.nodesArray.append(n)
        }
    }

    // STORAGE

    func storeNewNode (nodeName:String, macAddress:String, range:Int) {
        PFCloud.callFunctionInBackground("createNewNode", withParameters:
            ["name": nodeName, "macAddress": macAddress, "range": range]) {
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
        
        cell.touchDotImg.frame.origin.x =  cell.frame.size.width/2 - cell.touchDotImg.frame.width/2;
        cell.touchDotImg.frame.origin.y = CGFloat((cell.node?.position)!)
        cell.touchDotImg.alpha = 0.5
        
        if (cell.node!.isLowBattery) { cell.lowBatteryImg.hidden = false }
        else { cell.lowBatteryImg.hidden = true }

        if (cell.node!.lowPowerOn) {
            cell.lbBtn.setTitle("Turn LP Off", forState: UIControlState.Normal)
        }
        
        if (cell.node!.isFound) { cell.nodeBg.image = UIImage(named: "nodeBg") }
        else { cell.nodeBg.image = UIImage(named: "nodeBgNotFound") }

        return cell
    }

    func gestureRecognizer(sender:UIGestureRecognizer, movedWithTouches touches:Set<UITouch>, Event event:UIEvent) {
        
        let cell:NodeCell = sender.view?.superview?.superview as! NodeCell;
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
        PFUser.logOut()
        dispatch_async(dispatch_get_main_queue()){
            self.performSegueWithIdentifier("displayLoginView", sender: self)
        }
    }
    
    var alarmModeOn = false
    var prevPosition:CGFloat = 0.0

    func toggleAlarmsViewForNode (node:Node) -> Bool {
        
        if (!alarmModeOn) {
        // animation position over 1.0 second duration
            let curFrame = self.nodesCollectionView.frame
            prevPosition = curFrame.origin.y + (curFrame.height / 2)
            
            let springAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            springAnimation.toValue =  NSValue(CGPoint: CGPointMake(10, 0));
            springAnimation.velocity = NSValue(CGPoint: CGPointMake(0.3, 0.3))
            springAnimation.springBounciness = 14.0
            self.self.nodesCollectionView.pop_addAnimation(springAnimation, forKey: "springAnimation")
            
            alarmsViewController!.updateForNode(node)
            alarmModeOn = true;
        }
        else {

            let springAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPositionY)
            springAnimation.toValue =  NSValue(CGPoint: CGPointMake(prevPosition, 0));
            springAnimation.velocity = NSValue(CGPoint: CGPointMake(0.5, 0.5))
            springAnimation.springBounciness = 14.0
            self.self.nodesCollectionView.pop_addAnimation(springAnimation, forKey: "springAnimationDown")
    
            alarmModeOn = false;
        }
        
        return alarmModeOn
    }
    
    @IBAction func tappedAddAlarm(sender: AnyObject) {
        self.alarmsTableView.hidden = true
        self.addAlarmBtn.hidden = true
        self.datePicker.hidden = false
        self.saveAlarmBtn.hidden = false
    }
    
    @IBAction func tappedSaveAlarm(sender: AnyObject) {
        let pickedDate = datePicker.date
        let node = self.alarmsViewController?.currentNode!
        
        PFCloud.callFunctionInBackground("createNewAlarm", withParameters:["datetime":pickedDate.timeIntervalSince1970,
            "nodeId" : node!.objectId,
            "position" : node!.position,
            "macAddress" : node!.macAddress,
        ]){
            (alarms, error) in
            
            if (error == nil) {
                self.alarmsViewController?.transformAlarmResults(alarms!)
                self.datePicker.hidden = true
                self.saveAlarmBtn.hidden = true
                self.alarmsTableView.hidden = false
                self.addAlarmBtn.hidden = false
            }
            else {
                print("Error with creating alarm")
            }

        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayLoginView" {
            if let loginViewController = segue.destinationViewController as? LoginViewController {
                loginViewController.mainViewController = self
            }
        }
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
    
    @IBOutlet var nodeBg: UIImageView!
    @IBOutlet var lbBtn: UIButton!
    @IBOutlet var lowBatteryImg: UIImageView!
    
    @IBAction func tappedAddAlarm(sender: AnyObject) {
        let isOnAlarmsMode:Bool = (self.parentViewController?.toggleAlarmsViewForNode(self.node!))!
        
        if (isOnAlarmsMode == true) {
            addAlarmBtn.setTitle("Done", forState: UIControlState.Normal)
        }
        else {
            addAlarmBtn.setTitle("Set Alarms", forState: UIControlState.Normal)
        }
    }

    @IBAction func tappedLpBtn(sender: AnyObject) {
        
        if (self.node!.lowPowerOn) {
            Alamofire.request(.GET, WS_URL + "/lowpower/" + (self.node?.macAddress)! + "/0");
            lbBtn.setTitle("Turn LP on", forState: UIControlState.Normal)
            node?.lowPowerOn = false
        }
        else {
            Alamofire.request(.GET, WS_URL + "/lowpower/" + (self.node?.macAddress)! + "/1");
            lbBtn.setTitle("Turn LP off", forState: UIControlState.Normal)
            node?.lowPowerOn = true
        }
    }
    
}

