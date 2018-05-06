pdm.run:
dutycycle.run:

rate := 44270

pdm.obx: waveform.bin

waveform.bin: Demovibes11.raw
	mv $< $@

%.raw: %.mp3
	sox -v 1.1 $< -e unsigned-integer -b 8 -r$(rate) -D -t raw $@ remix - trim 42 1

atari = altirra

%.run: %.xex
	$(atari) $<

%.xex: %.obx
	cp $< $@

%.obx: %.asm
	xasm /t:$*.lab /l:$*.lst $<
	perl -pi -e 's/^n /  /' $*.lab

.PRECIOUS: %.obx %.xex %.asm
