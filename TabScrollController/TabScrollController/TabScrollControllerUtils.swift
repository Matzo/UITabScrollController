//
//  TabScrollControllerUtils.swift
//  TabScrollController
//
//  Created by 松尾 圭祐 on 2018/11/22.
//  Copyright © 2018年 松尾 圭祐. All rights reserved.
//

import UIKit

class TabScrollControllerUtils {
    class func progress(start: CGFloat, end: CGFloat, current: CGFloat, allowOverflow: Bool = true) -> CGFloat {
        guard start != end else { return start }
        var progress: CGFloat = (current - start) / (end - start)
        if !allowOverflow {
            progress = max(min(progress, 1.0), 0.0)
        }
        return progress
    }
    class func progressValue(start: CGFloat, end: CGFloat, progress: CGFloat) -> CGFloat {
        return (end - start) * progress + start
    }

    class func adjustedContentInset(from: UIScrollView) -> UIEdgeInsets {
        if #available(iOS 11, *) {
            return from.adjustedContentInset
        } else {
            return from.contentInset
        }
    }
}
