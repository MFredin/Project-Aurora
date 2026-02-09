import UIKit

/// Thread-safe image cache to avoid decoding cover images on every SwiftUI render
/// Uses NSCache for automatic memory pressure handling
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    func image(for key: UUID, data: Data?) -> UIImage? {
        let cacheKey = key.uuidString as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        guard let data, let image = UIImage(data: data) else {
            return nil
        }

        let cost = data.count
        cache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }

    func invalidate(for key: UUID) {
        cache.removeObject(forKey: key.uuidString as NSString)
    }

    func clearAll() {
        cache.removeAllObjects()
    }
}
