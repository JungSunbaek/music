import WidgetKit
import SwiftUI
import AppIntents
import UIKit

// Mp3 위젯용 Provider
struct Mp3Entry: TimelineEntry {
    let date: Date
    let fileName: String
}

struct Mp3Provider: TimelineProvider {
    func placeholder(in context: Context) -> Mp3Entry {
        Mp3Entry(date: Date(), fileName: "mp3 없음")
    }

    func getSnapshot(in context: Context, completion: @escaping (Mp3Entry) -> ()) {
        let entry = Mp3Entry(date: Date(), fileName: "mp3 없음")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Mp3Entry>) -> ()) {
        let entry = Mp3Entry(date: Date(), fileName: "mp3 없음")
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

struct weEntryView: View {
    var entry: Mp3Entry

    var body: some View {
        VStack {
            Text("파일명: \(entry.fileName)")
            // 여기에 위젯에 보여주고 싶은 UI 추가
        }
    }
}

struct we: Widget {
    let kind: String = "we"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Mp3Provider()) { entry in
            weEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MP3 위젯")
        .description("최근 mp3 파일을 표시합니다.")
    }
}
//
//  MusicWidget.swift
//  MusicWidget
//
//  Created by 정순백 on 6/30/25.
//

import WidgetKit
import SwiftUI

// MusicWidget 위젯용 Provider
struct MusicWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct MusicWidgetEntryView: View {
    var entry: MusicWidgetProvider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)
            Text("Favorite Emoji:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

//@main
struct MusicWidget: Widget {
    let kind: String = "MusicWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: MusicWidgetProvider()) { entry in
            MusicWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    MusicWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
//
//  MusicInfoWidget.swift
//  MusicInfoWidget
//
//  Created by 정순백 on 6/30/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// 음악 정보 Entry
struct MusicInfoEntry: TimelineEntry {
    let date: Date
    let albumCover: UIImage?
    let songTitle: String
    let artist: String
    let isPlaying: Bool
}

struct MusicInfoProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MusicInfoEntry {
        MusicInfoEntry(date: Date(), albumCover: nil, songTitle: "노래 제목", artist: "아티스트", isPlaying: false)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> MusicInfoEntry {
        loadEntry()
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<MusicInfoEntry> {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        return timeline
    }

    private func loadEntry() -> MusicInfoEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.jungsunbaek.music")
        let songTitle = sharedDefaults?.string(forKey: "nowPlayingTitle") ?? "노래 제목"
        let artist = sharedDefaults?.string(forKey: "nowPlayingArtist") ?? "아티스트"
        let isPlaying = sharedDefaults?.bool(forKey: "nowPlayingIsPlaying") ?? false

        var albumCover: UIImage? = nil
        if let imageData = sharedDefaults?.data(forKey: "nowPlayingArtwork") {
            albumCover = UIImage(data: imageData)
        }

        return MusicInfoEntry(date: Date(), albumCover: albumCover, songTitle: songTitle, artist: artist, isPlaying: isPlaying)
    }
}

// 위젯 뷰
struct MusicInfoWidgetEntryView : View {
    var entry: MusicInfoEntry

    var body: some View {
        VStack {
            if let image = entry.albumCover {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
            Text(entry.songTitle)
                .font(.headline)
                .lineLimit(1)
            Text(entry.artist)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            HStack(spacing: 32) {
                Button(intent: PreviousTrackIntent()) {
                    Image(systemName: "backward.fill")
                }
                Button(intent: PlayPauseIntent()) {
                    Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                }
                Button(intent: NextTrackIntent()) {
                    Image(systemName: "forward.fill")
                }
            }
            .font(.title2)
            .buttonStyle(.plain)
            
        }
    }
}

// dominantColor 확장 한 번만!
extension UIImage {
    func dominantColor() -> Color {
        guard let cgImage = self.cgImage else { return Color(red: 0.6, green: 0.07, blue: 0.09) }
        let width = 1, height = 1
        let bitmapData = calloc(width * height * 4, MemoryLayout<UInt8>.size)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let data = context?.data?.assumingMemoryBound(to: UInt8.self)
        let r = Double(data?[0] ?? 153) / 255.0
        let g = Double(data?[1] ?? 18) / 255.0
        let b = Double(data?[2] ?? 23) / 255.0
        free(bitmapData)
        return Color(red: r, green: g, blue: b)
    }
}

// 위젯 등록은 WidgetBundle에서 한 번만!
@main
struct MyWidgets: WidgetBundle {
    var body: some Widget {
        MusicInfoWidget()
    }
}

struct MusicInfoWidget: Widget {
    let kind: String = "MusicInfoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: MusicInfoProvider()) { entry in
            MusicInfoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("음악 위젯")
        .description("현재 재생 중인 곡 정보를 보여줍니다.")
    }
}
/*
// 예시: 앱에서 음악 정보 저장
let defaults = UserDefaults(suiteName: "group.com.jungsunbaek.music")
defaults?.set(songTitle, forKey: "songTitle")
defaults?.set(artist, forKey: "artist")
defaults?.set(isPlaying, forKey: "isPlaying")
// 앨범아트는 파일 경로나 Data로 저장

// 예시: 위젯 Provider에서 정보 읽기
let defaults = UserDefaults(suiteName: "group.com.jungsunbaek.music")
let songTitle = defaults?.string(forKey: "songTitle") ?? ""
let artist = defaults?.string(forKey: "artist") ?? ""
let isPlaying = defaults?.bool(forKey: "isPlaying") ?? false
// 앨범아트도 동일하게 불러오기
*/
