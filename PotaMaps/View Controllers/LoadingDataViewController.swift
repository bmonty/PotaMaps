//
//  LoadingDataViewController.swift
//  PotaMaps
//
//  Created by Benjamin Montgomery on 3/17/19.
//  Copyright © 2019 Benjamin Montgomery. All rights reserved.
//

import Foundation
import UIKit

class LoadingDataViewController: UIViewController {


    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!

    private let parkData = ParkData()

    let potaLogoImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "POTALogo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false  // enable autolayout
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private var potaLogoXAnchor: NSLayoutConstraint?
    private var potaLogoYAnchor: NSLayoutConstraint?
    private var potaLogoHeightAnchor: NSLayoutConstraint?
    private var potaLogoWidthAnchor: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        progressLabel.text = "Preparing to download park data..."
        parkData.addParkDataProgressObserver(self, closure: self.updateProgress)

        // execute the park data download process, transition to the park view
        // if successful or tell the user about problems if unsuccessful
        parkData.downloadParkData(
            forProgram: "k",
            withProgress: self.updateProgress,
            completion: { [weak self] result in
                guard let self = self else { return }

                switch(result) {
                case .success:
                    // update user defaults
                    let userDefaults = UserDefaults.standard
                    userDefaults.set(true, forKey: "dataLoaded")

                    // load the UI
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let viewController = storyboard.instantiateInitialViewController()
                    UIView.transition(with: appDelegate.window!,
                                      duration: 0.5, options: .transitionCrossDissolve,
                                      animations: { appDelegate.window?.rootViewController = viewController },
                                      completion: nil)
                    return
                case .failure(let error):
                    self.handleDownloadError(error)
                }
            })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureProgressView()
        configureProgressLabel()
        configurePotaLogo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animatePotaLogo(completion: {[weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 2.0) {
                self.progressView.alpha = 1.0
                self.progressLabel.alpha = 1.0
            }
        })
    }

    /// Set initial contsraints on the POTA Logo.
    private func configurePotaLogo() {
        view.addSubview(potaLogoImageView)

        potaLogoXAnchor = potaLogoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        potaLogoXAnchor?.isActive = true

        potaLogoYAnchor = potaLogoImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        potaLogoYAnchor?.isActive = true

        potaLogoHeightAnchor = potaLogoImageView.heightAnchor.constraint(equalToConstant: 314)
        potaLogoHeightAnchor?.isActive = true

        potaLogoWidthAnchor = potaLogoImageView.widthAnchor.constraint(equalToConstant: 314)
        potaLogoWidthAnchor?.isActive = true
    }

    /// Set initial constraints on the progress bar.
    private func configureProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false  // enable autolayout

        // set the progress bar to be 100 below the middle of the screen
        let offset = view.frame.midY + 100

        // horizontally center the progress bar
        progressView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        // set the top anchor to the offset
        progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: offset).isActive = true
        // set left and right anchors to 20 from safe area sides
        progressView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        progressView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        // set the height to 20
        progressView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    /// Set initial constraints on the progress label.
    private func configureProgressLabel() {
        progressLabel.translatesAutoresizingMaskIntoConstraints = false // enable autolayout

        // set label to be 10 below the progress view
        progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10).isActive = true
        // set left and right anchor to 20 from safe area sides
        progressLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        progressLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        // set the height at 35
        progressLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
    }

    /// Animate the movement of the POTA logo.
    private func animatePotaLogo(completion: @escaping (Bool) -> Void) {
        // turn off the centerYAnchor
        potaLogoYAnchor?.isActive = false
        // set the top anchor to be 20 from the top of the safe area
        potaLogoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        // set size to be 250x250 (smaller than start)
        potaLogoHeightAnchor?.constant = 250
        potaLogoWidthAnchor?.constant = 250
        // trigger animation
        UIView.animate(withDuration: 1.8,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.view.layoutIfNeeded()
                       },
                       completion: completion)
    }

    /// Update the progress tracker.
    ///
    /// - parameter progress: Updated `ParkDataProgressMessage`
    private func updateProgress(_ progress: ParkData.ParkDataProgressMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.progressLabel.text = progress.message
            if progress.percent != nil {
                self.progressView.progress = Float(progress.percent!)
            } else {
                self.progressView.progress = 0
            }
        }
    }

    /// Handle error from the data loading process.
    private func handleDownloadError(_ error: ParkDataError) {
        progressView.progress = 0
        progressLabel.text = error.localizedDescription
    }
}
