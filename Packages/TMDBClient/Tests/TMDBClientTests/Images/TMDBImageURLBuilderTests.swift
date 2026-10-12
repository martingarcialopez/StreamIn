import Testing
import Foundation
import Domain
@testable import TMDBClient

@Suite struct TMDBImageURLBuilderTests {
    private let builder = TMDBImageURLBuilder()

    @Test(arguments: [
        (ImageSize.poster, "w342"),
        (ImageSize.backdrop, "w780"),
        (ImageSize.providerLogo, "w92")
    ])
    func sizeMapsToTMDBSegment(size: ImageSize, segment: String) {
        let url = builder.url(for: ImagePath("/abc123.jpg"), size: size)
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/\(segment)/abc123.jpg")
    }

    @Test func customBaseURLIsUsedAsGiven() {
        let builder = TMDBImageURLBuilder(baseURL: "https://cdn.example.com/img/")
        let url = builder.url(for: ImagePath("/abc123.jpg"), size: .poster)
        #expect(url?.absoluteString == "https://cdn.example.com/img/w342/abc123.jpg")
    }

    @Test(arguments: [ImageSize.poster, .backdrop, .providerLogo])
    func resultHasNoDoubleSlash(size: ImageSize) throws {
        let url = try #require(builder.url(for: ImagePath("/abc123.jpg"), size: size))
        let withoutScheme = url.absoluteString.replacing("https://", with: "")
        #expect(!withoutScheme.contains("//"))
    }

    @Test func fileNameIsPreserved() throws {
        let url = try #require(builder.url(for: ImagePath("/aB_c-12.3_x.jpg"), size: .backdrop))
        #expect(url.lastPathComponent == "aB_c-12.3_x.jpg")
    }
}
