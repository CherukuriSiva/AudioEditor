//
//  ViewController.swift
//  AudioEditor
//
//  Created by Apple on 16/08/16.
//  Copyright © 2016 Cherukuri. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,RETrimControlDelegate {
    
    var audioDurationUILabel : UILabel!
    var audioPlayerUIButton : UIButton!
    var doneUIButton : UIButton!
    var isItPlayingAudio : Bool!
    var player:AVAudioPlayer = AVAudioPlayer()
    var trimControl: RETrimControl!
    var startTimeInSeconds : Int64 = 0
    var stopTimeInSeconds : Int64 = 0
    var localURLPath : URL!
    var isItFirstTime : Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isItPlayingAudio = false
        self.setupInitialUIControls()
        self.downloadMp3FileFromWeb()
    }
    
    //Setup Intial UI - UILabels, UIButtons etc
    func setupInitialUIControls(){
        
        trimControl = RETrimControl(frame: CGRect(x: self.view.frame.size.width * 0.03125, y: (self.view.frame.size.height - 150) / 2.0, width: self.view.frame.size.width * 0.9375, height: 100))
        trimControl.delegate = self
        self.view!.addSubview(trimControl)
        trimControl.length = 300
        
        audioDurationUILabel = UILabel()
        audioPlayerUIButton = UIButton()
        doneUIButton = UIButton()
        
        audioDurationUILabel.font = UIFont(name: "MarkerFelt-Thin", size: self.view.frame.size.height * 0.02816901408)
        audioDurationUILabel.textColor = UIColor.gray
        
        
        audioPlayerUIButton.frame = CGRect(x: self.view.frame.size.width * 0.03125, y: trimControl.frame.origin.y + trimControl.frame.size.height + 10, width: self.view.frame.size.height * 0.04225352113, height: self.view.frame.size.height * 0.04225352113)
        audioPlayerUIButton.setImage(UIImage(named: "play_audio.png"), for: UIControlState())
        audioPlayerUIButton.backgroundColor = UIColor.red
        audioPlayerUIButton.layer.cornerRadius = audioPlayerUIButton.frame.size.height / 2
        audioDurationUILabel.frame = CGRect(x: audioPlayerUIButton.frame.origin.x + audioPlayerUIButton.frame.size.width + 20, y: trimControl.frame.origin.y + trimControl.frame.size.height + 10, width: 200, height: self.view.frame.size.height * 0.04225352113)
        audioPlayerUIButton.addTarget(self, action: #selector(self.audioPlayerButtonTapped), for: .touchUpInside)
        audioPlayerUIButton.isEnabled = false
        self.view.addSubview(audioDurationUILabel)
        self.view.addSubview(audioPlayerUIButton)
        
        doneUIButton.frame = CGRect(x: self.view.frame.size.width - 100, y: self.view.frame.size.height * 0.2464788732, width: 90, height: 30)
        doneUIButton.setTitle("Done", for: UIControlState())
        doneUIButton.backgroundColor = UIColor.black
        doneUIButton.titleLabel?.textColor = UIColor.white
        doneUIButton.addTarget(self, action: #selector(self.didEditButtonClick), for: .touchUpInside)
        doneUIButton.layer.cornerRadius = 5.0
        doneUIButton.isHidden = true
        self.view.addSubview(doneUIButton)
        
    }
    
    //Download .wav file using NSURLSession
    func downloadMp3FileFromWeb(){
        
        //  First you need to create your audio url
        if let audioUrl = URL(string: "https://az817931.vo.msecnd.net/audiofiles/normalized-meet_318122810a836ad9c314508833ab39e1ed8176c_r.wav") {
        
        //if let audioUrl = NSURL(string: "http://radio.spainmedia.es/wp-content/uploads/2015/12/tailtoddle_lo4.mp3") {
            
            // then lets create your document folder url
            let documentsDirectoryURL =  FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // lets create your destination file url
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(audioUrl.lastPathComponent ?? "audio.wav")
            print(destinationUrl)
            
            // to check if it exists before downloading it
            if FileManager().fileExists(atPath: destinationUrl.path) {
                //The file already exists at path
                
                self.localURLPath = destinationUrl
                self.playMusicFromFilePath(destinationUrl)
                
                // if the file doesn't exist
            } else {
                
                // you can use NSURLSession.sharedSession to download the data asynchronously
                URLSession.shared.downloadTask(with: audioUrl, completionHandler: { (location, response, error) -> Void in
                    guard let location = location, error == nil else { return }
                    do {
                        // after downloading your file you need to move it to your destination url
                        try FileManager().moveItem(at: location, to: destinationUrl)
                        print("File moved to documents folder %@",destinationUrl)
                        
                        self.localURLPath = destinationUrl
                        self.playMusicFromFilePath(destinationUrl)
                        
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                    
                }).resume()
            }
        }
        
    }
    
    //Delegate method to get slider values(Time)
    func trimControl(_ trimControl: RETrimControl, didChangeLeftValue leftValue: String, rightValue: String) {
        
        audioDurationUILabel.text = String(format: "%@ - %@", leftValue, rightValue)
        self.setupStartAndStopTimes(leftValue,rightSliderValueString: rightValue)
        doneUIButton.isHidden = false
    }
    
    //Tapped on Done button after trimming audio
    func didEditButtonClick(_ sender: AnyObject) {
        
        doneUIButton.isHidden = true
        player.stop()
        audioPlayerUIButton.setImage(UIImage(named: "play_audio.png"), for: UIControlState())
        isItPlayingAudio = false
        
        if (trimControl != nil){
            
            trimControl.removeFromSuperview()
            trimControl = RETrimControl(frame: CGRect(x: self.view.frame.size.width * 0.03125, y: (self.view.frame.size.height - 150) / 2.0, width: self.view.frame.size.width * 0.9375, height: 100))
            trimControl.length = stopTimeInSeconds - startTimeInSeconds
            trimControl.delegate = self
            self.view.addSubview(trimControl)
            
        }
        
        print(self.localURLPath.path)
        
        if FileManager.default.fileExists(atPath: self.localURLPath.path) {
            print("2.File exists")
            
            if let asset : AVAsset = AVAsset(url: self.localURLPath ) {
                // do something with the asset
                self.trimWavFile(asset, fileName: "trimmed")
                
            }
            
        }else{
            print("2.File doesn't exists")
            
            if let resourceUrl = Bundle.main.url(forResource: "SourceAudio", withExtension: "mp3") {
                
                if let asset : AVAsset = AVAsset(url: resourceUrl ) {
                    // do something with the asset
                    self.trimWavFile(asset, fileName: "trimmed")
                    
                }
            }

        }
        
    }
    
    //Pause and play audio file
    func audioPlayerButtonTapped(_ sender: AnyObject) {
        
        if !isItPlayingAudio {
            
            player.play()
            
            audioPlayerUIButton.setImage(UIImage(named: "pause_audio.png"), for: UIControlState())
            isItPlayingAudio = true
            
        }else{
            
            player.pause()
            
            audioPlayerUIButton.setImage(UIImage(named: "play_audio.png"), for: UIControlState())
            isItPlayingAudio = false
        }
        
    }
    
    //To set up start and stop times
    func setupStartAndStopTimes(_ leftSliderValueString:String, rightSliderValueString:String){
        
        let startTimeValuesArray = leftSliderValueString.components(separatedBy: ":")
        let stopTimeValuesArray = rightSliderValueString.components(separatedBy: ":")
        
        startTimeInSeconds = (Int64(startTimeValuesArray[0])! * 60) + Int64(startTimeValuesArray[1])!
        stopTimeInSeconds = (Int64(stopTimeValuesArray[0])! * 60) + Int64(stopTimeValuesArray[1])!
        
    }
    
    //Trim the .wav file based on start and stop times
    func trimWavFile(_ asset:AVAsset, fileName:String) {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trimmedSoundFileURL = documentsDirectory.appendingPathComponent(String(format: "%@.m4a", fileName))
        
        let filemanager = FileManager.default
        if filemanager.fileExists(atPath: trimmedSoundFileURL.path) {
            print("sound exists")
            do{
                try FileManager.default.removeItem(atPath: trimmedSoundFileURL.path)
            }catch{
            }
        }else{
            print("sound doesn't exists")
            
        }
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        exporter!.outputFileType = AVFileTypeAppleM4A
        exporter!.outputURL = trimmedSoundFileURL
        
        let duration = CMTimeGetSeconds(asset.duration)
        if (duration < 5.0) {
            print("sound is not long enough")
            return
        }
        // e.g. the first 5 seconds
        let startTime = CMTimeMake(startTimeInSeconds, 1)
        let stopTime = CMTimeMake(stopTimeInSeconds, 1)
        
        print("Start and stop times %i %i",startTimeInSeconds,stopTimeInSeconds)
        
        let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
        exporter!.timeRange = exportTimeRange
        
        
        // do it
        exporter!.exportAsynchronously(completionHandler: {
            switch exporter!.status {
            case  AVAssetExportSessionStatus.failed:
                print("export failed \(exporter!.error)")
            case AVAssetExportSessionStatus.cancelled:
                print("export cancelled \(exporter!.error)")
            default:
                print("export complete")
                print(trimmedSoundFileURL)
                self.playMusicFromFilePath(trimmedSoundFileURL)
                
            }
        })
    }
    
    //Play music file using AVAudioPlayer
    func playMusicFromFilePath(_ resourceUrl: URL) {
        
        if FileManager.default.fileExists(atPath: resourceUrl.path) {
            
            do {
                self.player = try AVAudioPlayer(contentsOf: resourceUrl)
                player.prepareToPlay()
                player.volume = 1.0
                trimControl.length = (NSInteger)(player.duration)
                audioPlayerUIButton.isEnabled = true
                
                if(isItFirstTime){
                    audioDurationUILabel.text = String(format: "%.2f - %@", 0.00, String(format: "%d.%d",(NSInteger)(player.duration/60),(NSInteger)(player.duration.truncatingRemainder(dividingBy: 60))))
                    print(audioDurationUILabel.text)
                    isItFirstTime = false
                }
                
            } catch let error as NSError {
                //self.player = nil
                print(error.localizedDescription)
            } catch {
                print("AVAudioPlayer init failed")
            }
            
        }
    }
    
    
    
//    func tempMethod(){
//        
//        
//        let audioUrl = NSURL(string: "http://freetone.org/ring/stan/iPhone_5-Alarm.mp3")
//        
//        let documentDirectoryURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
//        
//        // your destination file url
//        let destination = try! documentDirectoryURL.path.appendingPathComponent(audioUrl.lastPathComponent!)
//        print(destination)
//        
//        // check if it exists before downloading it
//        if FileManager().fileExists(atPath: destination.path!) {
//        
//        print("The file already exists at path")
//        
//        } else {
//        //  if the file doesn't exist
//        //  just download the data from your url
//        URLSession.shared.downloadTask(with: audioUrl, completionHandler: { (location, response, error) in
//        // after downloading your data you need to save it to your destination url
//        guard
//        let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
//        let mimeType = response?.mimeType, mimeType.hasPrefix("audio"),
//        let location = location, error == nil
//        else {
//        return
//        }
//        
//        do {
//        
//        try FileManager.default.moveItem(at: location, to: destination)
//        print("file saved")
//        }
//        catch let error as NSError {
//        print(error.localizedDescription)
//        }
//        
//        }).resume()
//        }
//        
//        
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

//        if NSFileManager.defaultManager().fileExistsAtPath((player.url?.path)!) {
//
//            print(self.localURLPath.path)
//            if let asset : AVAsset = AVAsset(URL: self.localURLPath ) {
//                // do something with the asset
//                self.trimWavFile(asset, fileName: "trimmed")
//
//            }
//
//        }else{
//            print("File doesn't exists")
//
//            if let resourceUrl = NSBundle.mainBundle().URLForResource("SourceAudio", withExtension: "mp3") {
//
//                if let asset : AVAsset = AVAsset(URL: resourceUrl ) {
//                    // do something with the asset
//                    self.trimWavFile(asset, fileName: "trimmed")
//
//                }
//            }
//        }


//    func setupAndPlayInitialMusicFile() {
//
//        if let resourceUrl = NSBundle.mainBundle().URLForResource("SourceAudio", withExtension: "mp3") {
//            if NSFileManager.defaultManager().fileExistsAtPath(resourceUrl.path!) {
//
//                print(resourceUrl.path)
//                self.playMusicFromFilePath(resourceUrl)
//
//            }
//        }
//
//    }


//    let player2 = AVQueuePlayer()
//            player2.removeAllItems()
//            player2.insertItem(AVPlayerItem(URL: resourceUrl), afterItem: nil)
//            player2.play()

//    func prepareWavToPlay(url:NSURL) {
//        print("preparing")
//
//        do {
//            self.player = try AVAudioPlayer(contentsOfURL: url)
//            player.prepareToPlay()
//            player.volume = 1.0
//            trimControl.length = (NSInteger)(player.duration)
//            audioPlayerUIButton.enabled = true
//            audioDurationUILabel.text = String(format: "%.2f-%@", 0.00, String(format: "%d.%d",(NSInteger)(player.duration/60),(NSInteger)(player.duration%60)))
//            print(audioDurationUILabel.text)
//
//        } catch let error as NSError {
//            //self.player = nil
//            print(error.localizedDescription)
//        } catch {
//            print("AVAudioPlayer init failed")
//        }
//
//    }

//        if let resourceUrl = NSBundle.mainBundle().URLForResource("SourceAudio", withExtension: "mp3") {

//        }

//self.setupAndPlayInitialMusicFile()

/*let documentDirectoryURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory,
 inDomain: .UserDomainMask,
 appropriateForURL: nil,
 create: true)*/

//        let databaseURL = documentDirectoryURL.URLByAppendingPathComponent((player.url?.path)!)

//        let databaseURL = player.url
//
//        var error : NSError?
//        let fileExists = databaseURL!.checkResourceIsReachableAndReturnError(&error)
//        if !fileExists {
//            print(error)
//        }else{
//            print("File exists")
//        }

//        let url = "http://radio.spainmedia.es/wp-content/uploads/2015/12/tailtoddle_lo4.mp3"
//
//        //let url = "https://az817931.vo.msecnd.net/audiofiles/normalized-meet_318122810a836ad9c314508833ab39e1ed8176c_r.wav"
//        let searchURL = NSURL(string: url)
//
//        print(searchURL)
//
//        downloadFileFromURL(searchURL!)

//            print(self.localURLPath.path!)
//
//            if NSFileManager.defaultManager().fileExistsAtPath(self.localURLPath.path!) {
//                print("1.File exists")
//            }else{
//                print("1.File doesn't exists")
//            }

//    func downloadFileFromURL(url:NSURL){
//        var downloadTask:NSURLSessionDownloadTask
//        downloadTask = NSURLSession.sharedSession().downloadTaskWithURL(url, completionHandler: { (reponseUrl, response, error) -> Void in
//
//            self.localURLPath = reponseUrl
//            self.playMusicFromFilePath(reponseUrl!)
//
//        })
//
//        downloadTask.resume()
//
//    }

//                print(self.localURLPath.path!)
//
//                if NSFileManager.defaultManager().fileExistsAtPath(self.localURLPath.path!) {
//                    print("1.File exists")
//                }else{
//                    print("1.File doesn't exists")
//                }

//                        print(self.localURLPath.path!)
//
//                        if NSFileManager.defaultManager().fileExistsAtPath(self.localURLPath.path!) {
//                            print("1.File exists")
//                        }else{
//                            print("1.File doesn't exists")
//                        }
