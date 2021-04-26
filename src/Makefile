.PHONY: all

all: build

build:	*.asm
	 zmac -P --oo lst,hex,cim ff1_gbr_main.asm

clean:
	rm zout/*
