//
//  ViewController.swift
//  360Video
//
//  Created by idz on 5/1/16.
//  Copyright © 2016 iOS Developer Zone.
//  License: MIT https://raw.githubusercontent.com/iosdevzone/PanoView/master/LICENSE
//  Modified by bnlcas on 2023-01-23
//

import UIKit
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation

class ViewController: UIViewController {
    
    let motionManager = CMMotionManager()
    let cameraNode = SCNNode()
    var sphereNode = SCNNode()
    let spriteScene = SKScene()
    var queue: OperationQueue!
    //var deviceQueue = OperationQueue()
    
    var timer = Timer()
    
    var player : AVPlayer?
    var playerSlow : AVPlayer?
    
    @IBOutlet weak var sceneView: SCNView!
    
    @IBOutlet var button: UIButton!
    
    var video_ind = 0
    @IBAction func SwapVideo()
    {
        video_ind += 1

        let oldVideoNode = self.spriteScene.childNode(withName: "videoTexture")
        oldVideoNode?.removeFromParent()
        
        var videoNode : SKVideoNode?
        if(video_ind % 2 == 0){
            videoNode = SKVideoNode(avPlayer: player!)
            player?.play()
            playerSlow?.pause()
        }
        else
        {
            videoNode = SKVideoNode(avPlayer: playerSlow!)
            player?.pause()
            playerSlow?.play()
        }

        let size = CGSizeMake(3840,1920)
        videoNode!.size = size
        videoNode!.position = CGPointMake(size.width/2.0,size.height/2.0)
        videoNode!.name = "videoTexture"
        self.spriteScene.addChild(videoNode!)
    }
    
    func createVideoMaterials() {
        if let fileURL = Bundle.main.url(forResource: "ball_play", withExtension: "mp4"){
            // we found the file in our bundle!

            player =  AVPlayer(url: fileURL)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
                self.player!.seek(to: CMTime.zero)
                self.player!.play()
            }
            
            player?.play()
            
            let videoNode = SKVideoNode(avPlayer: player!)
            let size = CGSizeMake(3840,1920)
            videoNode.size = size
            videoNode.position = CGPointMake(size.width/2.0,size.height/2.0)
            videoNode.name = "videoTexture"
            self.spriteScene.size = size
//    = SKScene(size: size)
            self.spriteScene.addChild(videoNode)
        }
        
        if let fileURL = Bundle.main.url(forResource: "slow_150_reencode", withExtension: "mp4"){
            // we found the file in our bundle!
            
            playerSlow =  AVPlayer(url: fileURL)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
                self.playerSlow!.seek(to: CMTime.zero)
                self.playerSlow!.play()
            }
        }
    }
    
    func createSphereNode(material: AnyObject?) -> SCNNode {
        let sphere = SCNSphere(radius: 20.0)
        sphere.firstMaterial!.isDoubleSided = true
        sphere.firstMaterial!.diffuse.contents = material
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3Make(0,0,0)
        sphereNode.eulerAngles = SCNVector3Make(0,Float.pi, Float.pi)
        return sphereNode
    }
    
    func configureScene(node sphereNode: SCNNode) {
        // Set the scene
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.showsStatistics = false
        sceneView.allowsCameraControl = false
        //sceneView.cameraControlConfiguration.allowsTranslation = false
        //sceneView.cameraControlConfiguration = cam
        // Camera, ...
        cameraNode.camera = SCNCamera()
        //cameraNode.camera?.fieldOfView = 30;
        cameraNode.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(sphereNode)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func orientationFromCMQuaternion(_ q: CMQuaternion) -> SCNQuaternion
    {
        // add a rotation of the pitch 90 degrees

        let gq1 = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(-90), 1, 0, 0)
        let pose =  GLKQuaternionMake(Float(q.x), Float(q.y), Float(q.z), Float(q.w));

        let offsetQuat = GLKQuaternionMultiply(gq1, pose)
        
        let gq2 = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(90), 0, 0, 1)
        
        // the current orientation
        // get the "new" orientation
        let qp  =  GLKQuaternionMultiply(offsetQuat, gq2);
        //let rq =  CMQuaternion(.x = qp.x, .y = qp.y, .z = qp.z, .w = qp.w);

        return SCNVector4Make(qp.x, qp.y, qp.z, qp.w);
    }
    
    func startCameraTracking() {
        queue = OperationQueue.current
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
       // motionManager.set .attitudeReferenceFrame = .xArbitraryCorrectedZVertical

        let updatePose: (CMDeviceMotion?, Error?) -> Void = {motion, err in
            let attitude: CMAttitude? = motion?.attitude
            self.cameraNode.orientation = self.orientationFromCMQuaternion(attitude!.quaternion)
            //x: Float(attitude!.roll)
            //z: Float(attitude!.yaw))
            //SCNVector4Make(Float(attitude!.quaternion.x),Float(attitude!.quaternion.y),Float(attitude!.quaternion.z), Float(attitude!.quaternion.w))
        }
        
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue, withHandler: updatePose)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createVideoMaterials()
        sphereNode = createSphereNode(material: self.spriteScene)
        configureScene(node: sphereNode)
        guard motionManager.isDeviceMotionAvailable else {
            fatalError("Device motion is not available")
        }
        startCameraTracking()
        
        
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pincheGestureHandler))
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(pinchGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureHandler))
        self.view.addGestureRecognizer(panGesture)
        
    }
    
    var pinchGesture = UIPinchGestureRecognizer()
    var panGesture = UIPanGestureRecognizer()

    //var panGestures = UIPanGestureRecognizer()
    
    override func viewDidAppear(_ animated: Bool) {
        sceneView.play(self)
    }
    
    var yViewAngle = Float.pi
    @objc func panGestureHandler(recognizer:UIPanGestureRecognizer)
    {
        let panDist : CGPoint = recognizer.translation(in: self.view)
        
        let panAmp = Float(0.05)
        if(recognizer.state == .ended) {
            yViewAngle += panAmp * Float(panDist.x)
        }
        else
        {
            let currentYAngle = yViewAngle + panAmp * Float(panDist.x)
            //let maxAngle = Float.pi*0.6
            //let xPan = max(-maxAngle, min(maxAngle, Float(panDist.y)))
            self.sphereNode.eulerAngles = SCNVector3Make(0.0,currentYAngle, Float.pi)
        }
    }
    
    @objc func pincheGestureHandler(recognizer:UIPinchGestureRecognizer){
        //recognizer.view?.transform = (recognizer.view?.transform)!.scaledBy(x: recognizer.scale, y: recognizer.scale)
        //print(self.cameraNode.camera!.fieldOfView)
        
        
        var scale : CGFloat = 1.0 / recognizer.scale
        if(self.cameraNode.camera!.fieldOfView > CGFloat(75.0))
        {
            scale = CGFloat.minimum(scale, CGFloat(1.0))
        }
        if(self.cameraNode.camera!.fieldOfView < CGFloat(30.0))
        {
            scale = CGFloat.maximum(scale, CGFloat(1.0))
        }
        self.cameraNode.camera!.fieldOfView *= scale// * self.cameraNode.camera!.fieldOfView)
        
        recognizer.scale = 1.0
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

