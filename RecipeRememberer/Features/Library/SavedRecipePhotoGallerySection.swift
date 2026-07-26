import SwiftUI
import UIKit

struct SavedRecipePhotoGallerySection: View {
    let recipe: StoredRecipe

    @State private var selectedPhoto: SavedRecipePhotoAsset?

    var body: some View {
        VStack(spacing: 14) {
            ForEach(photos) { photo in
                SavedRecipePhotoCard(
                    photo: photo,
                    onPreview: {
                        selectedPhoto = photo
                    }
                )
            }
        }
        .padding(.vertical, 4)
        .fullScreenCover(item: $selectedPhoto) { photo in
            SavedRecipePhotoPreviewScreen(photo: photo)
        }
    }

    private var photos: [SavedRecipePhotoAsset] {
        var savedPhotos: [SavedRecipePhotoAsset] = []

        if let frontPhotoURL = RecipePhotoStore.url(for: recipe.frontPhotoFilename) {
            savedPhotos.append(
                SavedRecipePhotoAsset(
                    title: "Front",
                    photoURL: frontPhotoURL
                )
            )
        }

        if let backPhotoURL = RecipePhotoStore.url(for: recipe.backPhotoFilename) {
            savedPhotos.append(
                SavedRecipePhotoAsset(
                    title: "Back",
                    photoURL: backPhotoURL
                )
            )
        }

        return savedPhotos
    }
}

private struct SavedRecipePhotoCard: View {
    let photo: SavedRecipePhotoAsset
    let onPreview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(photo.title)
                .font(.headline)

            Button(action: onPreview) {
                SavedRecipePhotoThumbnail(photo: photo)
            }
            .buttonStyle(.plain)
            .contentShape(.rect(cornerRadius: 22))
            .accessibilityIdentifier("savedRecipe.preview.\(photo.accessibilitySuffix)")

            Text("Tap the photo to open it full screen.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            SavedRecipePhotoActionRow(photo: photo, onPreview: onPreview)
        }
        .padding(AppStyle.cardPadding)
        .background(.quaternary.opacity(0.24), in: .rect(cornerRadius: AppStyle.cardCornerRadius))
    }
}

private struct SavedRecipePhotoActionRow: View {
    let photo: SavedRecipePhotoAsset
    let onPreview: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SavedRecipePhotoActionLayout.actionButtonSpacing) {
                PreviewRecipePhotoButton(photo: photo, onPreview: onPreview)
                ShareRecipePhotoButton(photo: photo)
            }
            .frame(minWidth: SavedRecipePhotoActionLayout.minimumHorizontalRowWidth, maxWidth: .infinity)

            VStack(spacing: SavedRecipePhotoActionLayout.actionButtonSpacing) {
                PreviewRecipePhotoButton(photo: photo, onPreview: onPreview)
                ShareRecipePhotoButton(photo: photo)
            }
        }
    }
}

private struct PreviewRecipePhotoButton: View {
    let photo: SavedRecipePhotoAsset
    let onPreview: () -> Void

    var body: some View {
        Button(action: onPreview) {
            SavedRecipePhotoActionLabel(title: "Preview", systemImage: "arrow.up.left.and.arrow.down.right")
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, minHeight: SavedRecipePhotoActionLayout.minimumActionButtonHeight)
        .accessibilityIdentifier("savedRecipe.openPreview.\(photo.accessibilitySuffix)")
    }
}

private struct ShareRecipePhotoButton: View {
    let photo: SavedRecipePhotoAsset

    var body: some View {
        ShareLink(item: photo.photoURL) {
            SavedRecipePhotoActionLabel(title: "Share", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, minHeight: SavedRecipePhotoActionLayout.minimumActionButtonHeight)
        .accessibilityIdentifier("savedRecipe.share.\(photo.accessibilitySuffix)")
    }
}

private struct SavedRecipePhotoActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

private struct SavedRecipePhotoThumbnail: View {
    let photo: SavedRecipePhotoAsset

    var body: some View {
        if let uiImage = UIImage(contentsOfFile: photo.photoURL.path) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.08),
                        .black.opacity(0.58),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tap to preview")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)

                    Text("Open the saved photo in full screen.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 208)
            .background(.black.opacity(0.16))
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(.white.opacity(0.06))
            }
        } else {
            ContentUnavailableView(
                "Photo Unavailable",
                systemImage: "photo"
            )
            .frame(maxWidth: .infinity)
            .frame(height: 208)
            .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 22))
        }
    }
}

private struct SavedRecipePhotoPreviewScreen: View {
    @Environment(\.dismiss) private var dismiss

    let photo: SavedRecipePhotoAsset

    private var insideMarkerStatusLabel: String {
        UITestRecipeSeeder.hasUITestInsideMarker(in: photo.photoURL) ? "present" : "missing"
    }

    private var outsideMarkerStatusLabel: String {
        UITestRecipeSeeder.hasUITestOutsideMarker(in: photo.photoURL) ? "present" : "missing"
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                previewToolbar

                ZoomableSavedPhotoView(photo: photo)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Pinch to zoom and drag to inspect the saved recipe photo.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                if UITestLaunchConfiguration.shouldUseMockScannerCapture {
                    Text(insideMarkerStatusLabel)
                        .font(.footnote)
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("savedRecipe.insideMarker.\(photo.accessibilitySuffix)")

                    Text(outsideMarkerStatusLabel)
                        .font(.footnote)
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("savedRecipe.outsideMarker.\(photo.accessibilitySuffix)")
                }
            }
        }
    }

    private var previewToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Recipe Photo")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            ShareLink(item: photo.photoURL) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button("Done", action: dismiss.callAsFunction)
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.22))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

private struct ZoomableSavedPhotoView: View {
    let photo: SavedRecipePhotoAsset

    @State private var zoomScale = 1.0

    var body: some View {
        if let uiImage = UIImage(contentsOfFile: photo.photoURL.path) {
            ZStack(alignment: .bottomTrailing) {
                ZoomableRecipePhotoScrollView(
                    image: uiImage,
                    imageIdentifier: photo.id,
                    zoomScale: $zoomScale
                )
                .accessibilityIdentifier("savedRecipe.zoomablePhoto")

                Text("\(zoomScale.formatted(.number.precision(.fractionLength(1))))x")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.65), in: .capsule)
                    .padding(20)
                    .accessibilityIdentifier("savedRecipe.zoomScale")
            }
        } else {
            ContentUnavailableView(
                "Photo Unavailable",
                systemImage: "photo"
            )
            .foregroundStyle(.white, .secondary)
        }
    }
}

private struct ZoomableRecipePhotoScrollView: UIViewRepresentable {
    let image: UIImage
    let imageIdentifier: String
    @Binding var zoomScale: Double

    func makeUIView(context: Context) -> ZoomableImageContainerView {
        let view = ZoomableImageContainerView()
        view.onZoomScaleChange = { scale in
            zoomScale = scale
        }
        view.setImage(image, identifier: imageIdentifier)
        return view
    }

    func updateUIView(_ uiView: ZoomableImageContainerView, context: Context) {
        uiView.onZoomScaleChange = { scale in
            zoomScale = scale
        }
        uiView.setImage(image, identifier: imageIdentifier)
    }
}

private final class ZoomableImageContainerView: UIView, UIScrollViewDelegate {
    var onZoomScaleChange: ((Double) -> Void)?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var imageIdentifier: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds

        guard scrollView.zoomScale <= scrollView.minimumZoomScale + .ulpOfOne else {
            centerImage()
            return
        }

        updateImageFrame()
    }

    func setImage(_ image: UIImage, identifier: String) {
        guard imageIdentifier != identifier else {
            return
        }

        imageIdentifier = identifier
        imageView.image = image
        setNeedsLayout()
        layoutIfNeeded()
        resetZoom()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
        onZoomScaleChange?(scrollView.zoomScale)
    }

    private func configureView() {
        backgroundColor = .clear

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 6
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
    }

    private func resetZoom() {
        scrollView.zoomScale = 1
        updateImageFrame()
        onZoomScaleChange?(1)
    }

    private func updateImageFrame() {
        guard let image = imageView.image else {
            imageView.frame = bounds
            scrollView.contentSize = bounds.size
            return
        }

        let fittedSize = image.size.aspectFit(in: bounds.insetBy(dx: 12, dy: 12).size)
        imageView.frame = CGRect(origin: .zero, size: fittedSize)
        scrollView.contentSize = fittedSize
        centerImage()
    }

    private func centerImage() {
        let horizontalInset = max((bounds.width - scrollView.contentSize.width) / 2, 0)
        let verticalInset = max((bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
}

private struct SavedRecipePhotoAsset: Identifiable, Equatable {
    let title: String
    let photoURL: URL

    var id: String {
        photoURL.lastPathComponent
    }

    var accessibilitySuffix: String {
        title.lowercased()
    }
}

private extension CGSize {
    func aspectFit(in boundingSize: CGSize) -> CGSize {
        guard width > 0, height > 0, boundingSize.width > 0, boundingSize.height > 0 else {
            return boundingSize
        }

        let widthRatio = boundingSize.width / width
        let heightRatio = boundingSize.height / height
        let scale = min(widthRatio, heightRatio)

        return CGSize(width: width * scale, height: height * scale)
    }
}
