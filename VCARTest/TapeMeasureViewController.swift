//
//  TapeMeasureViewController.swift
//  VCARTest
//
//  Created by François Lambert on 30/07/2018.
//  Copyright © 2018 François Lambert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

protocol TapeMeasureDelegate: class {
    func didMeasure(_ measures: [Measure])
}

class TapeMeasureViewController: UIViewController, ARSCNViewDelegate {
    
    weak var delegate: TapeMeasureDelegate?

    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    @IBOutlet weak var measuringView: UIView!
    @IBOutlet weak var measuringLabel: UILabel!
    
    @IBOutlet weak var validateView: UIView!
    @IBOutlet weak var validateLabel: UILabel!
    
    var measures = [Measure]()
    var step = 0
    var spheres: [SphereNode] = []
    var labels: [LabelNode] = []
    var lines: [SCNNode] = []
    var trackingState: ARCamera.TrackingState?
    var distance: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        
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
    
    func loader(show: Bool, state: String? = nil) {
        loadingView.isHidden = !show
        measuringView.isHidden = show
        validateView.isHidden = show
        loadingLabel.text = state ?? ""
    }
    
    func displayMeasuring() {
        measuringView.isHidden = false
        validateView.isHidden = true
        measuringLabel.text = "Mesure de la \(measures[step].label)"
    }
    
    func displayValidating() {
        measuringView.isHidden = true
        validateView.isHidden = false
        
        guard let distance = distance else { return }
        validateLabel.text = measures[step].label + " : " + String(describing: Int(distance * 100.0)) + "cm"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapDismiss(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapClear(_ sender: UIButton?) {
        spheres.removeAll()
        labels.removeAll()
        lines.removeAll()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }
    
    @IBAction func didTapRetry(_ sender: Any) {
        didTapClear(nil)
        displayMeasuring()
    }
    
    @IBAction func didTapValidate(_ sender: Any) {
        var currentMeasure = self.measures[step]
        currentMeasure.value = distance
        self.measures[step] = currentMeasure
        
        delegate?.didMeasure(self.measures)
        
        // Dismiss
        if step == measures.count - 1 {
            didTapDismiss(nil)
            
        // Next Step
        } else {
            didTapClear(nil)
            step += 1
            distance = nil
            displayMeasuring()
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        if let result = hitTestResults.first {
            if spheres.count == 2 { return }
            
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            
            let sphere = SphereNode(position: position)
            let label = LabelNode(position: position, index: spheres.count + 1)
            
            sceneView.scene.rootNode.addChildNode(sphere)
            sceneView.scene.rootNode.addChildNode(label)
            
            let lastSphere = spheres.last
            
            spheres.append(sphere)
            labels.append(label)
            
            if let lastNode = lastSphere {
                distance = lastNode.position.distance(to: sphere.position)
                
                let line = SCNNode.lineNode(from: lastNode.position, to: sphere.position)
                
                sceneView.scene.rootNode.addChildNode(line)
                lines.append(line)
                
                displayValidating()
            }
        }
    }
    
    // MARK: ARSCNViewDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        trackingState = camera.trackingState
        
        if let t = trackingState {
            switch(t) {
            case .notAvailable:
                loader(show: true, state: "TRACKING UNAVAILABLE")
            case .normal:
                loader(show: false)
                displayMeasuring()
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    loader(show: true, state: "TRACKING LIMITED :\nToo much camera movement")
                case .insufficientFeatures:
                    loader(show: true, state: "TRACKING LIMITED :\nNot enough surface detail")
                case .initializing:
                    loader(show: true, state: "INITIALIZING")
                case .relocalizing:
                    loader(show: true, state: "RELOCALIZING")
                }
            }
        }
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
