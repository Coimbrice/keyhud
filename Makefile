QMLLINT ?= qmllint-qt6

.PHONY: test lint

test:
	node --test tests/*.test.mjs

lint:
	$(QMLLINT) *.qml
