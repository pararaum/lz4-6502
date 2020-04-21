;LZ4 data decompressor for Apple II
;Peter Ferrie (peter.ferrie@gmail.com)
;assemble using ACME
;dst<src
!cpu 65c02
!to "lz4",plain
*=$800

init	=	0 ;set to 1 if you know the values
hiunp	=	0 ;unpacker entirely in high memory
hipak	=	0 ;packed data entirely in high memory (requires hiunp)
!if init {
  oep		=	$1234 ;first unpacked byte to run, you must set this by yourself
  orgoff	=	$1234 ;offset of first unpacked byte, you must set this by yourself
  paksize	=	$1234 ;size of packed data, you must set this by yourself if hiunp=0
}
!if hiunp {
  hioff		=	$d000 ;address of unpacker in high memory, you can change this but leave room for packed data if hipak=1
  !if hipak {
    !if (init=0) {
      paksize	=	$1234 ;size of packed data, you must set this by yourself if hiunp=1
    }
  }
} else {
  !if (init=0) {
    paksize	=	$1234 ;size of packed data, you must set this by yourself if hiunp=1
  }
}


;unpacker variables, no need to change these
src	=	$0
dst	=	$2
end	=	$4
count	=	$6
delta	=	$8
A1L	=	$3c
A1H	=	$3d
A2L	=	$3e
A2H	=	$3f
A4L	=	$42
A4H	=	$43
LCBANK2	=	$c083
MOVE	=	$fe2c

!if init {
	lda	#<pakoff ;packed data offset
	sta	src
	lda	#<(pakoff+paksize) ;packed data size
	sta	end
	lda	#>pakoff
	sta	src+1
	lda	#>(pakoff+paksize)
	sta	end+1
	lda	#>orgoff ;original unpacked data offset
	sta	dst+1
  !if (>(oep-1)=>orgoff) { ;oep = original entrypoint
	pha
  } else {
	lda	#>(oep-1)
	pha
  }
	lda	#<orgoff
	sta	dst
  !if (<(oep-1)=<orgoff) {
	pha
  } else {
	lda	#<(oep-1)
	pha
  }
}

unpack ;unpacker entrypoint
!if hiunp {
	ldy	#0
	lda	#>parsetoken
	sta	A1H
	lda	#<parsetoken
	sta	A1L
  !if hipak {
	lda	#>pakoff+paksize ;packed data offset + packed data size
	sta	A2H
	lda	#<pakoff+paksize
	sta	A2L
  } else {
	lda	#>pakoff
	sta	A2H
	lda	#<pakoff
	sta	A2L
  }
	lda	#>hioff
	sta	A4H
	lda	#<hioff
	sta	A4L
	jsr	MOVE
	lda	LCBANK2
	jmp	hioff
} else {
	jmp	parsetoken

pakoff
	;place packed data here for low memory unpacking
*=pakoff+paksize
}

;!pseudopc hioff { ;uncomment if hiunp
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
	cmp	end
	lda	src+1
	sbc	end+1
	bcs	done

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
	iny
+	lda	src+1
	pha
	lda	src
	pha
	sec
	lda	dst
	sbc	delta
	sta	src
	lda	dst+1
	sbc	delta+1
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
	dey
	bne	docopy
	rts

buildcount
!if hiunp {
	iny
} else {
	ldy	#1
}
	cmp	#$0f
	bne	++
-	sta	count
	jsr	getsrc
	tax
	clc
	adc	count
	bcc	+
	iny
+	inx
	beq	-
++	rts

getput
	jsr	getsrc

putdst
	sta 	(dst)
	inc	dst
	bne	+
	inc	dst+1
+	rts

getsrc
	lda 	(src)
	inc	src
	bne	+
	inc	src+1
+	rts

!if hiunp {
pakoff
	;place packed data here for high memory unpacking
}
;} ;uncomment if hiunp
