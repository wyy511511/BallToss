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
            ARViewContainer { hitNode in
                if shotsRemaining > 0 {
                    // Handle node hit, e.g., change color
                    hitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    score += 1
                    shotsRemaining -= 1
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

    
    
    typealias UIViewType = ARSCNView
    
    var onTargetHit: ((SCNNode) -> Void)
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapRecognizer)

        // Start AR session with world tracking
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)

        // Add a basic cube as target
        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        cube.materials = [material]

        let cubeNode = SCNNode(geometry: cube)
        cubeNode.position = SCNVector3(0, 0, -0.5) // Half meter in front of the camera

        arView.scene.rootNode.addChildNode(cubeNode)

        arView.scene.physicsWorld.contactDelegate = context.coordinator as! any SCNPhysicsContactDelegate
           
           // Configure cube for collision detection
           cubeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
           cubeNode.physicsBody?.categoryBitMask = 2

           return arView
    }

    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate , SCNPhysicsContactDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }

            // Create a ball to shoot
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
            
            // Handle collision: You can enhance this to handle the collision between the ball and the cube.
            ballNode.physicsBody?.categoryBitMask = 1
            ballNode.physicsBody?.contactTestBitMask = 2
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
                    // Handle collision between ball (nodeA) and cube (nodeB)
                    DispatchQueue.main.async {
                        self.parent.onTargetHit(nodeB)
                    }
                } else if nodeA.physicsBody?.categoryBitMask == 2 && nodeB.physicsBody?.categoryBitMask == 1 {
                    // Handle collision between cube (nodeA) and ball (nodeB)
                    DispatchQueue.main.async {
                        self.parent.onTargetHit(nodeA)
                    }
                }
            }

    }
}


//struct ARViewContainer: UIViewRepresentable {
//    
//    func makeUIView(context: Context) -> ARView {
//        
//        let arView = ARView(frame: .zero)
//
//        // Create a cube model
//        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
//        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
//        let model = ModelEntity(mesh: mesh, materials: [material])
//
//        // Create horizontal plane anchor for the content
//        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
//        anchor.children.append(model)
//
//        // Add the horizontal plane anchor to the scene
//        arView.scene.anchors.append(anchor)
//
//        return arView
//        
//    }
//    
//    func updateUIView(_ uiView: ARView, context: Context) {}
//    
//}

#Preview {
    ContentView()
}
