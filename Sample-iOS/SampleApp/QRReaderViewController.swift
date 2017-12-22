//
//  QRReaderViewController.swift
//  OpenURL
//
//  Created by Cuong Ta on 12/1/15.
//  Copyright © 2015 Cuong Ta. All rights reserved.
//

import UIKit
import ZXingObjC

class QRReaderViewController: UIViewController, ZXCaptureDelegate {
    
    var capture: ZXCapture!
    var captureSquare: UIView!
    weak var delegate: QRReaderViewControllerDelegate?
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.white
        self.navigationItem.setRightBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target:self, action: #selector(close)), animated: true)
        self.navigationItem.title = "Scan Code"
        
        self.capture = ZXCapture()
        self.capture.delegate = self;
        self.capture.focusMode = AVCaptureFocusMode.continuousAutoFocus
        self.capture.scanRect = self.view.bounds;
        self.capture.camera = self.capture.back()
        self.capture.rotation = 90.0
        self.capture.layer.frame = self.view.bounds
        self.view.layer.addSublayer(self.capture.layer)
        
        self.captureSquare = UIView(frame: CGRect.zero)
        self.captureSquare.layer.borderWidth = 1;
        self.captureSquare.layer.borderColor = Default.defaultColor().cgColor
        self.view.addSubview(self.captureSquare)
        self.captureSquare.translatesAutoresizingMaskIntoConstraints = false;
        self.view.addConstraint(NSLayoutConstraint(item: self.captureSquare, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.captureSquare, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.captureSquare, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 320))
        self.view.addConstraint(NSLayoutConstraint(item: self.captureSquare, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 320))
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let captureSizeTransform = CGAffineTransform(scaleX: 320/self.view.frame.size.width, y: 320/self.view.frame.size.height)
        self.capture.scanRect = self.captureSquare.frame.applying(captureSizeTransform);
        super.viewWillAppear(animated)
    }
    
    func close(){
        self.capture.hard_stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    func barcodeFormatToString(_ format: ZXBarcodeFormat) -> String {
        switch (format) {
        case kBarcodeFormatAztec:
            return "Aztec";
            
        case kBarcodeFormatCodabar:
            return "CODABAR";
            
        case kBarcodeFormatCode39:
            return "Code 39";
            
        case kBarcodeFormatCode93:
            return "Code 93";
            
        case kBarcodeFormatCode128:
            return "Code 128";
            
        case kBarcodeFormatDataMatrix:
            return "Data Matrix";
            
        case kBarcodeFormatEan8:
            return "EAN-8";
            
        case kBarcodeFormatEan13:
            return "EAN-13";
            
        case kBarcodeFormatITF:
            return "ITF";
            
        case kBarcodeFormatPDF417:
            return "PDF417";
            
        case kBarcodeFormatQRCode:
            return "QR Code";
            
        case kBarcodeFormatRSS14:
            return "RSS 14";
            
        case kBarcodeFormatRSSExpanded:
            return "RSS Expanded";
            
        case kBarcodeFormatUPCA:
            return "UPCA";
            
        case kBarcodeFormatUPCE:
            return "UPCE";
            
        case kBarcodeFormatUPCEANExtension:
            return "UPC/EAN extension";
            
        default:
            return "Unknown";
        }
    }
    
    var previousImage:UIImageView?
    
    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        if result == nil {
            return
        }
        
        self.capture.stop()
        
        let urlStr = result.text
        do {
            let strongSelf = self.delegate
            
            // IMPORTANT Story:
            //
            // activate/* is used for any QR code scanner app. This is intended to redirect
            // the user with the token to a redirect page where they can embed js logic to open
            // their own app and deal with the QR code.
            //
            // verify/* is used for a Mist app where it'll do the 2nd part of the activate,
            // which is extracting the token, and enrolling the device with PAPI.
            
            let regex = try NSRegularExpression(pattern: "(activate|verify)\\/(.+)$", options: [])
            let matches = regex.matches(in: urlStr!, options: [], range: NSMakeRange(0, (urlStr?.characters.count)!))
            
            if matches.count == 0 {
                strongSelf?.receivedQRContent(nil, image: nil)
            } else {
                for match in matches {
                    
                    // regardless whichever way is passed, the app just cares about the token.
                    // extracts the second capture group because there's where the token is.
                    let secret = (urlStr as! NSString).substring(with: match.rangeAt(2))
                    
                    let lastScannedImage = UIImage(cgImage: capture.lastScannedImage)
                    
                    strongSelf?.receivedQRContent(secret, image: lastScannedImage)
                }
            }
        } catch {
            print("Cannot create regex ^https:\\/\\/admin\\.mistsys\\.com\\/api\\/v1\\/orgs\\/mobile\\/activate\\/(.+)")
        }
    }
    
    func captureCameraIsReady(_ capture: ZXCapture!){
        self.capture.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        self.capture.layer.removeFromSuperlayer()
    }
}

@objc
protocol QRReaderViewControllerDelegate {
    func receivedQRContent(_ content: String?, image: UIImage?)
}
