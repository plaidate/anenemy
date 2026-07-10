# AnEnemy - sea-anemone territorial duel for Playdate.
#
#   make          release build   -> out/AnEnemy.pdx
#   make smoke    instrumented    -> out/AnEnemySmoke.pdx
#
# Staging copies source/* into build/<variant>/source and writes the generated
# smokeflag.lua (pdc wants a single source root).

OUT := out

all: release

release: build/release/source
	pdc build/release/source $(OUT)/AnEnemy.pdx

smoke: build/smoke/source
	pdc build/smoke/source $(OUT)/AnEnemySmoke.pdx

build/release/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = false' > $@/smokeflag.lua

build/smoke/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = true' > $@/smokeflag.lua
	echo 'SHOT_PATH = "$(CURDIR)/build/anenemy-shot.png"' >> $@/smokeflag.lua

clean:
	rm -rf build $(OUT)

.PHONY: all release smoke clean
