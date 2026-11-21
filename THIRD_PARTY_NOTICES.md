# Third-party notices

MacEmojis itself is licensed under the MIT License (see [LICENSE](LICENSE)). It depends on the following third-party work.

## Emo — Desert Ant Labs

- **Project:** <https://desertant.com/models/emo/>
- **SDK:** <https://github.com/Desert-Ant-Labs/desert-ant-core>
- **License:** [Desert Ant Labs Source-Available License, Version 1.0](https://license.desertant.com/1.0)
- **SPDX:** `LicenseRef-DAL-Source-Available-1.0`
- **Copyright:** © 2026 Desert Ant Labs B.V.

The license is free below **100,000 monthly active devices per platform, for each model**. Above that, a commercial license is required. You may embed the models in your application, but you may not use them, their outputs, or their logs to train a competing on-device model. Credit Desert Ant Labs in your app. Using the SDK means accepting the full terms at the link above.

Required attribution:

> **Powered by [Desert Ant Labs](https://desertant.com/) 🐜**

The Emo model files are downloaded at runtime from Hugging Face and are not redistributed in this repository.

The SDK's own third-party notices are at <https://github.com/Desert-Ant-Labs/desert-ant-core/blob/main/THIRD_PARTY_NOTICES.md>.

## swift-numerics

- **Project:** <https://github.com/apple/swift-numerics>
- **License:** Apache License 2.0 with Runtime Library Exception
- **Used by:** Emo's `RealModule`

## Apple frameworks

SwiftUI, AppKit, Core ML, and the Accessibility API are part of macOS. They are not redistributed with this repository.

## Binary distribution

If you distribute a compiled app, include the full license texts for every dependency you ship. The links above point at the authoritative copies.
