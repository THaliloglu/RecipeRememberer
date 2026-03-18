import RealityKit
import SwiftData
import SwiftUI

struct RecipeScannerImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    @State private var subscriptions = [EventSubscription]()

    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content, _ in
                if content.entities.isEmpty {
                    for entry in SampleRecipeCatalog.entries {
                        guard let referenceCardURL = Bundle.main.url(
                            forResource: entry.referenceImageName,
                            withExtension: "png",
                            subdirectory: "ReferenceCards"
                        ) else {
                            continue
                        }

                        let anchor = AnchorEntity(
                            .referenceImage(
                                from: .init(
                                    referenceCardURL,
                                    physicalSize: [
                                        Float(entry.cardWidthMeters),
                                        Float(entry.cardHeightMeters),
                                    ]
                                )
                            )
                        )

                        anchor.name = entry.id
                        content.add(anchor)
                    }
                }

                if subscriptions.isEmpty {
                    subscriptions.append(
                        content.subscribe(to: SceneEvents.AnchoredStateChanged.self) { event in
                            guard
                                event.isAnchored,
                                let anchorEntity = event.anchor as? Entity,
                                let entry = SampleRecipeCatalog.entries.first(where: { $0.id == anchorEntity.name })
                            else {
                                return
                            }

                            appModel.handleTrackedRecipe(entry, using: modelContext)
                        }
                    )
                }
            } update: { content, attachments in
                for entry in SampleRecipeCatalog.entries {
                    guard
                        let anchor = content.entities.first(where: { $0.name == entry.id }),
                        anchor.isAnchored,
                        let attachmentEntity = attachments.entity(for: entry.id),
                        attachmentEntity.parent == nil
                    else {
                        continue
                    }

                    anchor.addChild(attachmentEntity)
                    attachmentEntity.setPosition([0, 0.12, 0], relativeTo: anchor)
                }
            } attachments: {
                ForEach(SampleRecipeCatalog.entries) { entry in
                    Attachment(id: entry.id) {
                        RecipeCardLabelView(entry: entry)
                    }
                }
            }

            Text("Look at a printed HelloFresh recipe card to recognize it. Cards in the sample reference set will show live save status above the paper.")
                .padding()
                .glassBackgroundEffect()
                .padding(.bottom, 32)
        }
        .onAppear {
            appModel.isImmersiveSpaceShown = true
        }
        .onDisappear {
            appModel.isImmersiveSpaceShown = false
        }
    }
}
