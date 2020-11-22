//
//  ViewController.swift
//  VideoMarkup
//
//  Created by Pat Trudel on 2020-11-20.
//

import UIKit
import Player
import MobileCoreServices
import PencilKit
import PhotosUI

class ViewController: UIViewController {
    
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    
    let player = Player()
    let canvas = PKCanvasView(frame: .zero)
    let toolPicker = PKToolPicker()
    var playerTimeScale: CMTimeScale {
        player.asset?.duration.timescale ?? 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCanvasView()
        setupChildViewController()
        setupGestureRecognizers()
    }
    
    func setupChildViewController() {
        player.playerDelegate = self
        player.playbackDelegate = self
        addChild(player)
        view.addSubview(player.view)
        view.sendSubviewToBack(player.view)
        player.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            player.view.topAnchor.constraint(equalTo: view.topAnchor),
            player.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            player.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            player.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        player.didMove(toParent: self)
    }
    
    func setupCanvasView() {
        canvas.backgroundColor = .clear
        canvas.drawingPolicy = .pencilOnly
        canvas.layer.shadowOffset = CGSize(width: 1, height: 2)
        canvas.layer.shadowRadius = 5
        canvas.layer.shadowOpacity = 0.33
        view.addSubview(canvas)
        view.sendSubviewToBack(canvas)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvas.topAnchor.constraint(equalTo: view.topAnchor),
            canvas.leftAnchor.constraint(equalTo: view.leftAnchor),
            canvas.rightAnchor.constraint(equalTo: view.rightAnchor),
            canvas.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupGestureRecognizers() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)
    }
    
    func skip(forward: Bool) {
        guard !Float(player.currentTime.seconds).isNaN else {
            return
        }
        let safeTime = Double(min(Int(player.asset?.duration.seconds ?? 0),
                                  max(0, Int(player.currentTime.seconds) + (forward ? 15 : -15))))
        player.seekToTime(to: CMTime(seconds: safeTime, preferredTimescale: playerTimeScale), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func updateButtons(for state: Player.PlaybackState) {
        playPauseButton.setImage(UIImage(systemName: state == .playing ? "pause" : "play.fill"), for: .normal)
    }
    
    @objc func handleTap() {
        if player.playbackState == .playing {
            player.pause()
        } else {
            player.playFromCurrentTime()
        }
    }
    
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        skip(forward: sender.location(in: view).x > (view.bounds.width / 2.0))
    }
    
    @IBAction func didTapAdd(_ sender: UIBarButtonItem) {
        presentImportOptions(sender: sender)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let time = (player.asset?.duration.seconds ?? 0.0) * Double(sender.value)
        let playerWasPlaying = player.playbackState == .playing
        player.pause()
        player.seekToTime(to: CMTime(seconds: time, preferredTimescale: playerTimeScale), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            if playerWasPlaying {
                DispatchQueue.main.async {
                    self?.player.playFromCurrentTime()
                }
            }
        }
    }
    
    @IBAction func didTapAspectRatio(_ sender: UIBarButtonItem) {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.player.fillMode = self.player.fillMode == .resizeAspect ? .resizeAspectFill : .resizeAspect
        }, completion: nil)
    }
    
    @IBAction func didTapPencil(_ sender: UIBarButtonItem) {
        if toolPicker.isVisible {
            toolPicker.setVisible(false, forFirstResponder: canvas)
            toolPicker.removeObserver(canvas)
            canvas.resignFirstResponder()
        } else {
            toolPicker.setVisible(true, forFirstResponder: canvas)
            toolPicker.addObserver(canvas)
            canvas.becomeFirstResponder()
        }
    }
    
    @IBAction func didTapClear(_ sender: UIBarButtonItem) {
        canvas.drawing = PKDrawing()
    }
    
}

extension ViewController: PlayerDelegate {
    
    func playerReady(_ player: Player) {
        if let endTime = player.asset?.duration {
            endTimeLabel.text = "/ \(endTime.positionalTime)"
        }
    }
    
    func playerPlaybackStateDidChange(_ player: Player) { }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        presentAlert(message: error?.localizedDescription ?? "Something went wrong.")
    }
    
    func playerBufferingStateDidChange(_ player: Player) { }
    func playerBufferTimeDidChange(_ bufferTime: Double) { }
    
}

extension ViewController: PlayerPlaybackDelegate {
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) { }
    
    func playerPlaybackDidEnd(_ player: Player) { }
    
    func playerCurrentTimeDidChange(_ player: Player) {
        guard !slider.isFirstResponder else { return }
        slider.value = Float(player.currentTime.seconds / (player.asset?.duration.seconds ?? player.currentTime.seconds))
        currentTimeLabel.text = player.currentTime.positionalTime
    }
    
    func playerPlaybackWillLoop(_ player: Player) { }
    func playerPlaybackDidLoop(_ player: Player) { }
    
}

extension ViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        player.url?.stopAccessingSecurityScopedResource()
        if let url = urls.first,
           url.startAccessingSecurityScopedResource() {
            player.url = url
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let nsurl = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL,
           let url = nsurl.absoluteURL {
            DispatchQueue.main.async { [weak self] in
                self?.player.url = url
                picker.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
