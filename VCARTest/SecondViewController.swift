//
//  SecondViewController.swift
//  VCARTest
//
//  Created by François Lambert on 26/07/2018.
//  Copyright © 2018 François Lambert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class SecondViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusTextView: UITextView!
    
    var box: Box?
    var status: String?
    var startPosition: SCNVector3?
    var distance: Float?
    var trackingState: ARCamera.TrackingState?
    var mode: Mode = .waitingForMeasuring {
        didSet {
            switch mode {
            case .waitingForMeasuring:
                status = "NOT READY"
            case .measuring:
                box?.update(minExtents: SCNVector3Zero, maxExtents: SCNVector3Zero)
                box?.isHidden = false
                startPosition = nil
                distance = 0.0
            }
            setStatusText()
        }
    }
    
    enum Mode {
        case waitingForMeasuring
        case measuring
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        // Set a padding in the text view
        statusTextView.textContainerInset = UIEdgeInsetsMake(20.0, 10.0, 10.0, 0.0)
        // Instantiate the box and add it to the scene
        box = Box()
        box?.isHidden = true
        if let box = box { sceneView.scene.rootNode.addChildNode(box) }
        // Set the initial mode
        mode = .waitingForMeasuring
        // Set the initial distance
        distance = 0.0
        // Display the initial status
        setStatusText()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration with plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        trackingState = camera.trackingState
        setStatusText()
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender.isOn {
            mode = .measuring
        } else {
            mode = .waitingForMeasuring
        }
    }
    
    func setStatusText() {
        var text = "Status: \(status ?? "")\n"
        text += "Tracking: \(getTrackigDescription())\n"
        if let distance = distance { text += "Distance: \(String(format:"%.2f cm", distance * 100.0))" }
        statusTextView?.text = text
    }
    
    func getTrackigDescription() -> String {
        var description = ""
        if let t = trackingState {
            switch(t) {
            case .notAvailable:
                description = "TRACKING UNAVAILABLE"
            case .normal:
                description = "TRACKING NORMAL"
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    description =
                    "TRACKING LIMITED - Too much camera movement"
                case .insufficientFeatures:
                    description =
                    "TRACKING LIMITED - Not enough surface detail"
                case .initializing:
                    description = "INITIALIZING"
                case .relocalizing:
                    description = "RELOCALIZING"
                }
            }
        }
        return description
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Call the method asynchronously to perform
        //  this heavy task without slowing down the UI
        DispatchQueue.main.async {
            self.measure()
        }
    }
    
    func measure() {
        let screenCenter : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let planeTestResults = sceneView.hitTest(screenCenter, types: .featurePoint)
        if let result = planeTestResults.first {
            status = "READY"
            if mode == .measuring {
                status = "MEASURING"
                let worldPosition = SCNVector3Make(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )
                if startPosition == nil {
                    startPosition = worldPosition
                    box?.position = worldPosition
                }
                if let startPosition = startPosition {
                    distance = calculateDistance(from: startPosition, to: worldPosition)
                }
                if let distance = distance {
                    box?.resizeTo(extent: distance)
                }
                if let startPosition = startPosition {
                    let angleInRadians = calculateAngleInRadians(from: startPosition, to: worldPosition)
                    box?.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
                }
            }
        } else {
            status = "NOT READY"
        }
        setStatusText()
    }
    
    func calculateDistance(from: SCNVector3, to: SCNVector3) -> Float {
        let x = from.x - to.x
        let y = from.y - to.y
        let z = from.z - to.z
        return sqrtf( (x * x) + (y * y) + (z * z))
    }
    
    func calculateAngleInRadians(from: SCNVector3, to: SCNVector3) -> Float {
        let x = from.x - to.x
        let z = from.z - to.z
        return atan2(z, x)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class Box: SCNNode {
    
    lazy var box: SCNNode = makeBox()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeBox() -> SCNNode {
        let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
        return convertToNode(geometry: box)
    }
    
    func convertToNode(geometry: SCNGeometry) -> SCNNode {
        for material in geometry.materials {
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = false
        }
        let node = SCNNode(geometry: geometry)
        self.addChildNode(node)
        return node
    }
    
    func resizeTo(extent: Float) {
        var (min, max) = boundingBox
        max.x = extent
        update(minExtents: min, maxExtents: max)
    }
    
    func update(minExtents: SCNVector3, maxExtents: SCNVector3) {
        guard let scnBox = box.geometry as? SCNBox else {
            fatalError("Geometry is not SCNBox")
        }
        // Normalize the bounds so that min is always < max
        let absMin = SCNVector3(
            x: min(minExtents.x, maxExtents.x),
            y: min(minExtents.y, maxExtents.y),
            z: min(minExtents.z, maxExtents.z)
        )
        let absMax = SCNVector3(
            x: max(minExtents.x, maxExtents.x),
            y: max(minExtents.y, maxExtents.y),
            z: max(minExtents.z, maxExtents.z)
        )
        // Set the new bounding box
        boundingBox = (absMin, absMax)
        // Calculate the size vector
        let size = absMax - absMin
        // Take the absolute distance
        let absDistance = CGFloat(abs(size.x))
        // The new width of the box is the absolute distance
        scnBox.width = absDistance
        // Give it a offset of half the new size so they box remains fixed
        let offset = size.x * 0.5
        // Create a new vector with the min position
        // of the new bounding box
        let vector = SCNVector3(x: absMin.x, y: absMin.y, z: absMin.z)
        // And set the new position of the node with the offset
        box.position = vector + SCNVector3(x: offset, y: 0, z: 0)
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
