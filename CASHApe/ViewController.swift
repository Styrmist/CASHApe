//
//  ViewController.swift
//  CASHApe
//
//  Created by Kyrylo Danylov on 06.01.2023.
//

import UIKit
import CoreGraphics
import CGPathIntersection

enum GridAction {
    case draw
    case erase
}

// recieved from camera
struct IncomingData {
    let vertLines: Int
    let horLines: Int
    let data: [Int]
}

// description of one block on view
class Block {
    let startPoint: CGPoint
    let endPoint: CGPoint

    var isSelected: Bool
    private(set) var layer: CAShapeLayer?

    init(isSelected: Bool, startPoint: CGPoint, endPoint: CGPoint, layer: CAShapeLayer? = nil) {
        self.isSelected = isSelected
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.layer = layer
    }

    func setLayer(_ layer: CAShapeLayer) {
        self.layer = layer
    }

}

//internal representation of all blocks
struct BlocksData {
    let blocks: [[Block]]
    let blockWidth: CGFloat
    let blockHeight: CGFloat
}

class ViewController: UIViewController {

    let incomingData: IncomingData = .init(
        vertLines: 16,
        horLines: 8,
        data:
//        Data(bytes:11110100111101000100111101000100111101001111010001001111010001001111010011110100010011110100010011110100111101000100111101000100, count: 128)
        [1,1,1,1,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,0,1,0,0]
    )

    var data = [[Int]]()

    let cgGridView = GridView()

    // set on pan gesture start
    var panGestureStartLocation: CGPoint = .zero
    var currentAction: GridAction = .draw
    var blocksData: BlocksData!

    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            stackView.widthAnchor.constraint(equalToConstant: 200),
            stackView.heightAnchor.constraint(equalToConstant: 20),
        ])

        let drawButton = UIButton(type: .custom)
        drawButton.addTarget(self, action: #selector(drawTapAction), for: .touchUpInside)
        drawButton.setTitle("Draw", for: .normal)
        drawButton.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(drawButton)

        let eraseButton = UIButton(type: .custom)
        eraseButton.addTarget(self, action: #selector(eraseTapAction), for: .touchUpInside)
        eraseButton.setTitle("Erase", for: .normal)
        eraseButton.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(eraseButton)

        let encodeButton = UIButton(type: .custom)
        encodeButton.addTarget(self, action: #selector(encodeTapAction), for: .touchUpInside)
        encodeButton.setTitle("Encode", for: .normal)
        encodeButton.setTitleColor(.black, for: .normal)
        stackView.addArrangedSubview(encodeButton)

        view.addSubview(cgGridView)
        cgGridView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cgGridView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            cgGridView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            cgGridView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            cgGridView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            cgGridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cgGridView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tapAction)
        )
        cgGridView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(panAction)
        )
        cgGridView.addGestureRecognizer(panGesture)

        processIncomingData(incomingData)

        cgGridView.onLayoutSubviews = { [weak self] in
            guard let self else { return }

            //creates block data from incoming data
            self.createBlockData(
                from: self.data,
                for: self.cgGridView,
                horLines: self.incomingData.horLines,
                vertLines: self.incomingData.vertLines
            )
            // draw grid and save all CAShapeLayers
            self.cgGridView.drawGrid(data: self.blocksData)
            // fill grid blocks according to passed blocks data
            self.cgGridView.fillGrid(with: self.blocksData)
        }
    }

    // parse incoming 1d array to 2d array
    fileprivate func processIncomingData(_ incomingData: IncomingData) {
        let groupedData: [[Int]] = incomingData.data.enumerated().reduce(into: []) {
            if $1.offset % incomingData.horLines == 0 {
                $0.append([$1.element])
            } else {
                $0[$0.index(before: $0.endIndex)].append($1.element)
            }
        }

        self.data = groupedData
    }

    // parse incoming 1d array to 2d array
    fileprivate func encodeBlocksData(_ data: BlocksData) -> [Int] {
        data.blocks.flatMap { block in
            block.compactMap { $0.isSelected ? 1 : 0 }
        }
    }

    //creates block data from incoming data
    func createBlockData(from data: [[Int]], for view: UIView, horLines: Int, vertLines: Int) {
        let blockWidth = view.bounds.width / CGFloat(horLines)
        let blockHeight = view.bounds.height / CGFloat(vertLines)

        var blocks: [[Block]] = .init()
        var blocksLine: [Block] = .init()

        for dataLine in data.enumerated() {
            blocksLine = .init()
            for block in dataLine.element.enumerated() {
                let xOffset = CGFloat(block.offset)
                let yOffset = CGFloat(dataLine.offset)

                let startPoint = CGPoint(
                    x: blockWidth * xOffset,
                    y: blockHeight * yOffset
                )
                let endPoint = CGPoint(
                    x: blockWidth * xOffset + blockWidth,
                    y: blockHeight * yOffset + blockHeight
                )
                let block = Block(
                    isSelected: block.element == 1 ? true : false,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                blocksLine.append(block)
            }
            blocks.append(blocksLine)
        }

        self.blocksData = BlocksData(
            blocks: blocks,
            blockWidth: blockWidth,
            blockHeight: blockHeight
        )
    }


    func updateData(with point: CGPoint) {
        for dataLine in blocksData.blocks {
            for block in dataLine {
                if block.layer?.path?.contains(point) == true {
                    updateBlock(block)

                    return
                }
            }
        }
    }

    func updateData(startPoint: CGPoint, endPoint: CGPoint) {
        for dataLine in blocksData.blocks {
            for block in dataLine {
                guard let blockRectPath = block.layer?.path else { continue }

                let selectionRectPath = CGPath(rect: CGRect(p1: startPoint, p2: endPoint), transform: nil)

                if selectionRectPath.intersects(blockRectPath) {
                    updateBlock(block)
                }
            }
        }
    }

    func updateBlock(_ block: Block) {
        block.isSelected = currentAction == .draw ? true : false
    }

    @objc
    func tapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: cgGridView)
        updateData(with: point)
        cgGridView.fillGrid(with: blocksData)
    }

    @objc
    func panAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            panGestureStartLocation = sender.location(in: cgGridView)
        case .changed:
            updateData(startPoint: panGestureStartLocation, endPoint: sender.location(in: cgGridView))
            cgGridView.fillGrid(with: blocksData)
        case .ended:
            updateData(startPoint: panGestureStartLocation, endPoint: sender.location(in: cgGridView))
            cgGridView.fillGrid(with: blocksData)
        default:
            break
        }
    }

    @objc
    func drawTapAction() {
        currentAction = .draw
    }

    @objc
    func eraseTapAction() {
        currentAction = .erase
    }

    @objc
    func encodeTapAction() {
        print(encodeBlocksData(blocksData))
        print("")
    }

}

extension CGRect {
    init(p1: CGPoint, p2: CGPoint) {
        self.init(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p1.x - p2.x),
            height: abs(p1.y - p2.y)
        )
    }
}
