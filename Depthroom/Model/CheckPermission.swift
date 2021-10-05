//
//  CheckPermission.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/06/23.
//

import Foundation
import Photos

class CheckPermission {
    
    func showCheckPermission(){
        PHPhotoLibrary.requestAuthorization { (status) in
            
            switch(status){
            
            case .authorized:
                print("許可されています")
            case .denied:
                print("拒否")
            case .notDetermined:
                print("notDetermined")
            case .restricted:
                print("restricted")
            case .limited:
                print("limited")
            @unknown default: break
            }
        }
    }
    
}
