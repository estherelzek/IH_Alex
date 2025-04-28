//
//  BookMarkView.swift
//  IH_Alex
//
//  Created by Esther Elzek on 06/03/2025.
//
import UIKit

protocol BookmarkViewDelegate: AnyObject {
    func didToggleBookmark()
}

class BookmarkView: UIView {
    
    weak var delegate: BookmarkViewDelegate?
    private let shapeLayer = CAShapeLayer()
    private let diagonalLayer = CAShapeLayer()
    private var isBookmarked: Bool
    private var isHalfFilled: Bool
    private var fillLayer1: CAShapeLayer?
    private var fillLayer2: CAShapeLayer?

    init(frame: CGRect, isBookmarked: Bool, isHalfFilled: Bool) {
        self.isBookmarked = isBookmarked
        self.isHalfFilled = isHalfFilled
        super.init(frame: frame)
        setupView()
        if isBookmarked {
            applyHalfMask()
        }
    }

    required init?(coder: NSCoder) {
        self.isBookmarked = false
        self.isHalfFilled = false
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        tag = 999
        setupSquareBorder()
        drawDiagonalLine()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleBookmark))
        addGestureRecognizer(tapGesture)
    }

    private func setupSquareBorder() {
        shapeLayer.path = UIBezierPath(rect: bounds).cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(shapeLayer)
    }

    private func drawDiagonalLine() {
        let diagonalPath = UIBezierPath()
        diagonalPath.move(to: CGPoint(x: bounds.width, y: 0))
        diagonalPath.addLine(to: CGPoint(x: 0, y: bounds.height))
        diagonalLayer.path = diagonalPath.cgPath
        diagonalLayer.strokeColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        diagonalLayer.lineWidth = 2
        diagonalLayer.lineDashPattern = [4, 2]
        layer.addSublayer(diagonalLayer)
    }

    @objc private func toggleBookmark() {
        delegate?.didToggleBookmark()
    }

    func updateUI(isBookmarked: Bool, isHalfFilled: Bool) {
        self.isBookmarked = isBookmarked
        self.isHalfFilled = isHalfFilled

        if isBookmarked {
            applyHalfMask()
        } else {
            clearHalfMask()
        }
    }

    private func applyHalfMask() {
        clearHalfMask()
        let fillLayer1 = CAShapeLayer()
        let fillPath1 = UIBezierPath()
        fillPath1.move(to: CGPoint(x: bounds.width, y: 0))
        fillPath1.addLine(to: CGPoint(x: 0, y: bounds.height))
        fillPath1.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        fillPath1.close()
        fillLayer1.path = fillPath1.cgPath
        fillLayer1.fillColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        layer.addSublayer(fillLayer1)
        self.fillLayer1 = fillLayer1

        let fillLayer2 = CAShapeLayer()
        let fillPath2 = UIBezierPath()
        fillPath2.move(to: CGPoint(x: 0, y: 0))
        fillPath2.addLine(to: CGPoint(x: 0, y: bounds.height))
        fillPath2.addLine(to: CGPoint(x: bounds.width, y: 0))
        fillPath2.close()
        fillLayer2.path = fillPath2.cgPath
        fillLayer2.fillColor = UIColor(hex: "#085C90").cgColor
        layer.addSublayer(fillLayer2)
        self.fillLayer2 = fillLayer2
    }

    private func clearHalfMask() {
        fillLayer1?.removeFromSuperlayer()
        fillLayer1 = nil
        fillLayer2?.removeFromSuperlayer()
        fillLayer2 = nil
    }

}
