//
//  ViewController.swift
//  conwAR
//
//  Created by Brandon Duderstadt on 12/31/20.
//

import UIKit
import ARKit
import AudioToolbox

var keepAliveVals: [Int] = [2, 3]
var bringAliveVals: [Int] = [5]
var meanDensity: Float = 0.1
var shouldRandomInit: Bool = false
var color: UIColor = UIColor.orange

var radius: CGFloat = 0.01
var initPlaced: Bool = false
var sigma: Float = 10.0
var rho: Float = 28
var beta: Float = 8.0/3.0
var points: [SCNNode] = []
var pseudoposes: [SIMD3<Float>] = []
var dt: Float = 0.01
var scaledown: Float = 100


//Because aparently swift doesnt have mod built in
infix operator %%

extension Int {
    static  func %% (_ left: Int, _ right: Int) -> Int {
        if left >= 0 { return left % right }
        if left >= -right { return (left+right) }
        return ((left % right)+right)%right
    }
}


func randomUIColor() -> UIColor {
    return UIColor(
        displayP3Red: CGFloat((211.0 + randomFloat()*40.0)/255.0),
        green: CGFloat((66 + randomFloat()*10.0)/255.0),
        blue:  CGFloat((181 + randomFloat()*120.0)/255.0),
        alpha: 1.0
    )
}


func randomFloat() -> Float{
    //https://stackoverflow.com/questions/25050309/swift-random-float-between-0-and-1
    return Float(arc4random()) / 0xFFFFFFFF
}

func randomCGFloat() -> CGFloat{
    return CGFloat(randomFloat())
}


class ViewController: UIViewController {


    @IBOutlet weak var arView: ARSCNView!
    let arConfig = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.session.run(arConfig)
    }
    
    func placeNode() {
        let px = randomFloat()/10
        let py = randomFloat()/10
        let pz = randomFloat()/10
        let color = randomUIColor()
        
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.z = -1.0 //was .3
        
        let sphereNode =  SCNNode(geometry: SCNSphere(radius: radius))
        sphereNode.simdTransform = matrix_multiply((arView.session.currentFrame?.camera.transform)!,
                                                   translationMatrix)
        sphereNode.geometry?.firstMaterial?.diffuse.contents = color
        points.append(sphereNode)
        pseudoposes.append(SIMD3<Float>([1.0+px, 1.0+py, 1.0+pz]))
        arView.scene.rootNode.addChildNode(sphereNode)
        
    }
    
    
    @IBAction func placeUniverse(_ sender: UILongPressGestureRecognizer) {

        
        if !initPlaced {
            
            var translationMatrix = matrix_identity_float4x4
            translationMatrix.columns.3.z = -1.0 //was .3
  
            for _ in 1...200 {
                placeNode()
            }
            
            initPlaced = true
            run()

        }
    }
    
    func run() {
        
        let gdq = DispatchQueue(label: "com.lorenzAR.queue", qos: .userInteractive)
        gdq.async{
           
            while true {
                print("UPDATE")
                //Compute updates
                var i = 0
                for point in points {
                    let pos = pseudoposes[i]
                    
                    print("pos: ", pos)
                    let dx = sigma * (pos.y - pos.x)
                    let dy = pos.x * (rho - pos.z) - pos.y
                    let dz = pos.x * pos.y - beta * pos.z
                    print("dx: ", dx)
                    print("dy: ", dy)
                    print("dz: ", dz)

                    point.simdLocalTranslate(by: SIMD3<Float>([dx*dt/scaledown, dy*dt/scaledown, dz*dt/scaledown]))
                    pseudoposes[i] = SIMD3<Float>([pos.x + dx*dt, pos.y + dy*dt, pos.z+dz*dt])
                    i = i + 1
                }
                usleep(10 * 1000)
            }
        }
    }
}

class settingsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var keepAliveText: UITextField!
    
    @IBOutlet weak var bringAliveText: UITextField!

    @IBAction func toggleColor(_ sender: UISegmentedControl) {
        let title = sender.titleForSegment(at: sender.selectedSegmentIndex)!
        
        if title == "Green" {
            color = UIColor.green
        }
        
        if title == "Blue" {
            color = UIColor.blue
        }
        
        if title == "Red" {
            color = UIColor.red
        }
        
        if title == "Orange" {
            color = UIColor.orange
        }

    }
    
    override func viewDidLoad() {
           super.viewDidLoad()
           self.keepAliveText.delegate = self
        
            self.bringAliveText.delegate = self
       }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let accessIdentifier = textField.accessibilityIdentifier!
        let text = textField.text
        let tempArray = text!.split(separator: ",")
        let intArray = tempArray.map { Int($0)! }
        
        if accessIdentifier == "keepAliveIdentifier" {
            keepAliveVals = intArray
        }
        
        if accessIdentifier == "bringAliveIdentifier" {
            bringAliveVals = intArray
        }
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func randomInit(_ sender: UIButton) {
        shouldRandomInit = true
    }
}
