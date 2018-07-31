//
//  FormViewController.swift
//  VCARTest
//
//  Created by François Lambert on 30/07/2018.
//  Copyright © 2018 François Lambert. All rights reserved.
//

import UIKit

class FormViewController: UIViewController {

    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var depthTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTapeMeasure", let destination = segue.destination as? TapeMeasureViewController {
            destination.delegate = self
            destination.measures = [Measure(unit: .cm, label: "Hauteur"),
                                    Measure(unit: .cm, label: "Largeur"),
                                    Measure(unit: .cm, label: "Profondeur")]
        }
    }

}

extension FormViewController: TapeMeasureDelegate {
    func didMeasure(_ measures: [Measure]) {
        measures.map({ print("\($0.label) : \($0.value) \($0.unit.rawValue)\n")})
        if let height = measures[0].value {
            heightTextField.text = String(describing: Int(height * 100.0)) + "cm"
        }
        
        if let width = measures[1].value {
            widthTextField.text = String(describing: Int(width * 100.0)) + "cm"
        }
        
        if let depth = measures[2].value {
            depthTextField.text = String(describing: Int(depth * 100.0)) + "cm"
        }
    }
}

struct Measure {
    let unit: Unit
    let label: String
    var value: Float?
    
    init(unit: Unit, label: String) {
        self.unit = unit
        self.label = label
        self.value = nil
    }
}

enum Unit: String {
    case cm
    case inch
}
