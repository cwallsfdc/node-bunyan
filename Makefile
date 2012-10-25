
#---- Tools

TAP := ./node_modules/.bin/tap


#---- Files

JSSTYLE_FILES := $(shell find lib test tools examples -name "*.js") bin/bunyan



#---- Targets

all:

# Ensure all version-carrying files have the same version.
.PHONY: versioncheck
versioncheck:
	[[ `cat package.json | json version` == `grep '^## ' CHANGES.md | head -1 | awk '{print $$3}'` ]]
	[[ `cat package.json | json version` == `grep '^var VERSION' bin/bunyan | awk -F'"' '{print $$2}'` ]]
	[[ `cat package.json | json version` == `grep '^var VERSION' lib/bunyan.js | awk -F"'" '{print $$2}'` ]]
	@echo Version check ok.

.PHONY: cutarelease
cutarelease: versioncheck
	[[ `git status | tail -n1` == "nothing to commit (working directory clean)" ]]
	./tools/cutarelease.py -p bunyan -f package.json -f lib/bunyan.js -f bin/bunyan

.PHONY: docs
docs:
	@[[ `which ronn` ]] || (echo "No 'ronn' on your PATH. Install with 'gem install ronn'" && exit 2)
	mkdir -p man/man1
	ronn --style=toc --manual="bunyan manual" --date=$(shell git log -1 --pretty=format:%cd --date=short) --roff --html docs/bunyan.1.ronn
	python -c 'import sys; h = open("docs/bunyan.1.html").read(); h = h.replace(".mp dt.flush {float:left;width:8ex}", ""); open("docs/bunyan.1.html", "w").write(h)'
	python -c 'import sys; h = open("docs/bunyan.1.html").read(); h = h.replace("</body>", """<a href="https://github.com/trentm/node-bunyan"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png" alt="Fork me on GitHub"></a></body>"""); open("docs/bunyan.1.html", "w").write(h)'
	@echo "# test with 'man ./docs/bunyan.1' and 'open ./docs/bunyan.1.html'"

.PHONY: publish
publish:
	mkdir -p tmp
	[[ -d tmp/bunyan-gh-pages ]] || git clone git@github.com:trentm/node-bunyan.git tmp/bunyan-gh-pages
	cd tmp/bunyan-gh-pages && git checkout gh-pages && git pull --rebase origin gh-pages
	cp docs/index.html tmp/bunyan-gh-pages/index.html
	cp docs/bunyan.1.html tmp/bunyan-gh-pages/bunyan.1.html
	(cd tmp/bunyan-gh-pages \
		&& git commit -a -m "publish latest docs" \
		&& git push origin gh-pages || true)

#---- test

.PHONY: test
test: $(TAP)
	TAP=1 $(TAP) test/*.test.js

# Test will all node supported versions (presumes install locations I use on my machine).
.PHONY: testall
testall: test08 test06 test09

.PHONY: test09
test09:
	@echo "# Test node 0.9.x (with node `$(HOME)/opt/node-0.9/bin/node --version`)"
	PATH="$(HOME)/opt/node-0.9/bin:$(PATH)" TAP=1 $(TAP) test/*.test.js
.PHONY: test08
test08:
	@echo "# Test node 0.8.x (with node `$(HOME)/opt/node-0.8/bin/node --version`)"
	PATH="$(HOME)/opt/node-0.8/bin:$(PATH)" TAP=1 $(TAP) test/*.test.js
.PHONY: test06
test06:
	@echo "# Test node 0.6.x (with node `$(HOME)/opt/node-0.6/bin/node --version`)"
	PATH="$(HOME)/opt/node-0.6/bin:$(PATH)" TAP=1 $(TAP) test/*.test.js



#---- check

.PHONY: check-jsstyle
check-jsstyle: $(JSSTYLE_FILES)
	./tools/jsstyle -o indent=2,doxygen,unparenthesized-return=0,blank-after-start-comment=0,leading-right-paren-ok $(JSSTYLE_FILES)

.PHONY: check
check: check-jsstyle
	@echo "Check ok."

.PHONY: prepush
prepush: check testall
	@echo "Okay to push."
