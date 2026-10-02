//
//  CaptureSnapshot.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 8/7/25.
//

import UIKit

/// Transient state representing the result of the last capture, held until the user accepts or discards it.
public enum CaptureSnapshot {
    /// Photo capture (any filter mode). `croppedData` contains the cropped JPEG when in card mode; `metadata` is empty for plain photos.
    case photo(preview: UIImage, raw: Photo, croppedData: Data?, metadata: [CaptureMetadata])
    /// Video recording.
    case video(url: URL)

    /// The preview image when the snapshot is a photo capture.
    public var preview: UIImage? {
        if case .photo(let preview, _, _, _) = self { preview } else { nil }
    }

    /// The raw photo data when the snapshot is a photo capture.
    public var photo: Photo? {
        if case .photo(_, let raw, _, _) = self { raw } else { nil }
    }

    /// The cropped image data when the snapshot is a card-mode capture; `nil` otherwise.
    public var croppedData: Data? {
        if case .photo(_, _, let croppedData, _) = self { croppedData } else { nil }
    }

    /// The video URL when the snapshot is a video capture.
    public var videoURL: URL? {
        if case .video(let url) = self { url } else { nil }
    }

    /// Capture metadata (features, text, etc.) — empty for plain photos and videos.
    public var metadata: [CaptureMetadata] {
        if case .photo(_, _, _, let metadata) = self { metadata } else { [] }
    }
}
