//
//  AlarmsViewController.swift
//  TouchMobile
//
//  Created by ican on 4/26/16.
//  Copyright © 2016 ThemBoyz. All rights reserved.
//

import Foundation
import UIKit
import Parse
import SwiftyJSON

class Alarm {
    var name:String?
    var time:NSDate?
}

class AlarmsViewController:UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    let cellIdentifier = "AlarmTableViewCell"
    var alarmsTableView:UITableView? = nil
    var alarms:[Alarm] = []

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return alarms.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:AlarmCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! AlarmCell
        
        let alarm:Alarm = self.alarms[indexPath.item];
        // Configure the cell...
        cell.nameLabel.text = String(alarm.time)
        return cell
    }
    
    func hideTable () {
        alarms = []
        self.alarmsTableView!.alpha = 0
    }
    
    func displayTable () {
        
    }
    
    func updateForNode (node:Node) {
        
        PFCloud.callFunctionInBackground("getAlarms", withParameters: ["nodeId": node.objectId]) {
            (alarms, error) in
            if (error == nil) {
                self.transformAlarmResults(alarms!)
                self.alarmsTableView!.reloadData()
                self.displayTable();
            }
            else {
                print("Error with getting alarms")
            }
        }

    }
    
    func transformAlarmResults (alarms:AnyObject) {
        self.alarms = [Alarm]()
        let alarmsJSON = JSON(alarms);
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSSSxxx"
        
        for (_,alarm) in alarmsJSON {
            let a = Alarm()
            a.name = alarm["name"].stringValue
            a.time = dateFormatter.dateFromString(alarm["time"].stringValue)
            self.alarms.append(a)
        }
    }

    
}

class AlarmCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
}

