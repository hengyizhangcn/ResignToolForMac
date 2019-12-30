//
//  ExternalData.swift
//  ResignTool
//
//  Created by zhanghengyi on 2019/12/30.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

import SwiftUI
import Combine

final class ExternalData: ObservableObject {
    let didChange = PassthroughSubject<Void, Never>()

    var filters: Dictionary<String, String> = [:] {
        didSet {
            didChange.send(())
        }
    }

    init() {
        filters["Juniper"] = ""
        filters["Beans"] = ""
    }

    var keys: [String] {
        return Array(filters.keys)
    }

    func binding(for key: String) -> Binding<String> {
        return Binding(get: {
            return self.filters[key] ?? ""
        }, set: {
            self.filters[key] = $0
        })
    }
}
