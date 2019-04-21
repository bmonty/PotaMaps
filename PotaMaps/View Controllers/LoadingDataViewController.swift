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

    // MARK: - IBOutlets
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var failedDownloadLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    // MARK: - ⛔️ Private Variables
    /// Reference to `ParkData` for accessing park information.
    private let parkData = ParkData()
    /// Tracks if the view is observing a `ParkData` object.
    private var parkDataObservationToken: ObservationToken? = nil
    /// POTA logo to show in the view.
    let potaLogoImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "POTALogo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false  // enable autolayout
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    /// POTA logo's X anchor.
    private var potaLogoXAnchor: NSLayoutConstraint?
    /// POTA logo's Y anchor.
    private var potaLogoYAnchor: NSLayoutConstraint?
    /// POTA logo's height anchor.
    private var potaLogoHeightAnchor: NSLayoutConstraint?
    /// POTA logo's width anchor.
    private var potaLogoWidthAnchor: NSLayoutConstraint?

    // MARK: - UIView Overrides
    // Configure UI elements.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureProgressView()
        configureProgressLabel()
        configurePotaLogo()
    }

    // Animate the POTA logo and show the download progress UI.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Animate the POTA logo movement
        animatePotaLogo(completion: {[weak self] _ in
            guard let self = self else { return }

            UIView.animate(withDuration: 0.8) { [weak self] in
                guard let self = self else { return }

                // show the progress UI
                self.progressView.alpha = 1.0
                self.progressLabel.alpha = 1.0

                // start the download process
                self.progressLabel.text = "Preparing to download park data..."
                self.executeDatabaseUpdate(forProgram: "k")
            }
        })
    }

    // MARK: - Actions and Callbacks
    /// Execute the database download process.
    ///
    /// - parameter program: the park program (i.e. "k", "ve", etc.) to download
    private func executeDatabaseUpdate(forProgram program: String) {
        // setup to observe progress notifications from the download
        if parkDataObservationToken == nil {
            parkDataObservationToken = parkData.addParkDataProgressObserver(self, closure: self.updateProgress)
        }

        // execute the park data download process, transition to the park view
        // if successful or tell the user about problems if unsuccessful
        parkData.downloadParkData(
            forProgram: program,
            withProgress: self.updateProgress,
            completion: { [weak self] result in
                guard let self = self else { return }

                switch(result) {
                case .success:
                    // stop observing parkData
                    self.parkDataObservationToken?.cancel()

                    // update user defaults
                    let defaults = UserDefaults.standard
                    defaults.set(true, forKey: "dataLoaded")

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

        // hide the progress info...
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }

            self.progressView.alpha = 0
            self.progressLabel.alpha = 0
            }, completion: { [weak self] _ in
                // ...and show the retry info
                guard let self = self else { return }

                self.progressView.isHidden = true
                self.progressLabel.isHidden = true

                self.failedDownloadLabel.isHidden = false
                self.failedDownloadLabel.alpha = 1
                self.retryButton.isHidden = false
                self.retryButton.alpha = 1
        })

        self.retryButton.isUserInteractionEnabled = true
    }

    // MARK: - IBActions
    @IBAction func retryTouched(_ sender: Any) {
        // hide the error message
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }

            self.failedDownloadLabel.isHidden = true
            self.failedDownloadLabel.alpha = 0
            self.retryButton.isHidden = true
            self.retryButton.alpha = 1
            }, completion: { [weak self] _ in
                guard let self = self else { return }

                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    guard let self = self else { return }

                    self.progressView.alpha = 1
                    self.progressView.isHidden = false
                    self.progressLabel.alpha = 1
                    self.progressLabel.isHidden = false
                })

                // start the download process
                self.progressLabel.text = "Preparing to download park data..."
                self.executeDatabaseUpdate(forProgram: "k")
        })
    }

    // MARK: - 🎉 UI Setup and Animations
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
                       animations: { self.view.layoutIfNeeded() },
                       completion: completion)
    }

}
