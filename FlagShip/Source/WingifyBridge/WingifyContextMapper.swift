//
//  WingifyContextMapper.swift
//  Flagship
//

import Foundation
import Wingify_FME

enum WingifyContextMapper {
    static func makeContext(from visitor: FSVisitor) -> WingifyUserContext {
        WingifyUserContext(
            id: visitor.visitorId,
            customVariables: visitor.getContext()
        )
    }
}
