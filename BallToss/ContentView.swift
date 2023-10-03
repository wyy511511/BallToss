//
//  ContentView.swift
//  BallToss
//
//  Created by Wu Yaoyao on 10/2/23.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @State private var shotsRemaining: Int = 5
    @State private var score: Int = 0
    
    var body: some View {
        VStack {
            ARViewContainer(shotsRemaining: $shotsRemaining) { hitNode in
                if shotsRemaining > 0 {
                    score += 1
//                    shotsRemaining -= 1
                }
            }

            
            HStack {
                Text("Shots: \(shotsRemaining)")
                Spacer()
                Text("Score: \(score)")
            }
            .padding()
        }
    }
}




struct ARViewContainer: UIViewRepresentable {
    @Binding var shotsRemaining: Int
    var onTargetHit: ((SCNNode) -> Void)

    
    
    typealias UIViewType = ARSCNView

    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapRecognizer)


        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        



        guard let modelURL = Bundle.main.url(forResource: "chair_swan", withExtension: "usdz") else {
                fatalError("Failed to find model file.")
            }
            
            guard let object = try? SCNReferenceNode(url: modelURL) else {
                fatalError("Failed to load model.")
            }
            object.load()
            object.scale = SCNVector3(0.2, 0.2, 0.2)  // Adjust as needed

            
            object.position = SCNVector3(0, 0, -0.5)
        
            arView.scene.rootNode.addChildNode(object)
            

        arView.scene.physicsWorld.contactDelegate = context.coordinator as! SCNPhysicsContactDelegate
        

        // Configure the model for collision detection
        object.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        object.physicsBody?.categoryBitMask = 2
        
        
        let collisionBox = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let collisionNode = SCNNode(geometry: collisionBox)
        collisionNode.opacity = 0.0  // Make it invisible
        collisionNode.position = object.position

        collisionNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        collisionNode.physicsBody?.categoryBitMask = 2
        arView.scene.rootNode.addChildNode(collisionNode)


           return arView
    }

    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate , SCNPhysicsContactDelegate {
        var parent: ARViewContainer
        var hasUpdatedScore = false

        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            

            
            if self.parent.shotsRemaining < 1 {
                return
            }
            


            let ball = SCNSphere(radius: 0.02)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red
            ball.materials = [material]

            let ballNode = SCNNode(geometry: ball)
            ballNode.position = arView.pointOfView!.position

            // Determine the orientation of the camera and apply a force to shoot the ball in that direction
            let orientation = SCNVector3(-1 * arView.pointOfView!.transform.m31,
                                         -1 * arView.pointOfView!.transform.m32,
                                         -1 * arView.pointOfView!.transform.m33)
            let force = SCNVector3(orientation.x * 2, orientation.y * 2, orientation.z * 2)
            ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            ballNode.physicsBody?.applyForce(force, asImpulse: true)

            arView.scene.rootNode.addChildNode(ballNode)
            
            ballNode.physicsBody?.categoryBitMask = 1
            ballNode.physicsBody?.contactTestBitMask = 2
            
            DispatchQueue.main.async {
                self.parent.shotsRemaining -= 1
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
                // Present an error to the user
                print("Session failed: \(error)")
            }

            func sessionWasInterrupted(_ session: ARSession) {
                // Inform the user that the session has been interrupted
                print("Session interrupted")
            }

            func sessionInterruptionEnded(_ session: ARSession) {
                // Reset tracking and/or remove existing anchors if consistent tracking is required
                print("Session interruption ended")
            }
        
        
        func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
            let nodeA = contact.nodeA
            let nodeB = contact.nodeB
            
            if nodeA.physicsBody?.categoryBitMask == 1 && nodeB.physicsBody?.categoryBitMask == 2 {

                if let modelNode = nodeB.childNode(withName: "chair_swan", recursively: true) {
                    shake(modelNode)

                    if !hasUpdatedScore {
                        self.parent.onTargetHit(modelNode)
                        hasUpdatedScore = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.hasUpdatedScore = false
                        }
                    }

                }
            } else if nodeA.physicsBody?.categoryBitMask == 2 && nodeB.physicsBody?.categoryBitMask == 1 {
                if let modelNode = nodeA.childNode(withName: "chair_swan", recursively: true) {
                    shake(modelNode)
                    if !hasUpdatedScore {
                        self.parent.onTargetHit(modelNode)
                        hasUpdatedScore = true


                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.hasUpdatedScore = false
                        }
                    }

                }
            }
            

        }


        func zoomOut(_ node: SCNNode) {
            let action = SCNAction.scale(by: 0.5, duration: 1)  // Scale down by 50% in 1 second
            node.runAction(action)
        }
        
        func shake(_ node: SCNNode) {
            let leftShake = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-0.05), duration: 0.1)
            let rightShake = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(0.05), duration: 0.1)
            let shakeAction = SCNAction.sequence([leftShake, rightShake])
            let shakeRepeat = SCNAction.repeat(shakeAction, count: 3)  // Shake three times
            node.runAction(shakeRepeat)
        }


    }
}



#Preview {
    ContentView()
}
