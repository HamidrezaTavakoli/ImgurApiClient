//
//  ImagesCollectionViewController.swift
//  ImgurApiClient
//
//  Created by Hamid on 2/21/18.
//  Copyright © 2018 PicBlast. All rights reserved.
//

import UIKit

class ImagesCollectionViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: Constants
    private struct Constants {
        static let ImageCollectionViewCellIdentifier = "imageCollectionCellIdentifier"
        static let FullscreenAnimationDuration: TimeInterval = 0.5
        static let TitleForbackButton = "Back"
    }

    // MARK: Model
    private var images: [UIImage?]? {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionView.reloadData()
            }
        }
    }
    
    // MARK: Properties
    private var fullScreenImageView: UIImageView?
    private var fullScreenBlurView: UIVisualEffectView?
    private var backButton: UIBarButtonItem?
    private var cellFrameBeforeFullscreen: CGRect? // frame of the cell that is now being presented in full screen
    
    // MARK: IBOutlets
    @IBOutlet weak var imageCollectionView: UICollectionView! {
        didSet {
            imageCollectionView.dataSource = self
            imageCollectionView.delegate = self
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // MARK: ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton =  UIBarButtonItem(title: Constants.TitleForbackButton, style: .plain, target: self, action: #selector(ImagesCollectionViewController.exitFullscreen))
        startSpinner()
        ImgurAPIClient.login { (success, token, error) in
            if token != nil {
                ImgurAPIClient.getImagesInBackground(completionBlock: { (images, error) in
                    if error == nil {
                        self.images = images
                    }
                    self.stopSpinner()
                })
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fullScreenImageView = UIImageView(frame: view.bounds)
        fullScreenBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        fullScreenBlurView?.frame = view.bounds
        fullScreenImageView?.contentMode = .scaleAspectFit
    }
}

// MARK: Collection View Datasource and Delegate
extension ImagesCollectionViewController {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.ImageCollectionViewCellIdentifier, for: indexPath) as? ImageCollectionViewCell {
            cell.image = images?[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let image = images?[indexPath.row] {
            let cell = collectionView.cellForItem(at: indexPath)
            let cellFrame = view.convert((cell?.bounds)!, from: cell)
            presentInFullScreen(image: image,fromFrame: cellFrame)
        }
    }
}

// MARK: - Helper Funcions
extension ImagesCollectionViewController {
    private func startSpinner() {
        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
    }
    private func stopSpinner() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
        }
    }
    private func presentInFullScreen(image: UIImage, fromFrame frame: CGRect?) {
        if frame != nil, fullScreenBlurView != nil, fullScreenImageView != nil{
            fullScreenBlurView!.frame = frame!
            fullScreenImageView!.frame = frame!
            fullScreenImageView!.image = image
            view.addSubview(fullScreenBlurView!)
            view.addSubview(fullScreenImageView!)
            cellFrameBeforeFullscreen = frame!
            UIView.animate(withDuration: Constants.FullscreenAnimationDuration, animations: {
                self.fullScreenBlurView?.frame = self.view.bounds
                self.fullScreenImageView?.frame = self.view.bounds
            }, completion: { (_) in
                self.navigationItem.leftBarButtonItem = self.backButton
            })
        }
    }
    
    @objc private func exitFullscreen() {
        UIView.animate(withDuration: Constants.FullscreenAnimationDuration, animations: {
            self.fullScreenBlurView?.frame = self.cellFrameBeforeFullscreen! // it is never nil here
            self.fullScreenImageView?.frame = self.cellFrameBeforeFullscreen!
        }) { (_) in
            self.fullScreenImageView?.removeFromSuperview()
            self.fullScreenBlurView?.removeFromSuperview()
            self.navigationItem.leftBarButtonItem = nil
        }
    }
}
