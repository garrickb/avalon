PORT := 8000

MAIN := src/Main.elm
ELM_FILES := $(shell find src -name "*.elm")
JS_OUTPUT := public/bundle.js

build-dev: $(ELM_FILES)
	elm make --yes $(MAIN) --debug --output $(JS_OUTPUT)

build: $(ELM_FILES)
	elm make --yes $(MAIN) --output $(JS_OUTPUT)

build-dev: $(ELM_FILES)
	elm make --yes $(MAIN) --debug --output $(JS_OUTPUT)

serve: build
	cd public && python -m http.server $(PORT)

develop: build-dev
	fswatch -0 src/* | xargs -0 -n1 -I '{}' make build-dev &
	cd public && python -m SimpleHTTPServer $(PORT)

clean:
	rm $(JS_OUTPUT)
