//
//  ViewController.swift
//  AdSpecter_v1
//
//  Created by John Li on 11/18/17.
//  Copyright © 2017 John Li. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate {

    /*********************************************
     *  Declarations for displaying images as ads
     *********************************************/
    
    let AD_PLANE_MAXIMUM_RATIO : CGFloat = 0.7
    let AD_ASSET_URL_1 : String = "http://127.0.0.1:3000/test"
    let AD_ASSET_URL_2 : String = "https://i.pinimg.com/originals/c1/3d/9d/c13d9d84539c69dbf22de3ec0fd5f86e.jpg"
    let AD_ASSET_URL_3 : String = "http://static.adweek.com/adweek.com-prod/files/2016_Jan/coke-taste-the-feeling-13.jpg"
    
    // array below incorporates AD_ASSET_URL_2 and AD_ASSET_URL_3 - used for carousel of changing ads
    var adAssets: [String] = ["https://i.pinimg.com/originals/c1/3d/9d/c13d9d84539c69dbf22de3ec0fd5f86e.jpg", "http://static.adweek.com/adweek.com-prod/files/2016_Jan/coke-taste-the-feeling-13.jpg"]
    var currentAdIndex = 0
    
    
    /**********************************************
     *  Declarations for displaying GIFs as ads
     **********************************************/
    
    var GIF_URL : String = "https://media.giphy.com/media/xUNd9VAKHbmuW6HA4M/giphy.gif"
    var currentGIFImageIndex = 0
    var gridMaterial = SCNMaterial()
    var GIFImagesArray = [CGImage]()
    var currentGIFImage : UIImage = UIImage()
    var timer: Timer!
    
    
    /**********************************************
     *  Universal declarations
     **********************************************/
    
    var hasAdBeenPlacedInCurrentView : Bool = false
    var image : UIImage?
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Debug purposes - shows real world surfaces
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.autoenablesDefaultLighting = true
        
        /******************************************************
         *  Used for displaying GIFs - comment out for images
         *  Initiate images array for given GIF URL
         ******************************************************/
        let bundleURL = URL(string: GIF_URL)
        let imageData = try? Data(contentsOf: bundleURL!)
        let source = CGImageSourceCreateWithData(imageData as! CFData, nil)

        initiateGIFImagesArray(source: source!)

        scheduledTimerWithTimeInterval()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        let url = URL(string: AD_ASSET_URL_2)
        let data = try? Data(contentsOf: url!)
        self.image = UIImage(data: data!)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func scheduledTimerWithTimeInterval() {
//        print("Timer scheduled")
        timer = Timer.scheduledTimer(timeInterval: 0.067265, target: self, selector: #selector(ViewController.animateGIF), userInfo: nil, repeats: true)
    }
    
    
    @objc func animateGIF() {
//        print("************* begin animating image *************")
//        print("currentGIFImageIndex \(currentGIFImageIndex)")
        
        if currentGIFImageIndex >= GIFImagesArray.count {
            currentGIFImageIndex = 0
        }
        
        let currentCGImage : CGImage = GIFImagesArray[currentGIFImageIndex]
        
        currentGIFImage = UIImage(cgImage: currentCGImage)
        gridMaterial.diffuse.contents = currentGIFImage
        
        currentGIFImageIndex += 1
        
//        print("************* finish animating image *************")
    }
    
    func setImage() {
        print("setting image")
        if self.currentAdIndex == 0 {
            self.currentAdIndex = 1
        } else {
            self.currentAdIndex = 0
        }
        
        let url = URL(string: self.adAssets[self.currentAdIndex])
        let data = try? Data(contentsOf: url!)
        self.image = UIImage(data: data!)
        
        self.gridMaterial.diffuse.contents = self.image
    }
    
    
    // detects first horizontal plane and places ad asset (image or GIF) onto it
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor && !hasAdBeenPlacedInCurrentView {
            print("anchor detected")
            let planeAnchor = anchor as! ARPlaneAnchor

            let planeWidth : CGFloat = CGFloat(planeAnchor.extent.x)
            let planeHeight : CGFloat = CGFloat(planeAnchor.extent.z)

            // Use at most AD_PLANE_MAXIMUM_RATIO of the width and height
            let maximumWidth : CGFloat = planeWidth * AD_PLANE_MAXIMUM_RATIO
            let maximumHeight : CGFloat = planeHeight * AD_PLANE_MAXIMUM_RATIO

//            print("maximumHeight \(maximumHeight)")
//            print("maximumWidth \(maximumWidth)")
//
//            print("anchor center x \(planeAnchor.center.x)")
//            print("anchor center z \(planeAnchor.center.z)")

            let assetWidth : CGFloat = maximumWidth
            let assetHeight : CGFloat = assetWidth * 4 / 3

            let plane = SCNPlane(width: assetHeight, height: assetWidth)

            let planeNode = SCNNode()

            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)

            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)

            /*******************************************************
             *  Used for displaying images - comment out for GIFs
             *  Changes ad every 10 seconds
             *******************************************************/
//            gridMaterial.diffuse.contents = image

            plane.materials = [gridMaterial]

            planeNode.geometry = plane

            self.currentGIFImageIndex = 0

            node.addChildNode(planeNode)

            self.hasAdBeenPlacedInCurrentView = true

            /*****************************************************
             *  Used for displaying GIFs - comment out for images
             *  Sets timer to animate each frame of the given GIF
             *****************************************************/
            scheduledTimerWithTimeInterval()
            
            /*****************************************************
             *  Used for displaying images - comment out for GIFs
             *  Changes ad every 10 seconds
             *****************************************************/
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
//                self.setImage()
//            }
        }
    }
    
    func initiateGIFImagesArray(source: CGImageSource) {
//        print("************* begin initiating images *************")
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        
//        print("count: \(count)")
        
        // Fill arrays
        for i in 0..<count {
            // Add image
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
        }
        
//        print("************* finish initiating images *************")
        
        self.GIFImagesArray = images
    }
    
    
    //MARK: - IGNORE ALL CODE BELOW
    /***************************************************************/
    
    
    
    //MARK: - Networking
    /***************************************************************/
    
    func getAdAsset(url: String) {
        Alamofire.request(url, method: .get).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success! Got the ad asset")
                
                let adJSON : JSON = JSON(response.result.value!)
                print("assetURL \(adJSON["image_url"])")
                
                let url = URL(string: adJSON["image_url"].string!)
                let data = try? Data(contentsOf: url!)
                self.image = UIImage(data: data!)
                
//                self.updateWeatherData(json: weatherJSON)
                
                //                print(weatherJSON)
            } else {
                print("Error \(response.result.error)")
            }
        }
    }
    
    //MARK: - JSON Parsing
    /***************************************************************/
    func updateImpressionData(json : JSON) {
        let tempResult = json["developer_app"]["name"]
        print("tempResult: \(tempResult)")
        
//        if let tempResult = json["developer_app"]["name"] {
//            print("tempResult: \(tempResult)")
//        }
//        else {
//            print("Ad Unavailable")
//        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
