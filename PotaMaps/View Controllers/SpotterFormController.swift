//
//  SpotterFormController.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 1/5/19.
//  Copyright © 2019 Benjamin Montgomery. All rights reserved.
//
import UIKit
import Alamofire
import Eureka

class SpotterFormController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Enables smooth scrolling to off-screen rows
        animateScroll = true

        tableView?.backgroundColor = UIColor(named: "POTADarkGreen")

        form
            +++ Section()
                <<< TextRow() {
                    $0.title = "Spotter"
                    $0.tag = "spotter"
                    $0.placeholder = "Your callsign"

                    // text formatting - make all input uppercase
                    $0.useFormatterDuringInput = true
                    $0.formatter = UppercaseFormatter()

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")

                    // validation
                    var rules = RuleSet<String>()
                    rules.add(rule: RuleRequired(msg: "The spotter callsign is required."))
                    rules.add(rule: RuleMinLength(minLength: 3, msg: "Callsign is too short.", id: nil))
                    //rules.add(rule: RuleMaxLength(maxLength: 6, msg: "Callsign is too long.", id: nil))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                    }.onRowValidationChanged { [weak self] cell, row in
                        guard let self = self else { return }
                        self.displayErrorsForText(row, cell)
                    }

            +++ Section()
                <<< TextRow() {
                    $0.title = "Activator"
                    $0.tag = "activator"
                    $0.placeholder = "The callsign you're spotting"

                    // text formatting - make all input uppercase
                    $0.useFormatterDuringInput = true
                    $0.formatter = UppercaseFormatter()

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")

                    // validation
                    var rules = RuleSet<String>()
                    rules.add(rule: RuleRequired(msg: "The activator callsign is required."))
                    rules.add(rule: RuleMinLength(minLength: 3, msg: "Callsign is too short.", id: nil))
                    rules.add(rule: RuleMaxLength(maxLength: 6, msg: "Callsign is too long.", id: nil))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                    }.onRowValidationChanged { [weak self] cell, row in
                        guard let self = self else { return }
                        self.displayErrorsForText(row, cell)
                    }

            +++ Section()
                <<< TextRow() {
                    $0.title = "Frequency"
                    $0.tag = "freq"
                    $0.placeholder = "1.234.50"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")

                    // validation
                    var rules = RuleSet<String>()
                    rules.add(rule: RuleRequired(msg: "A frequency is required."))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                }.cellSetup { cell, _ in
                    cell.textField.keyboardType = .decimalPad
                }.onRowValidationChanged { [weak self] cell, row in
                    guard let self = self else { return }
                    self.displayErrorsForText(row, cell)
                }

            +++ Section()
                <<< TextRow() {
                    $0.title = "Park Reference"
                    $0.tag = "reference"
                    $0.value = "K-"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")

                    // validation
                    var rules = RuleSet<String>()
                    rules.add(rule: RuleRequired(msg: "A park reference is required."))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                }.cellSetup { cell, _ in
                    cell.textField.keyboardType = .numberPad
                }.onRowValidationChanged { [weak self] cell, row in
                    guard let self = self else { return }
                    self.displayErrorsForText(row, cell)
                }

            +++ Section("Comment")
                <<< TextAreaRow() {
                    $0.placeholder = "Enter a comment for this spot."
                    $0.tag = "comments"
                }

            +++ Section()
                <<< ButtonRow() {
                    $0.title = "Submit Spot"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")

                    $0.onCellSelection { [weak self] cell, row in
                        guard let self = self else { return }

                        if self.form.validate().count > 0 {
                            let alert = UIAlertController(title: "Please correct errors in the spot.",
                                                          message: "The spot has not been submitted.",
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK",
                                                          style: .default,
                                                          handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            self.submitSpot()
                        }
                    }
                }

    }

    /// Adds/Removes label rows to provide validation error information on TextRows.
    private func displayErrorsForText(_ row: TextRow, _ cell: TextCell) {
        let rowIndex = row.indexPath!.row
        while row.section!.count > rowIndex + 1 && row.section?[rowIndex + 1] is LabelRow {
            row.section?.remove(at: rowIndex + 1)
        }

        if !row.isValid {
            cell.titleLabel?.textColor = .red
            for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                let labelRow = LabelRow() {
                    $0.title = validationMsg
                    $0.cell.height = { 30 }
                    }.cellUpdate { cell, row in
                        cell.textLabel?.textColor = .red
                        cell.textLabel?.font = UIFont(name: "sans-serif", size: 10)
                    }
                row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
            }
        }
    }

    /// Submits spot information to the POTA website
    private func submitSpot() {
        let values = form.values()
        guard let spotter = values["spotter"] as? String else { return }
        guard let activator = values["activator"] as? String else { return }
        guard let freq = values["freq"] as? String else { return }
        guard let reference = values["reference"] as? String else { return }

        var parameters: Parameters = [
            "spotter": spotter,
            "activator": activator,
            "frequency": freq,
            "reference": reference,
            "submit": "Submit+Spot"
        ]
        if values["comments"] != nil {
            parameters["comments"] = values["comments"]!
        }

        let request = Alamofire.request("https://pota.us/spots_add_form_handler.php",
                                        method: .post,
                                        parameters: parameters)
        request.response { [weak self] response in
            guard let self = self else { return }

            if response.response?.statusCode == 200 {
                print("spot submitted")
            } else {
                let alert = UIAlertController(title: "Spot Failed",
                                              message: "Your spot was not validated.",
                                              preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

}

class UppercaseFormatter: Formatter {

    override func string(for obj: Any?) -> String? {
        guard let callsign = obj as? String else {
            return nil
        }

        return callsign.uppercased()
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string.uppercased() as AnyObject
        return true
    }

}
