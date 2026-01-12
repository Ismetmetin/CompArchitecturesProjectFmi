masm 
model small
.data
input_handle dw 0; s tova shte dostupvam input file-a 
inputfilename db 'prjInput.txt', 0 ;v sushtata direktoriq
input_buffer db 201 dup (0); 201 terminirashti nuli za da moje ako spre rano da ne se znaimavam da slagam
point_input_buffer dd input_buffer
point_inpfname dd inputfilename
strlen dw 0
output_handle dw 0;
outputfilename db 'crypt.txt',0
point_outpfname dd outputfilename
err_over db 'Encryption limit reached! Cannot encrypt more!$'
err_under db 'Cannot decrypt anymore! That is your text!$'

.stack 256

.code 
 main: 
		mov ax, @data
		mov ds, ax
		mov es, ax
		
		;otvarqne na file-a
		mov al, 0h
		lds dx, point_inpfname
		mov ah, 3dh ;3dh e koda za otvarqne na file
		int 21h ;sled interupta v ax se zapazva handle-a na input.
		mov input_handle, ax ; zapazvam go na mqsto koeto znam
		
		;chetene ot file
		mov ah, 3fh ;tova e koda za chetene of handle-a v bx
		mov bx, input_handle
		mov cx, 200 ;kolko byte-a da prochete of file-a
		lds dx, point_input_buffer ;pointer kum bufer (obvi)
		int 21h
		
		;sled prochitane ako vsichko e tochno v ax se zapzva broq procheteni bytove
		
		jc bad
		cmp ax, 0h ;validacii che vs e tochno i ne sme stignali kraq na file-a
		je bad 
		
		push 0h
		
		mov strlen, ax
		mov cx, strlen ;tolkova trqbva da printiram
		lea si, input_buffer
		printSymbol:		
		lodsb ; sega al = tekushtiq simvol i si++
		mov dl, al ; loadvam tekushtiq simvol ot niza
		mov ah, 02h ;printiram simvol
		int 21h
		
		loop printSymbol
		;ako stigna do tuk vsichko trqbva da e tochno 
		
		mov dl, 0dh;cariage return
		mov ah, 02h
		int 21h
		mov dl, 0ah;cursor down one line
		int 21h
		
		jmp prompt
		
		jmp exit
	bad:
		;kogato stane neshto losho
		mov ah, 02h
		mov dl, 'n'
		int 21h
		
		mov dl, 'a'
		int 21h
		
		jmp exit
	
	save:
		; suzdavam 
		xor cx,cx
		lds dx, point_outpfname
		mov ah, 3ch
		int 21h
		
		mov al, 02h
		lds dx, point_outpfname
		mov ah, 3dh
		int 21h
		mov output_handle, ax
		
		mov bx, output_handle
		mov cx, strlen
		lds dx, point_input_buffer
		mov ah,40h
		int 21h
		jc bad
		
		mov ah, 3eh
		mov bx, output_handle
		int 21h
		
		jmp	prompt
		
	prompt:
		mov ah, 01h
		int 21h ;1 za kriptirane 2 za dekriptirane
		cmp al, '1'
		je crypt
		
		cmp al, '3';prompt za zapisvane vuv file
		je save
		
		cmp al, '2' ;exit
		jne exit
		
	
		jmp  decrypt ;prompt za decryptirane
		
		exit:	
		mov ah, 3eh
		mov bx, input_handle ;zatvarqm file-a
		int 21h
		
		mov	ax,4c00h	
		int	21h
		
	crypt:
		mov dl, 0dh;cariage return
		mov ah, 02h
		int 21h
		mov dl, 0ah;cursor down one line
		int 21h
		pop ax
		
		cmp ax, 0h
		je crypt1
		
		cmp ax, 01h
		je crypt2
		
		cmp ax, 02h
		je crypt3
		
		jmp tooMuch
		
	crypt1:
		;chetesh string element
		push 01h

		mov cx, strlen ;tolkova trqbva da obrabotq
		
		lea si, input_buffer
		lea di, input_buffer
		meth1:		
		lodsb ; sega al = tekushtiq simvol i si++
		not al ;bitflip
		stosb ; zapis
		loop meth1
		
		mov cx, strlen
		lea si, input_buffer
		jmp printSymbol
		
	crypt2:
		push 02h
		
		mov cx, strlen
		
		lea si, input_buffer
		lea di, input_buffer
		meth2:		
		lodsb 
		add al, 42h		;kum ascii koda my dobavqm 0x42
		stosb ; zapis
		loop meth2
		
		mov cx, strlen
		lea si, input_buffer
		jmp printSymbol
		
	crypt3:
		push 03h
		mov cx, strlen ;tolkova trqbva da obrabotq
		lea si, input_buffer
		lea di, input_buffer
		meth3:	
			lodsb
			mov dl, al
			xor ax, ax
			mov al, dl
			mov bl, 02h
			div bl
			
			cmp al, 01h
			je odd1
			sub dl, 04h			
			zapis:
			mov al, dl
			stosb ; zapis
			loop meth3
			
			mov cx, strlen
			lea si, input_buffer
			jmp printSymbol
		
		
	odd1:
		add dl, 04h
		jmp zapis
		
	tooMuch:
		push 03h
		
		mov ah, 09h
		mov dx, offset err_over
		int 21h
		jmp prompt
		
	decrypt:
		mov dl, 0dh;cariage return
		mov ah, 02h
		int 21h
		mov dl, 0ah;cursor down one line
		int 21h
		
		pop ax		
		cmp ax, 0h
		je notCrypted
		
		cmp ax, 01h
		je decrypt1
		
		cmp ax, 02h
		je decrypt2
		
		jmp decrypt3
		
	notCrypted:
		push 0
		
		mov ah, 09h
		mov dx, offset err_under
		int 21h
		
		jmp prompt
	decrypt1:
		;chetesh string element
		push 0h
		
		mov cx, strlen ;tolkova trqbva da obrabotq
		lea si, input_buffer
		lea di, input_buffer		
		dmeth1:
		lodsb 
		not al ; da obratnata funkciq e sushtata
		stosb 
		loop dmeth1
		
		mov cx, strlen
		lea si, input_buffer
		jmp printSymbol
	
	decrypt2:
		push 01h
		
		mov cx, strlen
		
		lea si, input_buffer
		lea di, input_buffer
		dmeth2:		
		lodsb 
		sub al, 42h
		stosb ; zapis
		loop dmeth2
		
		mov cx, strlen
		lea si, input_buffer
		jmp printSymbol
		
	decrypt3:
		push 02h
		mov cx, strlen ;tolkova trqbva da obrabotq
		lea si, input_buffer
		lea di, input_buffer
		dmeth3:	
			lodsb
			
			cmp al, 20h
			jb zapis2      
        ; ----------
			mov dl, al
			xor ax, ax
			mov al, dl
			mov bl, 02h
			div bl
			
			cmp al, 01h
			je odd2
			add dl, 04h			
			zapis2:
			mov al, dl
			stosb ; zapis
			loop dmeth3
			
			mov cx, strlen
			lea si, input_buffer
			jmp printSymbol
	
	
	odd2:
		sub dl, 04h
		jmp zapis2
	end main