//
//  ViewController.swift
//  VCARTest
//
//  Created by François Lambert on 12/06/2018.
//  Copyright © 2018 François Lambert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class FirstViewController: UIViewController, ARSCNViewDelegate {

    var nodes: [SphereNode] = []
    
    @IBOutlet var sceneView: ARSCNView!
    
    lazy var infoLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        label.textAlignment = .center
        label.backgroundColor = .white
        return label
    }()
    
    lazy var plusButton: UIButton = {
        let button = UIButton(type: .contactAdd)
        button.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        return button
    }()
    
    lazy var clearButton: UIButton = {
        let button = UIButton()
        button.setTitle("Clear", for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        view.addSubview(infoLabel)
        view.addSubview(plusButton)
        view.addSubview(clearButton)
        
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        infoLabel.frame = CGRect(x: 0, y: 40, width: view.bounds.width, height: 20)
        infoLabel.backgroundColor = UIColor.clear
        infoLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        clearButton.frame = CGRect(x: 20, y: view.bounds.height - 100, width: 100, height: 30)
        plusButton.frame = CGRect(x: view.bounds.width - 50, y: view.bounds.height - 100, width: 30, height: 30)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: Gesture handlers
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        if let result = hitTestResults.first {
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            let sphere = SphereNode(position: position)
            sceneView.scene.rootNode.addChildNode(sphere)
            let lastNode = nodes.last
            nodes.append(sphere)
            if lastNode != nil {
                let distance = lastNode!.position.distance(to: sphere.position)
                infoLabel.text = String(format: "Distance: %.2f meters", distance)
            }
        }
    }

    @objc func didTapAddButton() {
        print("add tap")
    }
    
    @objc func didTapClearButton() {
        print("clear tap")
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    // MARK: ARSCNViewDelegate
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //5
        var status = "Loading..."
        switch camera.trackingState {
        case ARCamera.TrackingState.notAvailable:
            status = "Not available"
        case ARCamera.TrackingState.limited(_):
            status = "Analyzing..."
        case ARCamera.TrackingState.normal:
            status = "Ready"
        }
        infoLabel.text = status
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

