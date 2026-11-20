APP := build/Build/Products/Debug/MacEmojis.app
DEST := platform=macOS,arch=arm64

.PHONY: run build test generate clean

run: build
	-@pkill -x MacEmojis 2>/dev/null
	@sleep 1
	@open $(APP)

build: generate
	@xcodebuild -quiet -scheme MacEmojis -configuration Debug -derivedDataPath build -destination '$(DEST)' build

test: generate
	@xcodebuild -quiet -scheme MacEmojis -configuration Debug -derivedDataPath build -destination '$(DEST)' test

generate:
	@xcodegen generate

clean:
	rm -rf build
