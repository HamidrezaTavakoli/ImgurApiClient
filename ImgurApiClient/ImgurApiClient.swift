//
//  ImgurSettings.swift
//  
//
//  Created by Hamid on 4/15/17.
//
//

import Foundation

import Alamofire
import AlamofireOauth2
class ImgurAPIClient {
    /*
     The class uses Alamofire and AlamofireOauth2 libraries to make REST calls to Imgur API
     In order to use the app, the user must have an account at imgur.com
     In this example, only the endpoint for getting the user's images is implemented
     */
    private struct Constants {
        static let StandardDefaultsKeyForAccessToken = "access_token"
        static let UnbaleToGetAccessTokenErrorMessage = "Unable to get an access token"
        static let UnbaleToGetAccessTokenErrorCustomCode = 1001
        
        static let UnableToParseImgurResponseMessage = "We were unable to parse the results"
        static let UnableToParseImgurResponseCustomCode = 1002
        
        static let ImageNotFoundErrorMessage = "Image not foound."
        static let ImageNotFoundErrorCusotmCode = 1003
        
        static let ImgurAPIBaseUrlString = "https://api.imgur.com/3/"
        static let ImgurAPIAuthorizeUrlString = "https://api.imgur.com/oauth2/authorize"
        static let ImgurAPIAccessTokenUrlString = "https://api.imgur.com/oauth2/token"
        static let ImgurAPIDefaultRedirectUrl = "https://imgur.com"
        
    }
    
    private static let imgurSettings = Oauth2Settings(baseURL:Constants.ImgurAPIBaseUrlString,
                                                      authorizeURL: Constants.ImgurAPIAuthorizeUrlString,
                                                      tokenURL:Constants.ImgurAPIAccessTokenUrlString,
                                                      redirectURL: Constants.ImgurAPIDefaultRedirectUrl,
                                                      clientID: AppDelegate.clientId,
                                                      clientSecret: AppDelegate.clientSecret)
    
    
    // it provides a valid request url for Imgur api
    private enum ImgurRequestConvertible: URLRequestConvertible {
        //    GET  https://api.imgur.com/3/account/me
        case me()
        //    GET https://api.imgur.com/3/account/me/images
        case images()
        //    POST https://api.imgur.com/3/image
        //    image    required    A binary file, base64 data, or a URL for an image. (up to 10MB)
        case postImage(parameters: Parameters)
        
        //    DELETE https://api.imgur.com/3/image/{id}
        case deleteImage(imageId: String)
        
        static let baseURLString = imgurSettings.baseURL
        static var oauthToken: String?
        
        private var method: HTTPMethod {
            switch self {
            case .me: return .get
            case .images: return .get
            case .postImage: return .post
            case .deleteImage: return .delete
            }
        }
        private var path: String {
            switch self {
            case .me: return "account/me"
            case .images: return "account/me/images"
            case .postImage: return "image"
            case .deleteImage(let id): return "image/\(id)"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            let url = try ImgurRequestConvertible.baseURLString.asURL()
            var urlRequest = URLRequest(url: url.appendingPathComponent(path))
            urlRequest.httpMethod = method.rawValue
            if let token = ImgurRequestConvertible.oauthToken {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            switch self {
            case .me:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: nil)
            case .images:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: nil)
            case .deleteImage:
                urlRequest = try URLEncoding.default.encode(urlRequest, with: nil)
            case .postImage(let parameters):
                urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
            }
            return urlRequest
        }
    }
    
    class func login(completionBlock: ((Bool,String?, Error?) -> Void)?) {
        // must be hashed properly (this is just for a demo)
        let accessToken = UserDefaults.standard.value(forKey: Constants.StandardDefaultsKeyForAccessToken) as? String ?? nil
        if accessToken == nil {
            UsingOauth2(imgurSettings, performWithToken: { (token) in
                UserDefaults.standard.set(token, forKey: Constants.StandardDefaultsKeyForAccessToken)
                UserDefaults.standard.synchronize()
                ImgurRequestConvertible.oauthToken = token
                completionBlock?(true, token, nil)
                
            }) {
                let error = NSError(domain: Constants.UnbaleToGetAccessTokenErrorMessage, code: Constants.UnbaleToGetAccessTokenErrorCustomCode, userInfo: nil)
                completionBlock?(false, nil, error)
            }
        } else {
            ImgurRequestConvertible.oauthToken = accessToken
            completionBlock?(true,accessToken,nil)
        }
    }
    
    class func getImagesInBackground(completionBlock: (([UIImage?]?, Error?) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            Alamofire.request(ImgurRequestConvertible.images()).responseJSON(completionHandler: { (response) in
                if response.error == nil {
                    if let receivedJsonResult = response.result.value as? Dictionary<String,Any> {
                        let imgurResponse = ImgurResponse(json: receivedJsonResult)
                        if imgurResponse.success {
                            if let imgurResponseDataArray = imgurResponse.data as? [Any] {
                                var retrievedImages = [UIImage]()
                                for imgurImageJsonFormat in imgurResponseDataArray {
                                    if let image = ImgurAPIClient.getImageFromImgurJson(object: imgurImageJsonFormat) {
                                        retrievedImages.append(image)
                                    } else {
                                        let error = NSError(domain: Constants.ImageNotFoundErrorMessage, code: Constants.ImageNotFoundErrorCusotmCode, userInfo: nil)
                                        completionBlock?(nil,error)
                                    }
                                }
                                completionBlock?(retrievedImages,nil)
                            } else {
                                let error = NSError(domain: Constants.UnableToParseImgurResponseMessage, code: Constants.UnableToParseImgurResponseCustomCode, userInfo: nil)
                                completionBlock?(nil,error)
                            }
                            
                        } else {
                            let error = NSError(domain: Constants.UnableToParseImgurResponseMessage, code: Constants.UnableToParseImgurResponseCustomCode, userInfo: nil)
                            completionBlock?(nil,error)
                        }
                    }
                } else {
                    completionBlock?(nil,response.error)
                }
            })
        }
    }
    
    private class func getImageFromImgurJson(object: Any) -> UIImage? {
        if let imageJsonDict = object as? [String: Any] {
            let imgurImage = ImgurImage(json: imageJsonDict)
            if let imageUrl = URL(string: imgurImage.link) {
                if let imageData = try? Data(contentsOf: imageUrl) {
                    return UIImage(data: imageData)
                }
            }
        }
        return nil
    }
}

struct ImgurImage {
    var id: String
    var link: String
    
    init(json: Dictionary<String, Any>) {
        self.id = json["id"] as! String
        self.link = json["link"] as! String
    }
}

struct ImgurResponse {
    var data: Any
    var status: Int
    var success: Bool
    
    init(json: Dictionary<String,Any>) {
        self.data = json["data"]!
        self.status = json["status"] as! Int
        self.success = json["success"] as! Bool
    }
}


