ram1088.run:

thecart.playcart:

calibrate.run:

pdm.run:
dutycycle.run:

rate := 44270

pdm.obx: waveform.bin

thecart.car: bank0.bin waveform.bin makecart.pl
	./makecart.pl $^ $(out)

ram1088.xex: ram.xex waveform.bin makecart.pl
	./makecart.pl -ram $^ $(out)

#waveform.bin: Demovibes11.raw
waveform.bin: elek.raw
	cp $< $@

	# -D -- don't dither
%.raw: %.mp3
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -D -t raw $@ remix - trim 565.75 600
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -D -t raw $@ remix - trim 1 240
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -t raw $@ remix - trim 0 300
	sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -D -t raw $@ remix - trim 0 300
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -D -t raw $@ remix - trim 1 40
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -t raw $@ remix - trim 1 240 dither -f lipshitz -S -s
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -t raw $@ remix - trim 1 240 dither -s
	#sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -t raw $@ remix - trim 0 600 dither -s
%.wav: %.mp3
	sox -v 1.5 $< -e unsigned-integer -b 8 -r$(rate) -D -t wav $@ remix - trim 0 600

out = > $@~ && mv $@~ $@

atari = altirra

%.run: %.xex
	$(atari) $<

%.playcart: %.car
	$(atari) $<

%.bin: %.obx
	cp $< $@

%.xex: %.obx
	cp $< $@

%.obx: %.asm
	xasm /t:$*.lab /l:$*.lst $<
	perl -pi -e 's/^n /  /' $*.lab

%.asm.pl: %.asm.pp
	echo 'sub interp {($$_=$$_[0])=~s/<<<(.*?)>>>/eval $$1/ge;print}' > $@
	perl -pe 's/^\s*>>>// or s/(.*)/interp <<'\''EOF'\'';\n$$1\nEOF/;' $< >> $@

%.asm: %.asm.pl
	perl $< $(out)

.PRECIOUS: %.obx %.xex %.asm
