;LZ4 data decompressor for Apple II
;Peter Ferrie (peter.ferrie@gmail.com)
;assemble using ACME
;src<dst
!cpu 6502
!to "lz4",plain
*=$800

init	=	0 ;set to 1 if you know the values
!if init {
  oep		=	$1234 ;first unpacked byte to run, you must set this by yourself
  orgoff	=	$1234 ;offset of first unpacked byte, you must set this by yourself
  orgsize	=	$1234 ;size of unpacked data, you must set this by yourself
  paksize	=	$1234 ;size of packed data, you must set this by yourself
}

;unpacker variables, no need to change these
src	=	$0
dst	=	$2
count	=	$4
delta	=	$6
tmpy	=	$8

!if init {
	lda	#>pakoff+paksize ;packed data offset + packed data size
	sta	src+1
	lda	#<pakoff+paksize
	sta	src
	lda	#>orgoff+orgsize ;original unpacked data offset + original unpacked size
	sta	dst+1
  !if (>(oep-1)=>(orgoff+orgsize)) { ;oep = original entrypoint
	pha
  } else {
	lda	#>(oep-1)
	pha
  }
	lda	#<orgoff+orgsize
	sta	dst
	lda	#<(oep-1)
	pha
}

unpack ;unpacker entrypoint
	ldy	#0

parsetoken
	jsr	getsrc
	pha
	lsr
	lsr
	lsr
	lsr
	beq	copymatches
	jsr	buildcount
	tax
	jsr	docopy
	lda	src
	cmp	#<(pakoff+1)
	lda	src+1
	sbc	#>(pakoff+1)
	bcc	done

copymatches
	jsr	getsrc
	sta	delta
	jsr	getsrc
	sta	delta+1
	pla
	and	#$0f
	jsr	buildcount
	clc
	adc	#4
	tax
	bcc	+
	inc	count+1
+	lda	src+1
	pha
	lda	src
	pha
	clc
	lda	dst
	adc	delta
	sta	src
	lda	dst+1
	adc	delta+1
	sta	src+1
	jsr	docopy
	pla
	sta	src
	pla
	sta	src+1
	jmp	parsetoken

done
	pla
	rts

docopy
	jsr	getput
	dex
	bne	docopy
	dec	count+1
	bne	docopy
	rts

buildcount
	ldx	#1
	stx	count+1
	cmp	#$0f
	bne	++
-	sta	count
	jsr	getsrc
	tax
	clc
	adc	count
	bcc	+
	inc	count+1
+	inx
	beq	-
++	rts

getput
	jsr	getsrc

putdst
	cpy	dst
	bne	+
	dec	dst+1
+	dec	dst
	sta	(dst), y
	rts

getsrc
	lda	src
	bne	+
	dec	src+1
+	dec	src
	lda	(src), y
	rts

pakoff
	;place packed data here
