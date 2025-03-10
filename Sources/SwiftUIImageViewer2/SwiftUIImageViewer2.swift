import SwiftUI
import Kingfisher

public struct SwiftUIImageViewer2: View {
    private let imageContent: AnyView

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero

     public init(image: Image) {
        self.imageContent = AnyView(
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }

    public init(uiImage: UIImage?) { // UIImage? 타입으로 변경
        if let uiImage = uiImage { // uiImage가 nil이 아닌 경우
            self.imageContent = AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            )
        } else { // uiImage가 nil인 경우 빈 이미지를 표시
            self.imageContent = AnyView(
                Image(systemName: "photo") // 혹은 다른 빈 이미지를 사용할 수 있습니다.
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            )
        }
    }

    public init(imageURL: URL) {
        self.imageContent = AnyView(
            KFImage(imageURL)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }

    public init(imageURLString: String) {
        self.imageContent = AnyView(
            KFImage(URL(string: imageURLString))
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }

     public var body: some View {
        GeometryReader { proxy in
            ZStack {
                imageContent
                    .scaleEffect(scale)
                    .offset(x: offset.x, y: offset.y)
                    .gesture(makeDragGesture(size: proxy.size))
                    .gesture(makeMagnificationGesture(size: proxy.size))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
    }

    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }

    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }

    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}
