//
//  MenuViewController.swift
//  PhotoBrowserDemo
//
//  Created by Eduardo Callado on 11/27/16.
//
//

import UIKit

class MenuViewController: UITableViewController, IDMPhotoBrowserDelegate {
    
    let maxZoomScale : CGFloat = 8; // zoom in scale on double tap can be define here now
}

// MARK: View Lifecycle

extension MenuViewController {
    override func viewDidLoad() {
        self.setupTableViewFooterView()
    }
}

// MARK: Layout

extension MenuViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: General

extension MenuViewController {
    func setupTableViewFooterView() {
        let tableViewFooter: UIView = UIView(frame: CGRect.init(x: 0, y: 0, width: 320, height: 426 * 0.9 + 40))
        
        let buttonWithImageOnScreen1 = UIButton(type: .custom)
        buttonWithImageOnScreen1.frame = CGRect.init(x: 15, y: 0, width: 640/3 * 0.9, height: 426/2 * 0.9)
        buttonWithImageOnScreen1.tag = 101
        buttonWithImageOnScreen1.adjustsImageWhenHighlighted = false
        buttonWithImageOnScreen1.setImage(UIImage.init(named: "photo1m.jpg"), for: .normal)
        buttonWithImageOnScreen1.imageView?.contentMode = .scaleAspectFill
        buttonWithImageOnScreen1.backgroundColor = UIColor.black
        buttonWithImageOnScreen1.addTarget(self, action: #selector(buttonWithImageOnScreenPressed(sender:)), for: .touchUpInside)
        tableViewFooter.addSubview(buttonWithImageOnScreen1)
        
        let buttonWithImageOnScreen2 = UIButton(type: .custom)
        buttonWithImageOnScreen2.frame = CGRect.init(x: 15, y: 426/2 * 0.9 + 20, width: 640/3 * 0.9, height: 426/2 * 0.9)
        buttonWithImageOnScreen2.tag = 102
        buttonWithImageOnScreen2.adjustsImageWhenHighlighted = false
        buttonWithImageOnScreen2.setImage(UIImage.init(named: "photo3m.jpg"), for: .normal)
        buttonWithImageOnScreen2.imageView?.contentMode = .scaleAspectFill
        buttonWithImageOnScreen2.backgroundColor = UIColor.black
        buttonWithImageOnScreen2.addTarget(self, action: #selector(buttonWithImageOnScreenPressed(sender:)), for: .touchUpInside)
        tableViewFooter.addSubview(buttonWithImageOnScreen2)
        
        self.tableView.tableFooterView = tableViewFooter;
    }
}

// MARK: Actions

extension MenuViewController {
    @objc func buttonWithImageOnScreenPressed(sender: AnyObject) {
        let buttonSender = sender as? UIButton
        
        // Create an array to store IDMPhoto objects
        var photos: [IDMPhoto] = []
        
        var photo: IDMPhoto
        
        if buttonSender?.tag == 101 {
            let path_photo1l = [Bundle.main.path(forResource: "photo1l", ofType: "jpg")]
            photo = IDMPhoto.photos(withFilePaths:path_photo1l).first as! IDMPhoto
            photo.caption = "Grotto of the Madonna"
            photos.append(photo)
        }
        
        let path_photo3l = [Bundle.main.path(forResource: "photo3l", ofType: "jpg")]
        photo = IDMPhoto.photos(withFilePaths:path_photo3l).first as! IDMPhoto
        photo.caption = "York Floods"
        photos.append(photo)
        
        let path_photo2l = [Bundle.main.path(forResource: "photo2l", ofType: "jpg")]
        photo = IDMPhoto.photos(withFilePaths:path_photo2l).first as! IDMPhoto
        photo.caption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
        photos.append(photo)
        
        let path_photo4l = [Bundle.main.path(forResource: "photo4l", ofType: "jpg")]
        photo = IDMPhoto.photos(withFilePaths:path_photo4l).first as! IDMPhoto
        photo.caption = "Campervan";
        photos.append(photo)
        
        if buttonSender?.tag == 102 {
            let path_photo1l = [Bundle.main.path(forResource: "photo1l", ofType: "jpg")]
            photo = IDMPhoto.photos(withFilePaths:path_photo1l).first as! IDMPhoto
            photo.caption = "Grotto of the Madonna";
            photos.append(photo)
        }
        
        // Create and setup browser
        let browser: IDMPhotoBrowser = IDMPhotoBrowser(photos: photos, animatedFrom: buttonSender) // using initWithPhotos:animatedFromView:
        browser.delegate = self
        browser.displayActionButton = false
        browser.displayArrowButton = true
        browser.displayCounterLabel = true
        browser.usePopAnimation = true
        browser.scaleImage = buttonSender?.currentImage
        browser.dismissOnTouch = true
        browser.maximumDoubleTapZoomScale = CGFloat(maxZoomScale);
        // Show
        self.present(browser, animated: true, completion: nil)
    }
}

// MARK: TableView Data Source

extension MenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Single photo"
        case 1:
            return "Multiple photos"
        case 2:
            return "Photos on screen"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create
        let cellIdentifier = "Cell";
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        // Configure
        if indexPath.section == 0 {
            cell?.textLabel?.text = "Local photo"
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                cell?.textLabel?.text = "Local photos"
            case 1:
                cell?.textLabel?.text = "Photos from Flickr"
            case 2:
                cell?.textLabel?.text = "Photos from Flickr - Custom"
            default:
                break
            }
        }
        
        return cell!
    }
}

// MARK: TableView Delegate

extension MenuViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Create an array to store IDMPhoto objects
        var photos: [IDMPhoto] = []
        
        var photo: IDMPhoto
        
        if indexPath.section == 0 { // Local photo
            let path_photo2l = [Bundle.main.path(forResource: "photo2l", ofType: "jpg")]
            photo = IDMPhoto.photos(withFilePaths:path_photo2l).first as! IDMPhoto
            photo.caption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
            photos.append(photo)
        }
        else if indexPath.section == 1 { // Multiple photos
            if indexPath.row == 0 { // Local Photos
                
                let path_photo1l = [Bundle.main.path(forResource: "photo1l", ofType: "jpg")]
                photo = IDMPhoto.photos(withFilePaths:path_photo1l).first as! IDMPhoto
                photo.caption = "Grotto of the Madonna"
                photos.append(photo)
                
                let path_photo2l = [Bundle.main.path(forResource: "photo2l", ofType: "jpg")]
                photo = IDMPhoto.photos(withFilePaths:path_photo2l).first as! IDMPhoto
                photo.caption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
                photos.append(photo)
                
                let path_photo3l = [Bundle.main.path(forResource: "photo3l", ofType: "jpg")]
                photo = IDMPhoto.photos(withFilePaths:path_photo3l).first as! IDMPhoto
                photo.caption = "York Floods"
                photos.append(photo)
                
                let path_photo4l = [Bundle.main.path(forResource: "photo4l", ofType: "jpg")]
                photo = IDMPhoto.photos(withFilePaths:path_photo4l).first as! IDMPhoto
                photo.caption = "Campervan";
                photos.append(photo)
            } else if indexPath.row == 1 || indexPath.row == 2 { // Photos from Flickr or Flickr - Custom
                let photosWithURLArray = [NSURL.init(string: "http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"),
                                          NSURL.init(string: "http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"),
                                          NSURL.init(string: "http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"),
                                          NSURL.init(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")]
                let photosWithURL: [IDMPhoto] = IDMPhoto.photos(withURLs: photosWithURLArray) as! [IDMPhoto]
                
                photos = photosWithURL
            }
        }
        
        // Create and setup browser
        let browser = IDMPhotoBrowser.init(photos: photos)
        browser?.delegate = self
        
        if indexPath.section == 1 { // Multiple photos
            if indexPath.row == 1 { // Photos from Flickr
                browser?.displayCounterLabel = true
                browser?.displayActionButton = false
            } else if indexPath.row == 2 { // Photos from Flickr - Custom
                browser?.actionButtonTitles      = ["Option 1", "Option 2", "Option 3", "Option 4"]
                browser?.displayCounterLabel     = true
                browser?.useWhiteBackgroundColor = true
                browser?.leftArrowImage          = UIImage.init(named: "IDMPhotoBrowser_customArrowLeft.png")
                browser?.rightArrowImage         = UIImage.init(named: "IDMPhotoBrowser_customArrowRight.png")
                browser?.leftArrowSelectedImage  = UIImage.init(named: "IDMPhotoBrowser_customArrowLeftSelected.png")
                browser?.rightArrowSelectedImage = UIImage.init(named: "IDMPhotoBrowser_customArrowRightSelected.png")
                browser?.doneButtonImage         = UIImage.init(named: "IDMPhotoBrowser_customDoneButton.png")
                browser?.view.tintColor          = UIColor.orange
                browser?.progressTintColor       = UIColor.orange
                browser?.trackTintColor          = UIColor.init(white: 0.8, alpha: 1)
            }
        }
        browser!.maximumDoubleTapZoomScale = CGFloat(maxZoomScale);
        // Show
        present(browser!, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: IDMPhotoBrowser Delegate

extension MenuViewController {
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didShowPhotoAt index: UInt) {
        let photo: IDMPhoto = photoBrowser.photo(at: index) as! IDMPhoto
        print("Did show photoBrowser with photo index: \(index), photo caption: \(photo.caption)")
    }
    
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, willDismissAtPageIndex index: UInt) {
        let photo: IDMPhoto = photoBrowser.photo(at: index) as! IDMPhoto
        print("Will dismiss photoBrowser with photo index: \(index), photo caption: \(photo.caption)")
    }
    
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didDismissAtPageIndex index: UInt) {
        let photo: IDMPhoto = photoBrowser.photo(at: index) as! IDMPhoto
        print("Did dismiss photoBrowser with photo index: \(index), photo caption: \(photo.caption)")
    }
    
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didDismissActionSheetWithButtonIndex buttonIndex: UInt, photoIndex: UInt) {
        let photo: IDMPhoto = photoBrowser.photo(at: buttonIndex) as! IDMPhoto
        print("Did dismiss photoBrowser with photo index: \(buttonIndex), photo caption: \(photo.caption)")
        
        UIAlertView(title: "Option \(buttonIndex+1)", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
    }
}
