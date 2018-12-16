//
//  SpotterViewController.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 12/14/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import UIKit
import Alamofire

class SpotterViewController: UIViewController {
    
    @IBOutlet weak var spotterTextField: UITextField!
    @IBOutlet weak var activatorTextField: UITextField!
    @IBOutlet weak var freqTextField: UITextField!
    @IBOutlet weak var referenceTextField: UITextField!
    @IBOutlet weak var commentsTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentsTextView.keyboardAppearance = .dark
        commentsTextView.returnKeyType = .done
    }

    @IBAction func submitPressed(_ sender: Any) {
        guard let button: UIButton = sender as? UIButton else { return }
        button.isEnabled = false
        activityIndicator.startAnimating()

        guard let spotter = spotterTextField.text else { return }
        guard let activator = activatorTextField.text else { return }
        guard let freq = freqTextField.text else { return }
        guard let reference = referenceTextField.text else { return }
        guard let comments = commentsTextView.text else { return }

        let parameters: Parameters = [
            "spotter": spotter,
            "activator": activator,
            "frequency": freq,
            "reference": reference,
            "comments": comments,
            "submit": "Submit+Spot"
        ]

        let request = Alamofire.request("https://pota.us/spots_add_form_handler.php",
                          method: .post,
                          parameters: parameters)
        request.response { [weak self] response in
            guard let self = self else { return }

            if response.response?.statusCode == 200 {
                self.activityIndicator.stopAnimating()
                button.isEnabled = true
            } else {
                let alert = UIAlertController(title: "Spot Failed",
                                              message: "Your spot was not validated.",
                                              preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

}

extension SpotterViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1

        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return true
    }

}

extension SpotterViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }

        return true
    }

}
