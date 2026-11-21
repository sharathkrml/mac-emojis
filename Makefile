APP := build/Build/Products/Debug/MacEmojis.app
DEST := platform=macOS,arch=arm64

.PHONY: run build test release archive generate clean

run: build
	-@pkill -x MacEmojis 2>/dev/null
	@sleep 1
	@open $(APP)

build: generate
	@xcodebuild -quiet -scheme MacEmojis -configuration Debug -derivedDataPath build -destination '$(DEST)' build

test: generate
	@xcodebuild -quiet -scheme MacEmojis -configuration Debug -derivedDataPath build -destination '$(DEST)' test

# ARCHS=arm64 is passed explicitly because Xcode otherwise builds the Emo
# package for x86_64 too, where its Core AI sources do not compile.
release: generate
	@xcodebuild -quiet -scheme MacEmojis -configuration Release -derivedDataPath build-release -destination '$(DEST)' ARCHS=arm64 build

archive: generate
	@xcodebuild -scheme MacEmojis -configuration Release -archivePath build/MacEmojis.xcarchive -destination '$(DEST)' ARCHS=arm64 archive

generate:
	@xcodegen generate

clean:
	rm -rf build
