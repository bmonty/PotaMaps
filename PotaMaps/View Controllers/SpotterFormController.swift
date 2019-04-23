//
//  SpotterFormController.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 1/5/19.
//  Copyright © 2019 Benjamin Montgomery. All rights reserved.
//
import UIKit
import SwiftyJSON
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

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                    $0.cellUpdate { [unowned self] cell, row in
                        cell.textLabel?.font = UIFont(name: "GillSans", size: 18)
                        cell.textField.font = self.makeTextEntryFont()
                    }

                    // text formatting - make all input uppercase
                    $0.useFormatterDuringInput = true
                    $0.formatter = UppercaseFormatter()

                    // swipe action
                    let clearAction = SwipeAction(
                        style: .normal,
                        title: "Clear",
                        handler: { action, row, completionHandler in
                            guard let textRow = row as? TextRow else { return }

                            textRow.value = ""
                            completionHandler?(true)
                    })
                    $0.trailingSwipe.actions = [clearAction]
                    $0.trailingSwipe.performsFirstActionWithFullSwipe = true

                    // validation
                    var rules = RuleSet<String>()
                    rules.add(rule: RuleRequired(msg: "The spotter callsign is required."))
                    rules.add(rule: RuleMinLength(minLength: 3, msg: "Callsign is too short.", id: nil))
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

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                    $0.cellUpdate { [unowned self] cell, row in
                        cell.textLabel?.font = UIFont(name: "GillSans", size: 18)
                        cell.textField.font = self.makeTextEntryFont()
                    }

                    // text formatting - make all input uppercase
                    $0.useFormatterDuringInput = true
                    $0.formatter = UppercaseFormatter()

                    // swipe action
                    let clearAction = SwipeAction(
                        style: .normal,
                        title: "Clear",
                        handler: { action, row, completionHandler in
                            guard let textRow = row as? TextRow else { return }

                            textRow.value = ""
                            completionHandler?(true)
                    })
                    $0.trailingSwipe.actions = [clearAction]
                    $0.trailingSwipe.performsFirstActionWithFullSwipe = true

                    // validation
                    var rules = RuleSet<String>()
                    rules.add(rule: RuleRequired(msg: "The activator callsign is required."))
                    rules.add(rule: RuleMinLength(minLength: 3, msg: "Callsign is too short.", id: nil))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                    }.onRowValidationChanged { [weak self] cell, row in
                        guard let self = self else { return }
                        self.displayErrorsForText(row, cell)
                    }

            +++ Section()
                <<< DecimalRow() {
                    $0.title = "Frequency"
                    $0.tag = "freq"
                    $0.placeholder = "1.234.50"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                    $0.cellUpdate { [unowned self] cell, row in
                        cell.textLabel?.font = UIFont(name: "GillSans", size: 18)
                        cell.textField.font = self.makeTextEntryFont()
                    }

                    // text formatting
                    let freqFormatter = NumberFormatter()
                    freqFormatter.usesGroupingSeparator = true
                    $0.formatter = freqFormatter

                    // swipe action
                    let clearAction = SwipeAction(
                        style: .normal,
                        title: "Clear",
                        handler: { action, row, completionHandler in
                            guard let textRow = row as? TextRow else { return }

                            textRow.value = ""
                            completionHandler?(true)
                    })
                    $0.trailingSwipe.actions = [clearAction]
                    $0.trailingSwipe.performsFirstActionWithFullSwipe = true

                    // validation
                    var rules = RuleSet<Double>()
                    rules.add(rule: RuleRequired(msg: "A frequency is required."))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                }.cellSetup { cell, _ in
                    cell.textField.keyboardType = .decimalPad
                }

            +++ Section()
                <<< SegmentedRow<String>() {
                    $0.title = "Park Prefix"
                    $0.options = ["K", "VE"]
                    $0.tag = "program"
                    $0.value = "K"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                }

                <<< IntRow() {
                    $0.title = "Park Reference"
                    $0.tag = "reference"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                    $0.cellUpdate { [unowned self] cell, row in
                        cell.textLabel?.font = UIFont(name: "GillSans", size: 18)
                        cell.textField.font = self.makeTextEntryFont()
                    }

                    // text formatting
                    let numberFormatter = NumberFormatter()
                    numberFormatter.groupingSeparator = ""
                    $0.useFormatterDuringInput = true
                    $0.formatter = numberFormatter

                    // swipe action
                    let clearAction = SwipeAction(
                        style: .normal,
                        title: "Clear",
                        handler: { action, row, completionHandler in
                            guard let intRow = row as? IntRow else { return }

                            intRow.value = 0
                            completionHandler?(true)
                    })
                    $0.trailingSwipe.actions = [clearAction]
                    $0.trailingSwipe.performsFirstActionWithFullSwipe = true

                    // validation
                    var rules = RuleSet<Int>()
                    rules.add(rule: RuleRequired(msg: "A park reference is required."))
                    $0.add(ruleSet: rules)
                    $0.validationOptions = .validatesOnChangeAfterBlurred
                }.cellSetup { cell, _ in
                    cell.textField.keyboardType = .numberPad
                }

            +++ Section("Comment")
                <<< TextAreaRow() {
                    $0.placeholder = "Enter a comment for this spot."
                    $0.tag = "comments"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                    $0.cellUpdate { cell, row in
                        cell.textLabel?.font = UIFont(name: "GillSans", size: 18)
                    }

                    // swipe action
                    let clearAction = SwipeAction(
                        style: .normal,
                        title: "Clear",
                        handler: { action, row, completionHandler in
                            guard let textRow = row as? TextAreaRow else { return }

                            textRow.value = ""
                            completionHandler?(true)
                    })
                    $0.trailingSwipe.actions = [clearAction]
                    $0.trailingSwipe.performsFirstActionWithFullSwipe = true
                }

            +++ Section()
                <<< ButtonRow() {
                    $0.title = "Submit Spot"

                    // cell formatting
                    $0.cell.backgroundColor = UIColor(named: "POTABackground")
                    $0.cellUpdate { cell, row in
                        cell.textLabel?.font = UIFont(name: "GillSans", size: 18)
                    }

                    // button press action
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

                let indexPath = row.indexPath!.row + index + 1
                row.section?.insert(labelRow, at: indexPath)
            }
        }
    }

    /// Creates a font with a "slash zero".
    private func makeTextEntryFont() -> UIFont {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let desc = font.fontDescriptor
        let d = [
            UIFontDescriptor.FeatureKey.featureIdentifier: kStylisticAlternativesType,
            UIFontDescriptor.FeatureKey.typeIdentifier: kStylisticAltSixOnSelector
        ]
        let desc2 = desc.addingAttributes([.featureSettings:[d]])
        return UIFont(descriptor: desc2, size: 18)
    }

    /// Submits spot information to the POTA website
    // Requires two POST requests:
    // 1. https://api.pota.us/slack/spot
    // 2. https://api.pota.us/spot
    // POST data looks like:
    // {"activator":"KG5YOV","spotter":"KG5YOV","frequency":"14.000","reference":"K-TEST","comments":"Test spot, please ignore."}
    private func submitSpot() {
        let values = form.values()
        guard let spotter = values["spotter"] as? String else { return }
        guard let activator = values["activator"] as? String else { return }
        guard let freq = values["freq"] as? Double else { return }
        guard let program = values["program"] as? String else { return }
        guard let reference = values["reference"] as? Int else { return }

        var parameters: Parameters = [
            "spotter": spotter,
            "activator": activator,
            "frequency": freq,
            "reference": "\(program)-\(reference)",
        ]
        if values["comments"] != nil {
            parameters["comments"] = values["comments"]!
        }

        // submit spot to main API
        Alamofire.request("https://api.pota.us/spot",
                                        method: .post,
                                        parameters: parameters,
                                        encoding: JSONEncoding.default)
            .responseJSON { [weak self] response in
                guard let self = self else { return }

                switch response.result {
                case .success:
                    break

                case .failure:
                    let alert = UIAlertController(title: "Spot Failed",
                                                  message: "Your spot was not validated.",
                                                  preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }

        // submit spot to slack
        Alamofire.request("https://api.pota.us/slack/spot",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
    
    }

}

class UppercaseFormatter: Formatter {

    override func string(for obj: Any?) -> String? {
        guard let callsign = obj as? String else {
            return nil
        }

        let formattedString = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return formattedString
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string.uppercased() as AnyObject
        return true
    }

}
