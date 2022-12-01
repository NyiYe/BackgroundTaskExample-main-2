//
//  DownloadManager.swift
//  BackgroundTaskExample
//
//  Created by Nyi Ye Han on 29/11/2022.
//

import Foundation
import UIKit



class DownloadManager: NSObject, ObservableObject {
    static var shared = DownloadManager()

    private var urlSession: URLSession!
    @Published var tasks: [URLSessionTask] = []
    
    
    func createDataBody(withParameters params: Parameters?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        let uiImage = UIImage(systemName: "square.and.arrow.up")!
        let data = uiImage.jpegData(compressionQuality: 0.1)!
        
        if let para = params {
            
            for (key, value) in para {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }


        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"mediaFiles\"; filename=\"gg.jpeg\"\(lineBreak)")
        body.append("Content-Type: \("image/jpeg" + lineBreak + lineBreak)")
        body.append(data)
        body.append(lineBreak)

        body.append("--\(boundary)--\(lineBreak)")
        
        
        return body
    }

    override private init() {
        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
        config.isDiscretionary = true
//        config.networkServiceType = .video

        // Warning: Make sure that the URLSession is created only once (if an URLSession still
        // exists from a previous download, it doesn't create a new URLSession object but returns
        // the existing one with the old delegate object attached)
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())

        updateTasks()
    }

    func startDownload() {
        
        let boundary: String = "Boundary-\(UUID().uuidString)"
        let params = ["userId" : "1011" , "locale" : "0"]
       
        let responseBody = createDataBody(withParameters: params, boundary: boundary)
        
        let data = "Secret Message".data(using: .utf8)!
                
        let tempDir = FileManager.default.temporaryDirectory
        let localURL = tempDir.appendingPathComponent("youknow")
        try? responseBody.write(to: localURL)
        
        
        print("start download")
//    http://192.168.100.85/user-service/upload/test
        var request = URLRequest(url: URL(string: "http://192.168.100.85/user-service/upload/test")!)
//        var request = URLRequest(url: URL(string: "http://192.168.100.85:8080/socialapp/chat/uploadChatMediaFiles")!)
//        request.httpBody = responseBody
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        request.setValue("userId", forHTTPHeaderField: "1011")
//        request.setValue("locale", forHTTPHeaderField: "0")
        request.httpMethod = "POST"
        
        
        
//        let task = urlSession.downloadTask(with: request)
//        saveImage()
        let path = getPathImage(name: "square.and.arrow.up")!
        let task = urlSession.uploadTask(with: request, fromFile: localURL)
        
        print("\(request.httpMethod!) \(request.url!)")
        print(request.allHTTPHeaderFields!)
//        print(String(data: request.httpBody ?? Data(), encoding: .utf8)!)
        task.resume()
        if let currentRequest = task.currentRequest{
            
//            print(currentRequest.httpBody ?? Data() , )
//            print(String(data: currentRequest.httpBody ?? Data(), encoding: .utf8)!)
        }
        tasks.append(task)
    }
    
    func saveImage(){
        let imageToSave = UIImage(systemName: "square.and.arrow.up")!
        let jpegData = imageToSave.jpegData(compressionQuality: 1.0)!
        
        do {
            if let path = getPathImage(name: "square.and.arrow.up"){
                try jpegData.write(to: path)
            }
           
            print("saved successfully")
        } catch  {
            print(error.localizedDescription)
        }
    }
    
    func getPathImage(name : String)-> URL?{
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("\(name).jpeg")else{
            print("Error Getting path")
            return nil
        }
        return path
    }

    private func updateTasks() {
        urlSession.getAllTasks { tasks in
            DispatchQueue.main.async {
                self.tasks = tasks
            }
        }
    }
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        print("need new body stream")
    }
    
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
        print(downloadTask.progress.fractionCompleted)
//        os_log("Progress %f for %@", type: .debug, downloadTask.progress.fractionCompleted, downloadTask)
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download finished : \(location.absoluteString)")
//        os_log("Download finished: %@", type: .info, location.absoluteString)
        // The file at location is temporary and will be gone afterwards
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download errorr \(error.localizedDescription)")
//            os_log("Download error: %@", type: .error, String(describing: error))
        } else {
            
            print(task.response ?? "nilr")
            
            if let currentRequest = task.currentRequest{
                print(currentRequest.allHTTPHeaderFields!)
//                print(currentRequest.httpBody ?? Data() , )
//                print(String(data: currentRequest.httpBody ?? Data(), encoding: .utf8)!)
            }
//            os_log("Task finished: %@", type: .info, task)
        }
    }
}
