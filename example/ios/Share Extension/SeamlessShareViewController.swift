//
//  SeamlessShareViewController.swift
//  Sharing Extension
//
//  Example of seamless sharing without compose dialog using RSIBaseShareViewController
//

import UIKit
import file_share_intent

class SeamlessShareViewController: RSIBaseShareViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure for seamless sharing
        showUI = true // Show minimal loading indicator
        processingMessage = "Sharing..."
        autoRedirect = true // Automatically redirect after processing
    }
    
    // Optional: Override this method to add custom behavior after attachments are processed
    override func onAttachmentsProcessed() {
        // Custom logic here if autoRedirect is false
        super.onAttachmentsProcessed()
    }
    
    // Optional: Override this method to control auto-redirect behavior
    override func shouldAutoRedirect() -> Bool {
        return true // Enable seamless sharing
    }
}