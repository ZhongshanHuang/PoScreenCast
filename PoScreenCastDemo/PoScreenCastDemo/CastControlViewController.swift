//
//  CastControlViewController.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/18.
//

import UIKit
import PoScreenCast

class CastControlViewController: UIViewController {
    
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var castDevice: CastDevice!
    var remoteControl: CastRemoteControl!
    
    var trackDuration: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        remoteControl = CastRemoteControl(castDevice)
        remoteControl.delegate = self
        
        let url = "http://mvvideo10.meitudata.com/572ff691113842657.mp4"
        remoteControl.setAVTransportURI(url, videoName: "123")
    }


    @IBAction
    func play() {
        if playButton.isSelected {
            remoteControl.pause()
        } else {
            remoteControl.play()
        }
    }
    
    @IBAction
    func stop() {
        remoteControl.stop()
    }
    
    @IBAction
    func handleVolumeEvent(sender: UISlider) {
        guard let max = castDevice.volumeRange?.maximum,
              let min = castDevice.volumeRange?.minimum else {
            return
        }
        let volume = Float(min) + Float(max - min) * volumeSlider.value
        remoteControl.setVolume(Int(volume))
    }
    
    @IBAction
    func handleProgressEvent(sender: UISlider) {
        guard let trackDurationValue = trackDuration?.convertToTimeInterval,
              trackDurationValue > 0 else {
            return
        }
        
        let position = progressSlider.value * Float(trackDurationValue)
        remoteControl.seek(Double(position))
    }

}

extension CastControlViewController: CastRemoteControlDelegate {
    
    func remoteControl(_ remoteControl: CastRemoteControl, sendAction action: CastAction, response: CastActionResponse) {
        if let failure = response.failure {
            print("【\(action.type)】failure: \(failure.localizedDescription)")
        } else {
            print("【\(action.type)】Success")
            do {
                switch action.type {
                case .getPositionInfo:
                    updateProgress(try response.parseToPositionInfo())
                case .getTransportInfo:
                    updatePlayState(try response.parseToTransportInfo())
                case .getVolume:
                    updateVolume(try response.parseToVolume())
                case .setAVTransportURI:
                    remoteControl.startAsyncMediaInfo()
                default:
                    break
                }
            } catch {
                print("【\(action.type)】 parse failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateProgress(_ positionInfo: CastActionResponse.PositionInfo) {
        guard let trackDuration = positionInfo.trackDuration,
              let relTime = positionInfo.relTime else {
            return
        }
        self.trackDuration = trackDuration
        let trackDurationValue = Float(trackDuration.convertToTimeInterval)
        if trackDurationValue > 0 {
            let relTimeValue = Float(relTime.convertToTimeInterval)
            progressSlider.value = relTimeValue / trackDurationValue
        }
        
        currentLabel.text = positionInfo.relTime
        durationLabel.text = positionInfo.trackDuration
    }
    
    private func updateVolume(_ volume: CastActionResponse.Volume) {
        guard let max = castDevice.volumeRange?.maximum,
              let min = castDevice.volumeRange?.minimum else {
            return
        }
        volumeSlider.value = Float(min + volume.value) / Float(max - min)
    }
    
    private func updatePlayState(_ transportInfo: CastActionResponse.TransportInfo) {
        playButton.isSelected = transportInfo.currentTransportState == .playing
        if let state = transportInfo.currentTransportState, state == .stopped || state == .noMediaPresent {
            remoteControl.stopAsyncMediaInfo()
        }
    }
}

private extension String {
    
    var convertToTimeInterval: Int {
        var res = 0
        let components = split(separator: ":")
        for (idx, component) in components.reversed().enumerated() {
            if idx  > 2 { break }
            let value = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if let num = Int(value) {
                let mul: Double = pow(60, Double(idx))
                res += num * Int(mul)
            }
        }
        return res
    }
    
}
