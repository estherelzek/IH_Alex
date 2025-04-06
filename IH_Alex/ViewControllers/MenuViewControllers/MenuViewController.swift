//
//  MenuViewController.swift
//  IH_Alex
//
//  Created by Esther Elzek on 11/03/2025.
//

import UIKit

protocol MenuViewDelegate: AnyObject {
    func keepDisplayOn()
    func rotateScreen()
    func changeLineSpacing(wide: Bool)
    func zoom(increase: Bool)
    func changeBackgroundAndFontColor(background: UIColor, font: UIColor)
    func adjustBrightness(value: Float)
    func changeScrollMode(to mode: ScrollMode)
}

class MenuViewController: UIViewController {

    weak var delegate: MenuViewDelegate?
    @IBOutlet weak var menuContentView: UIView!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var rotateScreenButton: UISwitch!
    @IBOutlet weak var keepScreenOnSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        menuContentView.layer.cornerRadius = 10
        menuContentView.layer.masksToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        setUpBriteness()
        if UserDefaults.standard.object(forKey: "rotationLocked") == nil {
            UserDefaults.standard.set(false, forKey: "rotationLocked") // Default: Unlocked
        }
        let savedRotationLock = UserDefaults.standard.bool(forKey: "rotationLocked")
        rotateScreenButton.isOn = !savedRotationLock
        if UserDefaults.standard.object(forKey: "keepDisplayOn") == nil {
            UserDefaults.standard.set(true, forKey: "keepDisplayOn")
        }
        let isScreenAlwaysOn = UserDefaults.standard.bool(forKey: "keepDisplayOn")
        keepScreenOnSwitch.isOn = isScreenAlwaysOn
    }

    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: view)
        if !menuContentView.frame.contains(touchPoint) {
            closeMenu()
        }
    }
    
    func setUpBriteness() {
        brightnessSlider.minimumValue = 0.0
        brightnessSlider.maximumValue = 1.0
        let savedBrightness = UserDefaults.standard.value(forKey: "savedBrightness") as? Float ?? Float(UIScreen.main.brightness)
        brightnessSlider.value = savedBrightness
    }

    private func closeMenu() {
        self.view.removeFromSuperview()
        self.removeFromParent()
    }

    @IBAction func keepDisplayOn(_ sender: Any) {
        delegate?.keepDisplayOn()
    }

    @IBAction func RotateScreenTapped(_ sender: UISwitch) {
        let isLocked = !sender.isOn // ❗ Switch ON = Unlocked, OFF = Locked
        UserDefaults.standard.set(isLocked, forKey: "rotationLocked") // ✅ Save state
        delegate?.rotateScreen() // ✅ Call the delegate method to apply rotation lock
    }

    @IBAction func wideSpacingButtonTapped(_ sender: Any) {
        delegate?.changeLineSpacing(wide: true)
    }

    @IBAction func tightSpacingButtonTapped(_ sender: Any) {
        delegate?.changeLineSpacing(wide: false)
    }

    @IBAction func ZoomInButtonTapped(_ sender: Any) {
        delegate?.zoom(increase: true)
    }

    @IBAction func ZoomOutButtonTapped(_ sender: Any) {
        delegate?.zoom(increase: false)
    }

    @IBAction func wightBackgroundBlackFontTapped(_ sender: Any) {
        delegate?.changeBackgroundAndFontColor(background: .white, font: .black)
    }

    @IBAction func lightbackgroundBlackFont(_ sender: Any) {
        delegate?.changeBackgroundAndFontColor(background: UIColor(hex: "#F5F4F4"), font: .black)
    }

    @IBAction func graybackgroundWhiteFontTapped(_ sender: Any) {
        delegate?.changeBackgroundAndFontColor(background: .lightGray, font: .white)
    }

    @IBAction func darkBackgroundWhiteFont(_ sender: Any) {
        delegate?.changeBackgroundAndFontColor(background: .black, font: .white)
    }

    @IBAction func brightnessSliderTapped(_ sender: UISlider) {
        let newBrightness = sender.value
        delegate?.adjustBrightness(value: newBrightness) // ✅ Correctly notify delegate
        UserDefaults.standard.set(newBrightness, forKey: "savedBrightness") // ✅ Save brightness
    }

    @IBAction func verticalScrollTapped(_ sender: Any) {
        delegate?.changeScrollMode(to: .verticalScrolling)
    }

    @IBAction func horizontialScrollTapped(_ sender: Any) {
        delegate?.changeScrollMode(to: .horizontalPaging)
    }
}

