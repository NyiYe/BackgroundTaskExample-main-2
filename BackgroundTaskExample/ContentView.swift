//
//  ContentView.swift
//  BackgroundTaskExample
//
//  Created by Leonardo Maia Pugliese on 10/09/2022.
//

import SwiftUI
import BackgroundTasks

typealias Parameters = [String: String]

class ImageStore: NSObject, ObservableObject{
    
    @Published var randomImage: UIImage?
    
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
    
    func getPathImage(name : String)-> URL?{
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("\(name).jpeg")else{
            print("Error Getting path")
            return nil
        }
        return path
    }
    
    func uploadPhoto() async{
        
        
        var request = URLRequest(url: URL(string: "http://192.168.100.85:8080/socialapp/chat/uploadChatMediaFiles")!)
        
        request.httpMethod = "POST"
        let boundary: String = "Boundary-\(UUID().uuidString)"
        let params = ["userId" : "1011" , "locale" : "0"]
       
        let responseBody = createDataBody(withParameters: params, boundary: boundary)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = responseBody
        
//        if let compressedJSONData = try? NSData(data: responseBody).compressed(using: .zlib) as Data { //3
//          request.httpBody = compressedJSONData
//        }
        
        
//        URLSession.shared.uploadTask(with: request, from: responseBody) { data, response, error in
//
//
//            if let response = response {
//                print(response)
//            }
//
//            if let data = data {
//                let jsonStr = String(data: data, encoding: .utf8)
//                print(jsonStr ?? "unknon json")
//
//            }
//        }.resume()
        
        
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "test")
        let session = URLSession(configuration: configuration,delegate: self,delegateQueue: nil)
//        let path = getPathImage(name: "square.and.arrow.up")!
//        session.uploadTask(with: request, fromFile: path).resume()
        let response = await   withTaskCancellationHandler {
            try? await session.data(for: request)
        } onCancel: {
            print("on cancel")
        
//            let task = session.downloadTask(with: request)
//             task.resume()
        }

//        session.downloadTask(with: request)
//        session.dataTask(with: request) { data, response, error in
//
//
//            if let response = response {
//                print(response)
//            }
//
//            if let data = data {
//                let jsonStr = String(data: data, encoding: .utf8)
//                print(jsonStr ?? "unknon json")
//
//            }
//        }.resume()
//
  
    }
}

struct ContentView: View {
    
    @ObservedObject var imageStore: ImageStore
    @StateObject var viewModel = DownloadManager.shared
    
    var body: some View {
        VStack {
            
            Button {
                viewModel.startDownload()
            } label: {
                Text("start Download")
            }

            
            Button("Local Message Autorization") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("All set!")
                        
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }.buttonStyle(.borderedProminent)
                .padding()
            
            Button("Schedule Background Task") {
                let request = BGAppRefreshTaskRequest(identifier: "randomImage")
//                request.earliestBeginDate = Calendar.current.date(byAdding: .second, value: 5, to: Date())
                do {
                    try BGTaskScheduler.shared.submit(request)
                    print("Background Task Scheduled!")
                } catch(let error) {
                    print("Scheduling Error \(error.localizedDescription)")
                }
                
            }.buttonStyle(.bordered)
                .tint(.red)
                .padding()
            
            if let image = imageStore.randomImage {
                Image(uiImage: image)
            }
            
        }
    }
}

// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"randomImage"]

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(imageStore: ImageStore())
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension ImageStore : URLSessionDelegate , URLSessionTaskDelegate{
    
    func urlSession(
           _ session: URLSession,
           task: URLSessionTask,
           didSendBodyData bytesSent: Int64,
           totalBytesSent: Int64,
           totalBytesExpectedToSend: Int64
       ) {
           print(totalBytesSent)
           print(totalBytesExpectedToSend)
           let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
           print("progress\(progress)")
//           let handler = progressHandlersByTaskID[task.taskIdentifier]
//           handler?(progress)
       }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("URLAuthenticationChallenge")
    }
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
//        print("URLAuthenticationChallenge")
//    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError")
    }
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("forBackgroundURLSession")
    }
    
}
