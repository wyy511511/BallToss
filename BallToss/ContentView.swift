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

            // Add a basic sphere as target
            let sphere = SCNSphere(radius: 0.05) // 5 cm radius
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue
            sphere.materials = [material]
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, 0, -0.5) // Half meter in front of the camera
            
            arView.scene.rootNode.addChildNode(sphereNode)

            return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            let location = gesture.location(in: arView)
            let hitResults = arView.hitTest(location, options: nil)
            
            if let hitNode = hitResults.first?.node {
                parent.onTargetHit(hitNode)
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
        
        // Implement other ARSCNViewDelegate methods if needed
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
