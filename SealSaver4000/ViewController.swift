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
    var engine:AVAudioEngine!
    var EQNode:AVAudioUnitEQ!

    //Set up circle animation
    var circle = CircleView()
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet var audioInputPlot: EZAudioPlot!
    @IBOutlet weak var gainSlider: UISlider!

    
    //Set up the keypad for the frequency
    @IBOutlet weak var FreqTestBox: UITextField!
    //Set the var for the freq
    var frequecy = 0

    
    //Timer Setup
    @IBOutlet weak var stopwatchLabel1: UILabel!
    var stopwatch1: LabelStopwatch!
    
    @IBOutlet weak var stopwatchLabel2: UILabel!
    var stopwatch2: LabelStopwatch!
    

    //Code to set up the plot
   
    func setupPlot() {
//        let file = EZAudioFile(url: self.directoryURL()! as URL!)
//        guard let data = recordingSession.getWaveformData() else { return }
//        print("What app Betch")
//        print(file)
//        print("I hate this")
 //       audioInputPlot.updateBuffer( data.buffers[0], withBufferSize: data.bufferSize )
        audioInputPlot.plotType = .rolling
        audioInputPlot.shouldFill = true
        audioInputPlot.shouldMirror = true
        audioInputPlot.backgroundColor = UIColor.black
        audioInputPlot.color = UIColor.red
        audioInputPlot.shouldFill = true;
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        FreqTestBox.keyboardType = UIKeyboardType.numberPad
        FreqTestBox.delegate = self
        FreqTestBox.addDoneButtonToKeyboard(myAction:  #selector(self.FreqTestBox.resignFirstResponder))
        stopwatch1 = LabelStopwatch(label: stopwatchLabel1)
        stopwatch2 = LabelStopwatch(label: stopwatchLabel2)
        let recordingSession = AVAudioSession.sharedInstance()
      
       let route = AVAudioSession.sharedInstance().currentRoute
        for port in route.inputs {
            print(port.portType)
            if port.portType == AVAudioSessionPortUSBAudio {
                print("YAS QUEEN")
                // USB Audio Location located
            }
        }
        
        if let desc = recordingSession.availableInputs?.first(where: { (desc) -> Bool in
            return desc.portType == AVAudioSessionPortUSBAudio
        }){
            do{
                try recordingSession.setPreferredInput(desc)
            } catch let error{
                print(error)
            }
        }
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Allow")
                    } else {
                        print("Dont Allow")
                    }
                }
            }
        } catch {
            print("failed to record!")
        }
        
        // Audio Settings
        settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
//        do {
//            try AKSettings.setSessionCategory(.PlayAndRecord, withOptions: .defaultToSpeaker)
//        } catch { print("Errored setting category.") }
        circle = CircleView(frame: CGRect(x: 40, y: 50, width: 40, height: 60))
        circle.backgroundColor = UIColor.clear
        view.addSubview(circle)
        
//        Timer.scheduledTimer(timeInterval: 0.1,
//                             target: self,
//                             selector: #selector(ViewController.checkPing),
//                             userInfo: nil,
//                             repeats: true)
//        
//        Timer.scheduledTimer(timeInterval: 0.1,
//                             target: self,
//                             selector: #selector(ViewController.checkTimeBetween),
//                             userInfo: nil,
//                             repeats: true)
    }
        //
    
        func initAudioEngine () {
            
            engine = AVAudioEngine()
            EQNode = AVAudioUnitEQ(numberOfBands: 2)
            EQNode.globalGain = 1
            engine.attach(EQNode)
            
            
            let filterParams = EQNode.bands[0] as AVAudioUnitEQFilterParameters
            
            filterParams.filterType = .bandPass
            
            // 20hz to nyquist
            filterParams.frequency = 5000.0
            
            //The value range of values is 0.05 to 5.0 octaves
            filterParams.bandwidth = 1.0
            
            filterParams.bypass = false
            
            // in db -96 db through 24 d
            filterParams.gain = 15.0
            
            let format = engine.inputNode?.inputFormat(forBus: 0)
            engine.connect(engine.inputNode!, to: engine.mainMixerNode, format: format)
            do {
                try engine.start()
            } catch { print("Error starting Engine")}
        }
//    @objc func checkPing(){
//        if(tracker.amplitude > 0.1){
////            let multiplier = tracker.amplitude * 100
//        
//            let multiplier = 100
//            //we have to update meters before we can get the metering values
//            audioRecorder.updateMeters()
//            //let multiplier = dBFS_convertTo_dB(dBFSValue: audioRecorder.avergaePowerForChannel(0))
//            circle.resizeCircleWithPulseAinmation(CGFloat(multiplier), duration: 0.5)
//        }
    
    
    @objc func checkTimeBetween(){
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

    @IBAction func timerButtonPressed1(_ sender: UIButton) {
        if (!stopwatch1.timer.isValid) {
            stopwatch1.start()
        } else {
            stopwatch1.stop()
        }
    }
    @IBAction func timerButtonPressed2(_ sender: UIButton) {
        if (!stopwatch2.timer.isValid) {
            stopwatch2.start()
        } else {
            stopwatch2.stop()
        }
    }

        /**
         Format dBFS to dB
         
         - author: RÅGE_Devil_Jåmeson
         - date: (2016-07-13) 20:07:03
         
         - parameter dBFSValue: raw value of averagePowerOfChannel
         
         - returns: formatted value
         */
    func dBFS_convertTo_dB (dBFSValue: Float) -> Float
    {
            var level:Float = 0.0
            let peak_bottom:Float = -60.0 // dBFS -> -160..0   so it can be -80 or -60
            
            if dBFSValue < peak_bottom
            {
                level = 0.0
            }
            else if dBFSValue >= 0.0
            {
                level = 1.0
            }
            else
            {
                let root:Float              =   2.0
                let minAmp:Float            =   powf(10.0, 0.05 * peak_bottom)
                let inverseAmpRange:Float   =   1.0 / (1.0 - minAmp)
                let amp:Float               =   powf(10.0, 0.05 * dBFSValue)
                let adjAmp:Float            =   (amp - minAmp) * inverseAmpRange
                
                level = powf(adjAmp, 1.0 / root)
            }
        return level
    }
    @IBAction func doPlay(_ sender: AnyObject) {
//        player!.play()
        if !audioRecorder.isRecording {
            self.audioPlayer = try! AVAudioPlayer(contentsOf: audioRecorder.url)
            self.audioPlayer.prepareToPlay()
            self.audioPlayer.delegate = self
            self.audioPlayer.play()
        }
    }
 
    @IBAction func click4Rec(_ sender: AnyObject) {
        if audioRecorder == nil {
            self.btnAudioRecord.setTitle("Stop", for: UIControlState.normal)
            //self.btnAudioRecord.backgroundColor = UIColor(red: 119.0/255.0, green: 119.0/255.0, blue: 119.0/255.0, alpha: 1.0)
            self.startRecording()
        } else {
            self.btnAudioRecord.setTitle("Record", for: UIControlState.normal)
            self.btnAudioRecord.backgroundColor = UIColor(red: 221.0/255.0, green: 27.0/255.0, blue: 50.0/255.0, alpha: 1.0)
            self.finishRecording(success: true)
        }
    }
    
    func directoryURL() -> NSURL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as NSURL
        let soundURL = documentDirectory.appendingPathComponent("sound.m4a")
        print(soundURL)
        return soundURL as NSURL?
    }
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        setupPlot()
        do {
            audioRecorder = try AVAudioRecorder(url: self.directoryURL()! as URL,
                                                settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
        } catch {
            finishRecording(success: false)
        }
        do {
            try audioSession.setActive(true)
            audioRecorder.record()
        } catch {
        }
    }
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        if success {
            print(success)
        } else {
            audioRecorder = nil
            print("Somthing Wrong.")
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
    func updateFrequency(value: Double){
        //This needs to be the bandpass filter values
        let filterParams = EQNode.bands[0] as AVAudioUnitEQFilterParameters
        filterParams.frequency = Float(value)
    }
    @IBAction func gain(sender: UISlider) {
        let val = sender.value
        //let filterParams = EQNode.bands[0] as AVAudioUnitEQFilterParameters
        //        filterParams.gain = val
        EQNode.globalGain = val
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




