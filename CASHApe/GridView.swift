//
//  GridView.swift
//  CASHApe
//
//  Created by Kyrylo Danylov on 16.01.2023.
//

import UIKit

final class GridView: UIView {

    var onLayoutSubviews: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        onLayoutSubviews?()

    }

}
