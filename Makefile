DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
PROJECT = Dozer.xcodeproj
SCHEME = Dozer
CONFIGURATION = Debug

setup:
	@brew bundle --no-upgrade
	@mkdir -p Dozer/Other/Generated
	@swiftgen
	@xcodegen

build: setup
	@xed "."

run: setup
	@DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination "platform=macOS" build
	@APP_PATH="$$(DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -showBuildSettings | awk -F ' = ' '/ TARGET_BUILD_DIR / { dir=$$2 } / WRAPPER_NAME / { name=$$2 } END { print dir "/" name }')"; \
	open "$$APP_PATH"

release:
	@echo "Running Fastlane deploy"
	@bundle exec fastlane release

.PHONY: setup build run release
