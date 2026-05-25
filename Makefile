.PHONY: project build test e2e score scaffold clean help baseline editor-bundle install-editor-deps dist release

help:
	@echo "MD Editor — make targets"
	@echo "  make project              Generate MDEditor.xcodeproj from project.yml (requires xcodegen)"
	@echo "  make install-editor-deps  npm install in Editor/web/"
	@echo "  make editor-bundle        Build the CodeMirror 6 bundle (esbuild)"
	@echo "  make build                Build Debug configuration (depends on editor-bundle)"
	@echo "  make test                 Run unit tests"
	@echo "  make score                Run scripts/score.sh; report current build-readiness metrics"
	@echo "  make baseline             Run scripts/measure-markedit-baseline.sh; write baselines.json"
	@echo "  make clean                Remove build artifacts"

project:
	xcodegen generate

install-editor-deps:
	cd Editor/web && npm install

editor-bundle: install-editor-deps
	mkdir -p build/editor
	cd Editor/web && npm run build
	cp Editor/web/src/editor.html build/editor/editor.html

build: project editor-bundle
	xcodebuild -project MDEditor.xcodeproj -scheme MDEditor -configuration Debug -derivedDataPath build build
	# Build the CLI helper as a separate target so it can live non-sandboxed in Helpers/.
	xcodebuild -project MDEditor.xcodeproj -scheme mdedit -configuration Debug -derivedDataPath build build
	# Copy the CM6 bundle into the .app's Resources so Bundle.main.url(forResource:) finds it.
	mkdir -p build/Build/Products/Debug/MDEditor.app/Contents/Resources
	cp -f build/editor/editor.html build/editor/editor.js build/Build/Products/Debug/MDEditor.app/Contents/Resources/ 2>/dev/null || true
	# Install the CLI helper into the .app bundle so RELEASING.md's claim
	# "MDEditor.app/Contents/Helpers/mdedit" is actually true.
	mkdir -p build/Build/Products/Debug/MDEditor.app/Contents/Helpers
	cp -f build/Build/Products/Debug/mdedit build/Build/Products/Debug/MDEditor.app/Contents/Helpers/mdedit 2>/dev/null || true

test: project
	xcodebuild -project MDEditor.xcodeproj -scheme MDEditor -configuration Debug -derivedDataPath build build-for-testing
	xcrun xctest build/Build/Products/Debug/MDEditorTests.xctest

## USE-level scenarios per docs/e2e-test-plan.md.
## Drives the app via XCUITest + Accessibility; asserts on the DOM state
## that App/E2EBridge.swift exposes when --e2e=1 is passed.
e2e: project editor-bundle
	xcodebuild test -project MDEditor.xcodeproj -scheme MDEditor \
	  -configuration Debug -derivedDataPath build \
	  -only-testing:MDEditorE2ETests \
	  -resultBundlePath build/e2e-result.xcresult \
	  | xcbeautify || true
	@echo "Result bundle: build/e2e-result.xcresult"

score:
	@./scripts/score.sh

baseline:
	@./scripts/measure-markedit-baseline.sh

## Distributable Debug bundle — produces dist/MDEditor.app + zip for drag-to-Applications.
## Doesn't notarize (that's `release`); intended for quick share + first-run testing.
dist: build
	rm -rf dist && mkdir -p dist
	cp -R build/Build/Products/Debug/MDEditor.app dist/
	# Remove any inherited quarantine so a tester can launch without xattr dance.
	xattr -dr com.apple.quarantine dist/MDEditor.app 2>/dev/null || true
	cd dist && /usr/bin/zip -qry MDEditor-debug.zip MDEditor.app
	@du -sh dist/MDEditor.app | awk '{print "App bundle: " $$1}'
	@ls -la dist/MDEditor-debug.zip | awk '{print "Zip: " $$5 " bytes"}'
	@echo "Drag dist/MDEditor.app to /Applications, or share dist/MDEditor-debug.zip."

## Release pipeline — Release config + sign + notarize (via audire/Membrain-pattern
## notarize.sh) + dmg + appcast.
## Required env: MDEDIT_APPLE_ID (e.g. you@example.com).
## Optional env: MDEDIT_TEAM_ID (defaults to LY8G872X5U — same as audire/Membrain).
## Prerequisite: ./scripts/setup-release.sh (one-time keychain profile + Sparkle keys).
## If MDEDIT_APPLE_ID is unset, skips notarization and produces an unsigned bundle.
release: project editor-bundle
	xcodebuild -project MDEditor.xcodeproj -scheme MDEditor -configuration Release -derivedDataPath build build
	xcodebuild -project MDEditor.xcodeproj -scheme mdedit -configuration Release -derivedDataPath build build
	mkdir -p build/Build/Products/Release/MDEditor.app/Contents/Resources \
	          build/Build/Products/Release/MDEditor.app/Contents/Helpers
	cp -f build/editor/editor.html build/editor/editor.js build/Build/Products/Release/MDEditor.app/Contents/Resources/
	cp -f build/Build/Products/Release/mdedit build/Build/Products/Release/MDEditor.app/Contents/Helpers/mdedit
	@if [ -n "$$MDEDIT_APPLE_ID" ]; then \
	    ./scripts/notarize.sh build/Build/Products/Release/MDEditor.app "$$MDEDIT_APPLE_ID" "$${MDEDIT_TEAM_ID:-LY8G872X5U}" && \
	    ./scripts/build-dmg.sh && \
	    ./scripts/generate-appcast.sh; \
	  else \
	    echo "Skipping sign/notarize: set MDEDIT_APPLE_ID=you@example.com to enable."; \
	    ./scripts/build-dmg.sh || true; \
	  fi

clean:
	rm -rf build dist MDEditor.xcodeproj Editor/web/node_modules
