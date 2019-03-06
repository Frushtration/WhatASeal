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


class ViewController: UIViewController, AVAudioRecorderDelegate , AVAudioPlayerDelegate, UITextFieldDelegate{
    

    
    //Settings for all the audio input
    @IBOutlet weak var btnAudioRecord: UIButton!
    var recordingSession : AVAudioSession!
    var audioRecorder    :AVAudioRecorder!
    var settings         = [String : Int]()
    var audioPlayer : AVAudioPlayer!

    var recorder: AKNodeRecorder?
    var player: AKAudioPlayer?
    var tape: AKAudioFile?
    var micBooster: AKBooster?
    var moogLadder: AKMoogLadder?
    
    var state = State.readyToRecord
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet var audioInputPlot: EZAudioPlot!
    /*
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var freqLabel: UILabel!
    @IBOutlet weak var resonLabel: UILabel!
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var freqSlider: UISlider!
    @IBOutlet weak var moogLadderTitle: UILabel!
    @IBOutlet weak var resonSlider: UISlider!
    */
    
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
    
    /*
    //Set up the button to show the current freq
    @IBOutlet weak var frequency: UILabel!
     */
    
    //Set up for the timers
    var startTime = TimeInterval()
    var timer1:Timer = Timer()
    @IBOutlet weak var timer1Label: UILabel!
    @IBOutlet weak var timer2Label: UILabel!
    
    /*
    //Code to set up the plot
    func setupPlot() {
        let plot = AKNodeOutputPlot(mic, frame: audioInputPlot.bounds)
        plot.plotType = .Rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.blueColor()
        audioInputPlot.addSubview(plot)
    }
    */
    
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
        let mic = AKMicrophone()
        let micMixer = AKMixer(mic)
        micBooster = AKBooster(micMixer)
        
        // Will set the level of microphone monitoring
        micBooster!.gain = 0
        recorder = try? AKNodeRecorder(node: micMixer)
        tape = recorder?.audioFile
        player = tape?.player
        player?.looping = false
        player?.completionHandler = playingEnded
        
        moogLadder = AKMoogLadder(player!)
        
   
        let mainMixer = AKMixer(moogLadder!, micBooster!)
        
        AudioKit.output = mainMixer
        AudioKit.start()
        
       // setupUIForRecording()
    }
/*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AudioKit.output = silence
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        setupPlot()
        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)
    }
    
    @objc func updateUI() {
        if tracker.amplitude > 0.1 {
            frequencyLabel.text = String(format: "%0.1f", tracker.frequency)
            
            var frequency = Float(tracker.frequency)
            while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
                frequency /= 2.0
            }
            while frequency < Float(noteFrequencies[0]) {
                frequency *= 2.0
            }
            
            var minDistance: Float = 10_000.0
            var index = 0
            
            for i in 0..<noteFrequencies.count {
                let distance = fabsf(Float(noteFrequencies[i]) - frequency)
                if distance < minDistance {
                    index = i
                    minDistance = distance
                }
            }
            let octave = Int(log2f(Float(tracker.frequency) / frequency))
            noteNameWithSharpsLabel.text = "\(noteNamesWithSharps[index])\(octave)"
            noteNameWithFlatsLabel.text = "\(noteNamesWithFlats[index])\(octave)"
        }
        amplitudeLabel.text = String(format: "%0.2f", tracker.amplitude)
    }
    */
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
            timer1.invalidate()
 
        }
    }
    func updateTime() {
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


