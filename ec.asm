#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#


; All variables given memory
porta equ 00h
portb equ 02h
portc equ 04h

; All the sensors :  fs# indicates fine sensor for floor #
					;cs#_[1/2] indicates course sensor on floor # with 1 indicating accelerating when
					;going up and 2 indicates decelerating when going down.
	;SENSORS
	fs0 equ 0200h
	cs0_1 equ 0201h
	cs1_1 equ 0202h
	fs1 equ 0203h
	cs1_2 equ 0204h
	cs2_1 equ 0205h
	fs2 equ 0206h
	cs2_2 equ 0207h
	fs3 equ 0208h
	cs3_2 equ 0209h

	; FLOOR BUTTONS
	up0 equ 020ah
	up1 equ 020bh
	down1 equ 020ch
	up2 equ 020dh
	down2 equ 020eh
	down3 equ 020fh

	; Lift buttons
	f0 equ 0210h
	f1 equ 0211h
	f2 equ 0212h
	f3 equ 0213h
	dc equ 0214h

	dir equ 0215h ; 1 means ___ and 0 means ___
	stop equ 0216h 
	closed equ 0217h
	decel equ 0218h
	accel equ 0219h
	cfloor equ 021ah ; current floor
	nfloor equ 021bh ; next floor
	min_speed equ 021ch

	;8253 addresses
	cnt0	equ	08h
	cnt1	equ	0ah
	cnt2	equ	0ch
	cr_8253	equ	0eh
	
	;8259 addresses
	master1  equ 10h
	master2  equ 12h
	slave1_1 equ 18h
	slave1_2 equ 1ah
	slave2_1 equ 20h
	slave2_2 equ 22h

; startup
         jmp     st1 
         db     509 dup(0)

;IVT entry for 80H
         
         dw     m0
         dw     0000
		 dw     m1
         dw     0000
         dw     m2
         dw     0000
		 dw     m3
         dw     0000
		 dw     m4
         dw     0000
		 dw     m5
         dw     0000
		 dw     m6
         dw     0000
		 dw     m7
         dw     0000
		 dw     s1_0
         dw     0000
		 dw     s1_1
         dw     0000
		 dw     s1_2
         dw     0000
		 dw     s1_3
         dw     0000
		 dw     s1_4
         dw     0000
		 dw     s1_5
         dw     0000
		 dw     s1_6
         dw     0000
		 dw     s1_7
         dw     0000
		 dw     s2_0
         dw     0000
		 dw     s2_1
         dw     0000
		 dw     s2_2
         dw     0000
		 dw     s2_3
         dw     0000
		 dw     s2_4
         dw     0000
		 dw     s2_5
         dw     0000
		 dw     s2_6
         dw     0000
		 dw     s2_7
         dw     0000
		 db     416 dup(0)
;main program
          
st1:      cli ;clear interrupt flag

; initialize ds,es,ss to start of RAM
          mov       ax,0200h
          mov       ds,ax ;data segment starts at 200H
          mov       es,ax
          mov       ss,ax
          mov       sp,0FFFEH
		  
; initialize porta, portb & portc as output
		  ; Control register for 8255
          mov       al,10000000b  ;0 as all are for output
		  out 		06h,al 

		

	

;initializing 8253

	;loading value to get 20% duty cycle at the start
	
	;initializing counter0 with 25000
	mov	al,00110110b  ; square wave generator with mode 3.
	out	cr_8253,al ; control register of 8253
	mov	al,0A8h ; LSB
	out	cnt0,al 
	mov	al,61h ; MSB
	out	cnt0,al 
	
	;initializing counter1 with 5 to get 20Hz
	mov	al,01110110b
	out	cr_8253,al
	mov	al,05h
	out	cnt1,al
	mov	al,00h ;0005h
	out	cnt1,al
	
	;initializing counter2 with 8 in mode 1 ;20% duty initialized
	mov	al,10110010b
	out	cr_8253,al
	mov	al,20   ;04h for 20% , 2h for 60% , 03h for 40%
	out	cnt2,al
	mov	al,0 
	out	cnt2,al
		
;8259 initialize - vector no. 80h, edge triggered
;initialize master 8259	  
		  ;ICW1 on A0 = 0
		  mov       al,00010001b	;d3=0 -> edge triggered, d1=0 -> multiple 8259, d0=1 -> ic4 reqd
		  out       10h,al
		  ;ICW2 on A0 = 1, The vector number which 8259 will send to 8086 for IR0 (It will auto calculate for other IRs)
		  mov       al,80h
		  out       12h,al
		  ;ICW3 on A0 = 1, This is sent if we have used the cascade
		  mov       al, 11000000b 	;d7 and d6 are 1 as on IR7 and IR6, slave 8259s are connected
		  out       12h,al
		  ;ICW4 on A0 = 1
		  mov       al,00000011b	;d1=1 -> automatic end of interrupt, d0=1 -> processor is 8086
		  out       12h,al
		  ;OCW1 on A0=1, This is used to mask IR pins
		  mov       al,00h 		;No pins masked
		  out       12h,al
		  
		  
;initialize slave1 8259
		;ICW1
		  mov       al,00010001b 		;d3=0 -> edge triggered, d1=0 -> multiple 8259, d0=1 -> ic4 reqd
		  out       18h,al
		;ICW2, The vector number which 8259 will send to 8086 for IR0 (It will auto calculate for other IRs)
		  mov       al,88h
		  out       1ah,al
		;ICW3S  
		  mov       al,00000111b	;111 means that this slave is connected on IR7 of the master 8259
		  out       1ah,al
		;ICW4
		  mov       al,00000011b 	;d1=1 -> automatic end of interrupt, d0=1 -> processor is 8086
		  out       1ah,al
		;OCW1
		  mov       al,00h 	;No pins masked
		  out       1ah,al
		  

;initialize slave2 8259
		;ICW1
		  mov       al,00010001b	;d3=0 -> edge triggered, d1=0 -> multiple 8259, d0=1 -> ic4 reqd
		  out       20h,al
		;ICW2, The vector number which 8259 will send to 8086 for IR0 (It will auto calculate for other IRs) 
		  mov       al,90h
		  out       22h,al
		;ICW3S  
		  mov       al,00000110b 	;110 means that this slave is connected on IR6 of the master 8259
		  out       22h,al
		;ICW4
		  mov       al,03h 		;d1=1 -> automatic end of interrupt, d0=1 -> processor is 8086
		  out       22h,al
		;OCW1
		  mov       al,00h  ;No pins masked
		  out       22h,al
		  
		  sti ;set interrupt flag

x9:		mov si, 0200h
		mov cx, 0029 ;we have 28 variables
		
		mov al, 00h
x8:		
		mov ds:[si], al ;putting 0 on all outputs
		inc si
		loop x8
		mov al, 01h
		mov ds:[dir], al
		mov ds:[stop], al	
	
;loop till Interrupt service routine

		
		;display current floor and stop,dir,closed
x1:     mov al, ds:[cfloor]  ;all these set various pins on port c..... can be done using BSR mode
		out portb, al
		mov al,ds:[nfloor]
		out porta,al
		mov al,ds:[accel]
		ror al,1
		or al,ds:[decel]
		ror al,1
		or al, ds:[closed]
		ror al, 1
		or al, ds:[stop]
		ror al, 1
		or al, ds:[dir]
		ror al, 1
		out portc, al
		
		; resetting if no keys are pressed
		mov al,ds:[stop] 
		and al,ds:[closed]
		cmp al,01h
		jnz x2
		mov al, 00h
		or al, ds:[f0]
		or al, ds:[f1]
		or al, ds:[f2]
		or al, ds:[f3]
		or al, ds:[up0]
		or al, ds:[up1]
		or al, ds:[up2]
		or al, ds:[down1]
		or al, ds:[down2]
		or al, ds:[down3]
		cmp al, 00h
		jnz x2 ;if al was not 0 i.e any of the keys was pressed
		jmp x9 ;UP
		
		
x2:		mov al,ds:[dc]
		cmp al,01h
		jnz ndc
		mov al,00h
		mov ds:[stop],al
		mov ds:[dc],al
		mov al,01h
		mov ds:[closed],al
		
ndc:	;no door closed
		mov al,01
		cmp ds:[stop],al
		je nd_stop
		mov al,ds:[accel]
		cmp al,01h
		jnz	na
		mov	al,10010010b;;;;;10110010b
		out	cr_8253,al
		mov	cl,4 ;8
		
a4:		mov	al,cl
		out	cnt2,al ;pwm
		;mov	al,0
		;out	cnt2,al
		dec	cl
		cmp	cl,1;4
		jne	a4
		mov al,00h
		mov ds:[accel],al
na:
		mov al,ds:[min_speed]
		cmp al,01h
		jz nd
		mov al,ds:[decel]
		cmp al,01h
		jnz nd
		mov	al,10010010b;;;;;;;;;10110010b
		out	cr_8253,al
		mov	cl,2 ;5
		
a1:		mov	al,cl
		out	cnt2,al
		;mov	al,0
		;out	cnt2,al	
		inc	cl
		cmp	cl,5;9
		jne	a1
		mov al,01h
		mov ds:[min_speed],al
nd:		
		jmp       x1
nd_stop:	mov al,10010000b
		out cr_8253,al
		mov cl,0
		mov al,cl
		out cnt2,al
		jmp x1


m0: 		;Door close button   
		 mov al, 01h
		 mov ds:[dc], al
		 mov ds:[closed],al
		 mov ds:[accel],al
ibw:		 mov al,ds:[cfloor]
		 cmp al,00h
		 jz nx0
		 cmp al,01h
		 jz nx1
		 cmp al,02h
		 jz nx2
		 cmp al,03h
		 jz nx3
	nx0: mov al,ds:[f1]
		 or al,ds:[up1]
		 cmp al,01h
		 jz n1
		 mov al,ds:[f2]
		 or al,ds:[up2]
		 cmp al,01h
		 jz n2
		 mov al,ds:[f3]
		 or al,ds:[down3]
		 cmp al,01h
		 jz n3
		 mov al,ds:[down2]
		 cmp al,01h
		 jz n2
		 mov al,ds:[down1]
		 cmp al,01h
		 jz n1
	nx1: mov al,ds:[dir]
		 cmp al,01h
		 jz nx1u
		 mov al,ds:[f0]
		 or al,ds:[up0]
		 cmp al,01h
		 jz n0
	nx1u:mov al,ds:[f2]
		 or al,ds:[up2]
		 cmp al,01h
		 jz n2
		 mov al,ds:[f3]
		 or al,ds:[down3]
		 cmp al,01h
		 jz n3
		 mov al,ds:[down2]
		 cmp al,01h
		 jz n2
	nx2: mov al,ds:[dir]
		 cmp al,01h
		 jz nx2u
		 mov al,ds:[f1]
		 or al,ds:[down1]
		 cmp al,01h
		 jz n1
		 mov al,ds:[f0]
		 or al,ds:[up0]
		 cmp al,01h
		 jz n0
		 mov al,ds:[up1]
		 cmp al,01h
		 jz n1
	nx2u:mov al,ds:[f3]
		 or al,ds:[down3]
		 cmp al,01h
		 jz n3
	nx3: mov al,ds:[f2]
		 or al,ds:[down2]
		 cmp al,01h
		 jz n2
		 mov al,ds:[f1]
		 or al,ds:[down1]
		 cmp al,01h
		 jz n1
		 mov al,ds:[f0]
		 or al,ds:[up0]
		 cmp al,01h
		 jz n0
		 mov al,ds:[up1]
		 cmp al,01h
		 jz n1
		 mov al,ds:[up2]
		 cmp al,01h
		 jz n2
		 
	n0:	 mov al,00h
		 jmp as
	n1:	 mov al,01h
		 jmp as
	n2:	 mov al,02h
		 jmp as
	n3:	 mov al,03h
	as:	mov ds:[nfloor],al	 
		 
          iret
          
m1:		;Floor 0 (inside lift)
		mov al, 01h
		mov ds:[f0], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret
		
m2:
		iret
		
m3:		;Floor 3 (inside lift)
		mov al, 01h
		mov ds:[f3], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret

m4:		;Floor 2 (inside lift)
		mov al, 01h
		mov ds:[f2], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret
		
m5:		;Floor 1 (inside lift)
		mov al, 01h
		mov ds:[f1], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret

m6:	;
		iret

m7:	;
		iret
		
s1_0:	; CS0_1
		

		mov al, 01h
		mov ds:[cs0_1], al
		mov al,ds:[f0]
		or al,ds:[up0]
		cmp al,01
		jnz nd0
		; mov al,ds:[cs0_1]
		; mov ah,ds:[dir] ;0 then moving
		; not ah
		; and ah,01h
		; and al,ah
		; cmp al,01h
		; jnz nd0
		; 	;for debugging purposes
		; mov al,6
		; mov ds:[nfloor],al
		; iret
		mov al,01h
		mov ds:[decel],al
		mov al,00h
		mov ds:[min_speed],al
		mov ds:[cs0_1],al
nd0:	mov al,00h
		mov ds:[accel],al
        iret

s1_1:	; FS_0
		mov al, 01h
		mov ds:[fs0], al
		mov al, ds:[fs0]
		cmp al,01h
		jnz nf0
		mov al,00h
		mov ds:[cfloor],al
		mov al,00h
		mov ds:[fs0],al
		mov al,ds:[nfloor]
		cmp ds:[cfloor],al
		jnz nf0
		mov al,01h
		mov ds:[stop],al
		mov al,00h
		mov ds:[decel],al
		mov ds:[closed],al
		mov ds:[f0],al
		mov ds:[up0],al
		mov al,01h
		mov ds:[dir],al
	nf0:
        iret

s1_2:	; Down 3
		mov al, 01h
		mov ds:[down3], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret

s1_3:	; Down 2
		mov al, 01h
		mov ds:[down2], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret

s1_4:	; Down 1
		mov al, 01h
		mov ds:[down1], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret

s1_5:	; Up 2
		mov al, 01h
		mov ds:[up2], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret

s1_6:	; Up 1
		mov al, 01h
		mov ds:[up1], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret
		
s1_7:	; Up 0
		mov al, 01h
		mov ds:[up0], al
		mov al,ds:[closed]
		cmp al,01h
		jz ibw
		iret
	
s2_0:	; FS 3
		mov al, 01h
		mov ds:[fs3], al
		mov al, ds:[fs3]
		cmp al,01h
		jnz nf3
		mov al,03h
		mov ds:[cfloor],al
		mov al,00h
		mov ds:[f3],al
		mov al,ds:[nfloor]
		cmp ds:[cfloor],al
		jnz nf3
		mov al,01h
		mov ds:[stop],al
		mov al,00h
		mov ds:[decel],al
		mov ds:[closed],al
		mov ds:[down3],al
		mov ds:[dir],al
		mov ds:[fs3],al
nf3:
        iret
	
s2_1:	; CS3_2
		mov al, 01h
		mov ds:[cs3_2], al
		; mov al,ds:[cs3_2]
		; and al,ds:[dir]
		; cmp al,01h
		
		mov al,ds:[nfloor]
		cmp al,03h

		jnz nd3
		mov al,01h
		mov ds:[decel],al
		mov al,00h
		mov ds:[min_speed],al
		mov ds:[cs3_2],al
nd3:	mov al,00h
		mov ds:[accel],al
        iret
	
s2_2:   ; CS2_1
		mov al, 01h
		mov ds:[cs2_1], al
		; mov ah,ds:[f2]
		; or ah,ds:[down2]
		; and ah,ds:[cs2_1];;useless
		; mov bl,ds:[dir]
		; not bl
		; and bl,01h
		; and ah,bl
		; cmp ah,01h
		
		mov al,ds:[nfloor]
		cmp al,02h

		jnz nd2
		mov al,00h
		mov ds:[cs2_1],al
		mov al,01h
		mov ds:[decel],al
		mov al,0
		mov ds:[min_speed],al
nd2:;when going up
		mov al,ds:[up2]
		cmp al,01h
		jnz nc2_2
		
		mov al,ds:[dir]
		cmp al,00h
		jnz nc2_2
		mov al,ds:[up1]
		or al,ds:[down1]
		or al,ds:[f1]
		or al,ds:[f0]
		or al,ds:[up0]
		cmp al,00h
		jnz nc2_2
		mov al,01h
		mov ds:[dir],al
		mov al,01h
		mov ds:[decel],al
		
	nc2_2:
		mov al,00h
		mov ds:[min_speed],al
		mov ds:[accel],al
        iret
	
s2_3:	; FS 2
		mov al, 01h
		mov ds:[fs2], al
		mov al, ds:[fs2]
		cmp al,01h
		jnz nf2
		mov al,02h
		mov ds:[cfloor],al
		mov al,00h
		mov ds:[fs2],al
		mov al,ds:[nfloor]
		cmp ds:[cfloor],al
		jnz nf2
		mov al,01h
		mov ds:[stop],al
		mov al,00h
		mov ds:[decel],al
		mov ds:[closed],al
		mov ds:[f2],al
		mov al,ds:[dir]
		cmp al,01h
		jnz nf2_1
		mov al,00h
		mov ds:[up2],al
		jmp nf3
	nf2_1: 
			mov al,00h
			mov ds:[down2],al
	nf2:
			iret
	
s2_4:	; CS2_2
		mov al, 01h
		mov ds:[cs2_2], al
		; mov al,ds:[f2]
		; or al,ds:[up2]
		; and al,ds:[cs2_2]
		; and al,ds:[dir]
		; cmp al,01h
			mov al,ds:[nfloor]
			cmp al,02h
		jnz nd2_1
		mov al,00h
		mov ds:[cs2_2],al
		mov al,01h
		mov ds:[decel],al
		mov al,0
		mov ds:[min_speed],al
	
	nd2_1:
		mov al,ds:[down2]
		cmp al,01h
		jnz nc2_1		
		mov al,ds:[dir]
		cmp al,01h
		jnz nc2_1
		mov al,ds:[down3]
		or al,ds:[f3]
		cmp al,00h
		jnz nc2_1
		mov al,00h
		mov ds:[dir],al
		mov al,01h
		mov ds:[decel],al
		
	nc2_1:
		mov al,00h
		mov ds:[min_speed],al
		mov ds:[accel],al
        iret
	
s2_5:	; CS1_1
		mov al, 01h
		mov ds:[cs1_1], al
		; mov al,ds:[f1]
		; or al,ds:[down1]
		; and al,ds:[cs1_1]
		; mov ah,ds:[dir]
		; not ah
		; and ah,01h
		; and al,ah
		mov al,ds:[nfloor]
		cmp al,01h
		jnz nd1
		mov al,00h
		mov ds:[cs1_1],al
		mov al,01h
		mov ds:[decel],al
		mov al,0
		mov ds:[min_speed],al
nd1:
		mov al,ds:[up1]
		cmp al,01h
		jnz nc1_2
		
		mov al,ds:[dir]
		cmp al,00h
		jnz nc1_2
		mov al,ds:[up0]
		or al,ds:[f0]
		cmp al,00h
		jnz nc1_2
		mov al,01h
		mov ds:[dir],al
		mov al,01h
		mov ds:[decel],al
		
	nc1_2:
		mov al,00h
		mov ds:[min_speed],al
		mov ds:[accel],al
        iret

s2_6: 	; FS 1
		
		mov al, 01h
		mov ds:[fs1], al
		mov al, ds:[fs1]
		cmp al,01h
		jnz nf1
		mov al,01h
		mov ds:[cfloor],al
		mov al,00h
		mov ds:[fs1],al
		mov al,ds:[nfloor]
		cmp ds:[cfloor],al
		jnz nf1
		mov al,01h
		mov ds:[stop],al
		mov al,00h
		mov ds:[decel],al
		mov ds:[closed],al
		mov ds:[f1],al
		mov al,ds:[dir]
		cmp al,01h
		jnz nf1_1
		mov al,00h
		mov ds:[up1],al
		jmp nf3
	nf1_1: 
		mov al,00h
		mov ds:[down1],al
	nf1:
		iret
		
s2_7:		;CS1_2
		mov al, 01h
		mov ds:[cs1_2], al
		; mov al,ds:[f1]
		; or al,ds:[up1]
		; and al,ds:[cs1_2]
		; and al,ds:[dir]
		; cmp al,01h

		mov al,ds:[nfloor]
		cmp al,01h

		jnz nd1_1
		mov al,00h
		mov ds:[cs1_2],al
		mov al,01h
		mov ds:[decel],al
		mov al,0
		mov ds:[min_speed],al
	nd1_1:
		mov al,ds:[down1]
		cmp al,01h
		jnz nc1_1
		mov al,ds:[dir]
		cmp al,01h
		jnz nc1_1
		mov al,ds:[up2]
		or al,ds:[down2]
		or al,ds:[f2]
		or al,ds:[f3]
		or al,ds:[down3]
		cmp al,00h
		jnz nc1_1
		mov al,00h
		mov ds:[dir],al
		mov al,01h
		mov ds:[decel],al

	nc1_1:
		mov al,00h
		mov ds:[min_speed],al
		mov ds:[accel],al
        iret
