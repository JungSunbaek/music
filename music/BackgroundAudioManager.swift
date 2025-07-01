import AVFoundation
import Combine
import MediaPlayer
import WidgetKit
import SwiftUI

class BackgroundAudioManager: ObservableObject {
    static let shared = BackgroundAudioManager()
    @Published var isPlaying: Bool = false
    @Published var audioPlayer: AVAudioPlayer?
    private var playlist: [SongMeta] = []
    private var currentSong: SongMeta?

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("오디오 세션 설정 오류: \(error)")
        }
        setupRemoteCommandCenter()
    }

    func setPlaylist(_ songs: [SongMeta], current: SongMeta) {
        self.playlist = songs
        self.currentSong = current
    }

    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true

            // 곡 정보 추출
            let asset = AVAsset(url: url)
            var title = url.lastPathComponent
            var artist = ""
            var artwork: UIImage? = nil
            for meta in asset.commonMetadata {
                if meta.commonKey?.rawValue == "title", let value = meta.value as? String {
                    title = value
                }
                if meta.commonKey?.rawValue == "artist", let value = meta.value as? String {
                    artist = value
                }
                if meta.commonKey?.rawValue == "artwork", let data = meta.value as? Data, let image = UIImage(data: data) {
                    artwork = image
                }
            }
            updateNowPlayingInfo(
                title: title,
                artist: artist,
                artwork: artwork,
                duration: audioPlayer?.duration ?? 0,
                elapsed: audioPlayer?.currentTime ?? 0
            )
        } catch {
            print("오디오 재생 오류: \(error)")
            isPlaying = false
        }
    }

    func play() {
        audioPlayer?.play()
        isPlaying = true
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    func updateNowPlayingInfo(title: String, artist: String = "", artwork: UIImage? = nil, duration: Double = 0, elapsed: Double = 0) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        
        if let artwork = artwork, let data = artwork.pngData() {
            saveNowPlayingToAppGroup(title: title, artist: artist, artwork: data)
        } else {
            saveNowPlayingToAppGroup(title: title, artist: artist, artwork: nil)
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        // 슬라이더(구간 이동) 처리 추가
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.audioPlayer,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            player.currentTime = positionEvent.positionTime
            self.updateNowPlayingInfo(
                title: self.currentSong?.title ?? "",
                artist: self.currentSong?.artist ?? "",
                artwork: self.currentSong?.albumArt,
                duration: player.duration,
                elapsed: player.currentTime
            )
            return .success
        }
    }

    func playNext() {
        guard let current = currentSong,
              let idx = playlist.firstIndex(where: { $0.url == current.url }),
              idx < playlist.count - 1 else { return }
        let nextSong = playlist[idx + 1]
        currentSong = nextSong
        play(url: nextSong.url)
    }

    func playPrevious() {
        guard let current = currentSong,
              let idx = playlist.firstIndex(where: { $0.url == current.url }),
              idx > 0 else { return }
        let prevSong = playlist[idx - 1]
        currentSong = prevSong
        play(url: prevSong.url)
    }
    
    func saveNowPlayingToAppGroup(title: String, artist: String, artwork: Data?) {
        let defaults = UserDefaults(suiteName: "group.your.app.group") // App Group ID로 변경
        defaults?.setValue(title, forKey: "nowPlayingTitle")
        defaults?.setValue(artist, forKey: "nowPlayingArtist")
        defaults?.setValue(artwork, forKey: "nowPlayingArtwork")
        defaults?.synchronize()
    }
}

