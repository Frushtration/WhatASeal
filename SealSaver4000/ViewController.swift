//
//  ViewController.swift
//  SealSaver4000
//
//  Created by Christie  on 1/19/19.
//  Copyright © 2019 Christie Frush. All rights reserved.
//
import UIKit
import AVFoundation
import CoreAudio
import CoreAudioKit
import Foundation
import AVKit
import AudioKit
//import CoreLocation


class ViewController: UIViewController, AVAudioRecorderDelegate , AVAudioPlayerDelegate, UITextFieldDelegate{
    
    //Settings for all the audio input
    @IBOutlet weak var btnAudioRecord: UIButton!
    var recordingSession : AVAudioSession!
    var audioRecorder    :AVAudioRecorder!
    var settings         = [String : Int]()
    var audioPlayer : AVAudioPlayer!
    
    var mic: AKMicrophone!
    var recorder: AKNodeRecorder?
    var player: AKAudioPlayer?
    var tape: AKAudioFile?
    var micBooster: AKBooster?
    var freqFilter: AKMoogLadder?
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!

    
    //Set up circle animation
    var circle = CircleView()
    
    var state = State.readyToRecord
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet var audioInputPlot: EZAudioPlot!
    @IBOutlet weak var gainSlider: UISlider!
    
    enum State {
        case readyToRecord
        case recording
        //case readyToPlay
        //case playing
    }
    
    //Set up the keypad for the frequency
    @IBOutlet weak var FreqTestBox: UITextField!
    //Set the var for the freq
    var frequecy = 0

    //Set up for the timers
    var startTime = TimeInterval()
    var timer1:Timer = Timer()
    @IBOutlet weak var timer1Label: UILabel!
    @IBOutlet weak var timer2Label: UILabel!
   // var finalTimer1:String

    //Code to set up the plot
    func setupPlot() {
        let plot = AKNodeOutputPlot(mic, frame: audioInputPlot.bounds)
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.backgroundColor = UIColor.black
        plot.color = UIColor.red
        plot.shouldFill = true;
        audioInputPlot.addSubview(plot)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        FreqTestBox.keyboardType = UIKeyboardType.numberPad
        FreqTestBox.delegate = self
        FreqTestBox.addDoneButtonToKeyboard(myAction:  #selector(self.FreqTestBox.resignFirstResponder))
        
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSessionCategory(.PlayAndRecord, withOptions: .defaultToSpeaker)
        } catch { print("Errored setting category.") }
        
        // Patching
         AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        let micMixer = AKMixer(mic)
        freqFilter = AKMoogLadder(mic)

        micBooster = AKBooster(micMixer)
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)
        
        // Will set the level of microphone monitoring
        micBooster!.gain = 0
        recorder = try? AKNodeRecorder(node: micMixer)
        tape = recorder?.audioFile
        player = tape?.player
        player?.looping = false
        player?.completionHandler = playingEnded
        
        //let mainMixer = AKMixer(freqFilter!, micBooster!)
        
        AudioKit.output = silence
        AudioKit.start()
        
        circle = CircleView(frame: CGRect(x: 40, y: 50, width: 40, height: 60))
        circle.backgroundColor = UIColor.clear
        view.addSubview(circle)
        
        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.checkPing),
                             userInfo: nil,
                             repeats: true)
    }
    
    func updateFrequency(value: Double){
        freqFilter?.cutoffFrequency = value
    }
    
    @objc func checkPing(){
        if(tracker.amplitude > 0.1){
            let multiplier = tracker.amplitude * 100
            circle.resizeCircleWithPulseAinmation(CGFloat(multiplier), duration: 0.5)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPlot()

       // setUpCircle()
    }
     func playingEnded() {
        DispatchQueue.main.async {
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startStopTimer1(_ sender: AnyObject) {
        if (!timer1.isValid) {
            timer1 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
            startTime = Date.timeIntervalSinceReferenceDate
        } else {
            //you need to save the time after this
            //also leave the timer label on until a new timer is created
            //finalTimer1 =  timer1Label.text!
            timer1.invalidate()
        }
    }
    
    func updateTime(/*startTime:TimeInterval, timerLabel: UILabel*/) {
        let currentTime = Date.timeIntervalSinceReferenceDate
        
        //Find the difference between current time and start time.
        var elapsedTime: TimeInterval = currentTime - startTime
        
        //calculate the minutes in elapsed time.
        let minutes = UInt8(elapsedTime / 60.0)
        elapsedTime -= (TimeInterval(minutes) * 60)
        
        //calculate the seconds in elapsed time.
        let seconds = UInt8(elapsedTime)
        elapsedTime -= TimeInterval(seconds)
        
        //find out the fraction of milliseconds to be displayed.
        let fraction = UInt8(elapsedTime * 100)
        
        //add the leading zero for minutes, seconds and millseconds and store them as string constants
        
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strFraction = String(format: "%02d", fraction)
        
        //concatenate minuets, seconds and milliseconds as assign it to the UILabel
        timer1Label.text = "\(strMinutes):\(strSeconds):\(strFraction)"
    }

    func directoryURL() -> NSURL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        let soundURL = documentDirectory.appendingPathComponent("sound.m4a")
        print(soundURL)
        return soundURL as NSURL?
    }

    @IBAction func doPlay(_ sender: AnyObject) {
        player!.play()
    
    }
 
    @IBAction func click4Rec(_ sender: AnyObject) {
        switch state {
        case .readyToRecord :
            //infoLabel.text = "Recording"
            //mainButton.setTitle("Stop", for: .normal)
            state = .recording
            // microphone will be monitored while recording
            // only if headphones are plugged
            if AKSettings.headPhonesPlugged {
                micBooster!.gain = 1
            }
            do {
                try recorder?.record()
            } catch { print("Errored recording.") }
            
        case .recording :
            // Microphone monitoring is muted
            micBooster!.gain = 0
            do {
                try player?.reloadFile()
            } catch { print("Errored reloading.") }
            
            let recordedDuration = player != nil ? player?.audioFile.duration  : 0
            if recordedDuration! > 0.0 {
                recorder?.stop()
               // setupUIForPlaying ()
            }
        }

    }
 
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print(flag)
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?){
        print(error.debugDescription)
    }
    internal func audioPlayerBeginInterruption(_ player: AVAudioPlayer){
        print(player.debugDescription)
    }
    
    @IBAction func setFrequency(_ sender: AnyObject) {
        FreqTestBox.resignFirstResponder()
        processInputOnDone()
    }
    //Save the number and set it to the current desired frequency
    func processInputOnDone() {
        if let text = FreqTestBox.text, !text.isEmpty {
            frequecy = Int(FreqTestBox.text!)!
            //Update the controls to adjust for the frequencyx
            updateFrequency(value: Double(frequecy))
        }
        print(frequecy)
    }
}

     /* Taken from https://gist.github.com/jplazcano87/8b5d3bc89c3578e45c3e */
extension UITextField{
    
    func addDoneButtonToKeyboard(myAction:Selector?){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: myAction)
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
}


