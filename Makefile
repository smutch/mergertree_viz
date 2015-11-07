serve: build
	python3 -m http.server 8000

refresh: build
	sh chrome_refresh.sh

build: graph.coffee graph.scss
	coffee -c graph.coffee
	sass graph.scss graph.css
