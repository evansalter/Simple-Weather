//
//  WriteBackProtocol.swift
//  Simple Weather
//
//  Created by Evan Salter on 2015-06-15.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import Foundation

protocol writeValueBackDelegate {
    func writeValueBack(name: String, woeid: String)
}
