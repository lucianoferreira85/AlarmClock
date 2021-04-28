//
//  ViewController.swift
//  AlarmClock
//
//  Created by Luciano Ferreira on 25/04/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var clock: UIImageView!
    @IBOutlet weak var counter: UILabel!
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var startButton: UIButton!
    
    let pickerData = ["5", "10", "15" , "20", "25", "30", "35", "40", "45", "50", "55", "60"]
    var timer : Timer?
    var timerCount = 0
    var isAlarmRunning = false
    var audioPlayer: AVAudioPlayer?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        counter.isHidden = true
        self.timePicker.delegate = self
        self.timePicker.dataSource = self
        
        setClockImageOrientationChanged()
        askForAlarmPermission()
    }
    
    
    @IBAction func startAlarm(_ sender: UIButton) {
        handleAlarmState(Int(pickerData[timePicker.selectedRow(inComponent: 0)])!)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isPortrait {
            self.clock.image = UIImage(named: "alarm-clock")
        } else {
            self.clock.image = UIImage(named: "digital-clock")
        }
    }
    
    // MARK - Picker Selected value.

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(pickerData[row]) seconds."
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        print("Selected value \(pickerData[row])")
    }
    
    // MARK - Helper methods

    private func setClockImageOrientationChanged() {
        let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation

        if orientation == .portrait {
            self.clock.image = UIImage(named:"analog-clock")!
        } else if orientation == .landscapeRight || orientation == .landscapeLeft{
            self.clock.image = UIImage(named:"digital-clock")!
        }
    }

    private func startAlarmTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(performAlarmClock), userInfo: nil, repeats: true)
    }

    private func stopAlarmTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc func performAlarmClock() {
        timerCount = timerCount - 1
        counter.text = "\(timerCount)"

        if (timerCount <= 0) {
            playSound()
            stopAlarmTimer()
            shakeAlarmClock()
        }
    }

    private func showCounter() {
        counter.isHidden = false
        timePicker.isHidden = true
    }
    
    private func showAlarmPicker() {
        counter.isHidden = true
        timePicker.isHidden = false
    }
    
    private func toggleisAlarmRunning() {
        isAlarmRunning = !isAlarmRunning
    }

    private func playSound() {
        do {
            let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3")!
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else { return }

            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(error.description)
        } catch {
            print(Error.self)
        }
    }

    private func shakeAlarmClock() {
        CATransaction.begin()

        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = NSValue(cgPoint: CGPoint(x: clock.center.x - 10, y: clock.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: clock.center.x + 10, y: clock.center.y))
        animation.duration = 0.15
        animation.repeatCount = 12
        animation.autoreverses = true

        CATransaction.setCompletionBlock {
            self.startButton.setTitle("Começar", for: .normal)
            self.toggleisAlarmRunning()
            self.showAlarmPicker()
            self.toggleisAlarmRunning()
        }

        clock.layer.add(animation, forKey: "position")
        CATransaction.commit()
    }

    private func askForAlarmPermission() {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound]) {success, error in
            if success {
                let content = UNMutableNotificationContent()
                content.title = "Hello!"
                content.body = "Permission accepted."
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                let request = UNNotificationRequest(identifier: "Local Notification", content: content, trigger: trigger)
                center.add(request)
            } else {
                print("Permission denied")
            }
        }
    }

    private func handleAlarmState(_ pickerValue: Int) {
        if (!isAlarmRunning) {
            timerCount = pickerValue
            showCounter()
            counter.text = "\(pickerValue)"
            startAlarmTimer()
            toggleisAlarmRunning()
            startButton.setTitle("Cancelar", for: .normal)
            
        } else {
            startButton.setTitle("Começar", for: .normal)
            showAlarmPicker()
            stopAlarmTimer()
            toggleisAlarmRunning()
            clock.layer.removeAllAnimations()
            guard let player = audioPlayer else { return }
            player.stop()
        }
    }
}

