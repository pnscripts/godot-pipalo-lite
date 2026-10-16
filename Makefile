GODOT ?= godot
.PHONY: test buyer-check web-check

test:
	$(GODOT) --headless --path . --import >/dev/null 2>&1 || true
	$(GODOT) --headless --path . -s tests/run_tests.gd

# What the Godot Asset Library hands a buyer (git archive honours .gitattributes export-ignore),
# unpacked into a fresh project with the plugin enabled; then the test suite runs there.
buyer-check:
	GODOT=$(GODOT) tools/buyer_check.sh

# Web export of the demo in real Chrome with two-finger touch (needs PN_PLAYWRIGHT).
web-check:
	GODOT=$(GODOT) tools/web/web_check.sh
