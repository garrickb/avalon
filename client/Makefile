ELM_FILES := $(shell find src -name "*.eml")
ELM_MAIN := src/Main.elm

PORT := 8000

public/bundle.js: $(ELM_FILES)
	elm make $(ELM_MAIN) --debug --warn --output public/bundle.js

serve:
	cd public && python -m SimpleHTTPServer $(PORT)

develop:
	fswatch -0 src/* | xargs -0 -n1 -I '{}' make &
	cd public && python -m http.server ${PORT}
