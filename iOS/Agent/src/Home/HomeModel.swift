//
//  HomeModel.swift
//  Agent
//
//  Created by qinhui on 2024/12/10.
//

import UIKit

enum HomeContentType: Int {
    case voiceAgent
}

class HomeModel: NSObject {
    var title: String?
    var vc: UIViewController?
    
    static func createData() -> [HomeContentModel] {
        var dataArray = [HomeContentModel]()
        let homeModel = createContentModel(title: "Voice Agent", desc: "Voice Agent", imageName: "", type: .voiceAgent)
        dataArray.append(homeModel)
        
        return dataArray
    }
    
    static private func createContentModel(title: String?,
                                   desc: String?,
                                   imageName: String?,
                                   type: HomeContentType,
                                   isEnable: Bool = true) -> HomeContentModel {
        var model = HomeContentModel()
        model.title = title
        model.desc = desc
        model.imageName = imageName
        model.type = type
        model.isEnable = isEnable
        return model
    }

}

struct HomeContentModel {
    var title: String?
    var desc: String?
    var imageName: String?
    var type: HomeContentType = .voiceAgent
    var isEnable: Bool = true
}
