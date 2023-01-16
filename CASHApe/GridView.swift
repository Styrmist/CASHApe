//
//  GridView.swift
//  CASHApe
//
//  Created by Kyrylo Danylov on 16.01.2023.
//

import UIKit

final class GridView: UIView {

    var onLayoutSubviews: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()

        onLayoutSubviews?()

    }

    // draw grid and save all CAShapeLayers
    func drawGrid(data: BlocksData) {
        for blocksLine in data.blocks {
            for block in blocksLine {

                let x = block.startPoint.x
                let y = block.startPoint.y

                let levelLayer = CAShapeLayer()
                levelLayer.path = UIBezierPath(
                    rect: CGRect(
                        x: bounds.origin.x + x,
                        y: bounds.origin.y + y,
                        width: data.blockWidth,
                        height: data.blockHeight
                    )
                ).cgPath
                levelLayer.fillColor = .none
                levelLayer.lineWidth = 1
                levelLayer.strokeColor = UIColor.black.cgColor

                block.setLayer(levelLayer)
                layer.addSublayer(levelLayer)
            }
        }

    }

    // fill grid blocks according to passed blocks data
    func fillGrid(with blocksData: BlocksData) {
        for dataLine in blocksData.blocks {
            for block in dataLine {

                if block.isSelected {
                    block.layer?.fillColor = UIColor.blue.withAlphaComponent(0.7).cgColor
                } else {
                    block.layer?.fillColor = .none
                }
            }
        }
    }

}
