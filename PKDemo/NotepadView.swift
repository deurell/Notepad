import Foundation
import RealityKit
import ARKit
import SwiftUI
import PencilKit
import Combine

class NotepadView: ARView, ARSessionDelegate, PKCanvasViewDelegate {
    
    static let noteBookComponentQuery = EntityQuery(where: .has(NotebookComponent.self))
    
    var arView: ARView { return self }
    var anchor: AnchorEntity!
    var camera: AnchorEntity?
    var canvasView: PKCanvasView!
    var notepadEntity: Entity?
    var subscription: Cancellable?
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("not implemented")
    }
    
    func setup(canvasView: PKCanvasView) {
        self.canvasView = canvasView
        self.canvasView.delegate = self
        
        arView.cameraMode = .ar
        setupScene()
        setupARSession()
        
        subscription = scene.subscribe(to: SceneEvents.Update.self, onSceneUpdated)
    }
    
    func onSceneUpdated(_ event: Event) {
        if self.notepadEntity == nil {
            self.notepadEntity = findNotepadEntity(scene: scene)
        }
    }
    
    func findNotepadEntity(scene: RealityKit.Scene) -> Entity? {
        let notebookEntity = scene.performQuery(Self.noteBookComponentQuery).map {$0}.first
        return notebookEntity
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let notepadEntity = self.notepadEntity as? HasModel else { return }
        
        let size = canvasView.frame.size
        let image = canvasView.drawing
            .transformed(using: .init(scaleX: -1.0, y: -1.0).translatedBy(x: -CGFloat(size.width), y: -CGFloat(size.height)))
            .image(from: .init(x: 0, y: 0, width: size.width, height: size.height), scale: 1.0)
            .withBackground(color: .white)
                
        if let cgImage = image.cgImage {
            if let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) {
                var notepadMaterial = PhysicallyBasedMaterial()
                notepadMaterial.baseColor.texture = PhysicallyBasedMaterial.Texture(texture)
                notepadEntity.model?.materials = [notepadMaterial]
            }
        }
    }
    
    private func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection.insert(.horizontal)
        session.run(configuration)
        session.delegate = self
    }
    
    private func setupScene() {
        anchor = AnchorEntity(.plane(.horizontal, classification: .any,
                                     minimumBounds: [0.5, 0.5]))
        
        scene.anchors.append(anchor)
        
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = 4000
        directionalLight.light.isRealWorldProxy = true
        directionalLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 10,
            depthBias: 5.0)
        directionalLight.position = [0,8,5]
        directionalLight.look(at: [0,0,0], from: directionalLight.position, relativeTo: directionalLight.parent)
        anchor.addChild(directionalLight)
        
        let planeSize:simd_float3 = [0.5, 0.5, 0.05]
        let planeMesh: MeshResource = .generateBox(size: planeSize)
        let planeMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.2), roughness: 0.5, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        planeEntity.position = [0, 0, 0]
        planeEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: [1,0,0])
        planeEntity.collision = CollisionComponent(shapes: [.generateBox(size: planeSize)])
        planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static)
        anchor.addChild(planeEntity)
        
        let notebookSize:simd_float3 = [0.1, 0.2, 0.005]
        let notebookMesh: MeshResource = .generateBox(size: notebookSize)
        let notebookMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let notebookEntity = ModelEntity(mesh: notebookMesh, materials: [notebookMaterial])
        notebookEntity.position = [0, 0.2, 0]
        notebookEntity.transform.rotation = simd_quatf(angle: Float.pi/4, axis: [1,0,0])
        notebookEntity.collision = CollisionComponent(shapes: [.generateBox(size: notebookSize)])
        notebookEntity.physicsMotion = PhysicsMotionComponent()
        notebookEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic)
        notebookEntity.components.set(NotebookComponent())
        anchor.addChild(notebookEntity)
    }
}

struct NotebookComponent: Component {}

extension UIImage {
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
      UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
      guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
      defer { UIGraphicsEndImageContext() }
      let rect = CGRect(origin: .zero, size: size)
      ctx.setFillColor(color.cgColor)
      ctx.fill(rect)
      ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
      ctx.draw(image, in: rect)
      return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
  }
