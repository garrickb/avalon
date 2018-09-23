PORT := 8000

MAIN := src/Main.elm
ELM_FILES := $(shell find src -name "*.elm")
JS_OUTPUT := public/bundle.js


build: $(ELM_FILES)
	elm make $(MAIN) --debug --warn --output $(JS_OUTPUT)

serve: build
	cd public && python -m SimpleHTTPServer $(PORT)

develop: build
	fswatch -0 src/* | xargs -0 -n1 -I '{}' make &
	cd public && python -m http.server $(PORT)

clean:
	rm $(JS_OUTPUT)
