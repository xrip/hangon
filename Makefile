PYTHON ?= python3

.PHONY: all verify clean

all: verify

verify:
	$(PYTHON) build.py

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"
