//
//  ThirdViewController.swift
//  VCARTest
//
//  Created by François Lambert on 30/07/2018.
//  Copyright © 2018 François Lambert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ThirdViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusTextView: UITextView!
    
    var nodes: [SphereNode] = []
    var labels: [LabelNode] = []
    var trackingState: ARCamera.TrackingState?
    var distance: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        
        // Set the initial distance
        distance = 0.0
        // Display the initial status
        setStatusText()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapClear(_ sender: UIButton) {
        nodes.removeAll()
        labels.removeAll()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        distance = 0.0
        setStatusText()
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        if let result = hitTestResults.first {
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            let sphere = SphereNode(position: position)
            let label = LabelNode(position: position, index: nodes.count + 1)
            sceneView.scene.rootNode.addChildNode(sphere)
            sceneView.scene.rootNode.addChildNode(label)
            let lastNode = nodes.last
            nodes.append(sphere)
            labels.append(label)
            if let lastNode = lastNode {
                distance = lastNode.position.distance(to: sphere.position)
                
                let line = SCNNode.lineNode(from: lastNode.position, to: sphere.position)
//                let line = SCNNode(geometry: SCNGeometry.lineFrom(vector: lastNode.position, toVector: sphere.position))
                sceneView.scene.rootNode.addChildNode(line)
            }
            setStatusText()
        }
    }
    
    // MARK: ARSCNViewDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        trackingState = camera.trackingState
        setStatusText()
    }
    
    func setStatusText() {
        var text = "Tracking: \(getTrackigDescription())\n"
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

class SphereNode: SCNNode {
    init(position: SCNVector3) {
        super.init()
        let sphereGeometry = SCNSphere(radius: 0.004)
        self.geometry = sphereGeometry
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LabelNode: SCNNode {
    init(position: SCNVector3, index: Int, scale: Float = 0.002) {
        super.init()
        
        let labelGeometry = SCNText(string: "\(index)", extrusionDepth: 0)
        labelGeometry.alignmentMode = kCAAlignmentCenter
        
        self.geometry = labelGeometry
        self.scale = SCNVector3(scale, scale, scale)
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SCNNode {
    static func lineNode(from: SCNVector3, to: SCNVector3, radius: CGFloat = 0.002) -> SCNNode {
        let vector = to - from
        let height = vector.length()
        let cylinder = SCNCylinder(radius: radius, height: CGFloat(height))
        cylinder.radialSegmentCount = 20
        let node = SCNNode(geometry: cylinder)
        node.position = posBetween(first: from, second: to)
        node.eulerAngles = SCNVector3.lineEulerAngles(vector: vector)
        return node
    }
}

func posBetween(first: SCNVector3, second: SCNVector3) -> SCNVector3 {
    return SCNVector3Make((first.x + second.x) / 2, (first.y + second.y) / 2, (first.z + second.z) / 2)
}

extension SCNVector3 {
    
    static func lineEulerAngles(vector: SCNVector3) -> SCNVector3 {
        let height = vector.length()
        let lxz = sqrtf(vector.x * vector.x + vector.z * vector.z)
        let pitchB = vector.y < 0 ? Float.pi - asinf(lxz/height) : asinf(lxz/height)
        let pitch = vector.z == 0 ? pitchB : sign(vector.z) * pitchB
        
        var yaw: Float = 0
        if vector.x != 0 || vector.z != 0 {
            let inner = vector.x / (height * sinf(pitch))
            if inner > 1 || inner < -1 {
                yaw = Float.pi / 2
            } else {
                yaw = asinf(inner)
            }
        }
        return SCNVector3(CGFloat(pitch), CGFloat(yaw), 0)
    }
    
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
    
    func distance(to destination: SCNVector3) -> Float {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
        let column = matrix.columns.3
        return SCNVector3(column.x, column.y, column.z)
    }
}

extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}
