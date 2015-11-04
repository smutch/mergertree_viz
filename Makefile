serve: build
	python3 -m http.server 8000

build: graph.scss
	sass graph.scss graph.css
