.686										;use .686 instruction set in the assembly
.XMM										;SSE extension will be used
.MODEL FLAT, STDCALL						;set flat memory model, calling convention shall be standard

OPTION CASEMAP:NONE							;case matters
INCLUDE C:/masm32/include/windows.inc		;necessary library
INCLUDE \masm32\include\kernel32.inc
INCLUDELIB \masm32\lib\kernel32.lib

.CONST										;read only segment - constant
ExampleConst DWORD 145d						;edxamplary constant used in the procedure foo. value 145, decimal

heapAllocFlags DWORD HEAP_ZERO_MEMORY

XCharacter WORD 0058h						;UTF-16 encoding of the X character (two bytes).
GCharacter WORD 0047h						;UTF-16 encoding of the G character (two bytes).

.DATA										;Data segment, with variables

.CODE										;Code segment beginning

DllEntry PROC hInstDll:HINSTANCE, reason:DWORD, reserved1:DWORD

MOV EAX, TRUE
RET
DllEntry ENDP
;*****************************************************************
;*Testing procedure - for checking if library has been loaded correctly.
;******************************************************************
foo PROC
	MOV EAX, ExampleConst
	INC EAX
	POP EDX
	PUSH EDX
	RET
foo ENDP

;***************************************************************
;*Calculates needed length for the encrypted message.
;**Input:
;***message to encrypt length
;***key length
;*Output is the desired length of the message (int, DWORD) in EAX.
;***************************************************************
CalcNeededLength PROC msgLength:DWORD, keyLength:DWORD
	
	POP ECX												;Store return address
	POP msgLength										;Get the messageLength value from the stack and store it in msgLength
	POP keyLength										;Get the keyLength value from the stack and store it in keyLength
	PUSH ECX											;Put the return address back on the stack

	MOV EAX, msgLength									;Prepare the current message length for division.
	MOV EBX, keyLength									;Prepare the ky length for division.

	XOR EDX, EDX										;Division by 32 bit number - 64 bit divident is stored in EDX (higher 32 bits) and EAX (lower 32 bits). Since the value won't exceed 32 bits - set the EDX to 0x0h
	DIV EBX												;Divide the msgLength by keyLength - remainder of the division is needed and will be found in EDX.
											;EDX stores info about present characters in the last line. We need to know how many we need to add to the line, so we need to subtract
											;the rest of the division from the keyLength (if the rest is not equal to 0, that is).
	CMP EDX, 0										;Check if EDX has 0 in it (No characters needed to add).
	JZ CharsAmountEqualKeyLength					;If the remainder equals 0x0h - there's no need to add new characters. 
													;Otherwise:
	MOV EAX, keyLength									;Prepare the key length
	SUB EAX, EDX										;Subtract the remainder from the keyLength - receive the amount of characters to add.
	JMP ReturnNeededCharsAmount							;Jump in otder to return the calculated needed chars to add to the caller.
	
CharsAmountEqualKeyLength:					;There's dividable by the key length amount of characters in the mmessage. We can return it.
	MOV EAX, msgLength									;Prepare the length to return 
	RET													;Return to caller.

ReturnNeededCharsAmount:						;The result (additional amount of chars) has been calculated and loaded into EAX. Return it to the caller. (stdcall convention - single value returned in EAX).
	ADD EAX, msgLength							;Add the current length of the message to the result.
	RET											;Return the needed length.

CalcNeededLength ENDP
;********************************

;*****************************************************************
;*Lengthens the message string by adding needed characters (as X any G, amount is difference between desiredLength and sourceLength).
;*Copies the source and adds the two letters at the end.
;**Input (from left to right):
;***encoded in ADFGVX string with message 
;***Length of the source message
;***Desired length of the message
;**The output is pointer to new string of characters that is extended by proper amount of characters (allocated with HeapAlloc and GetProcessHeap - deallocate with HeapFree).
;***Document that describes the HeapFree, HeapAlloc and GetProcessHeap is in your laptop.
;**RESULT PASSED THROUGH STACK!
;*****
;*Note that the passed characters are in UTF-16
;*****************************************************************
LengthenString PROC sourceMsg:DWORD, sourceLength:DWORD, desiredLength:DWORD
	returnPtr DWORD ?									;Placeholder for return address.
	resultMsg DWORD ?									;Variable for storing the return address.

	POP returnPtr										;Store the return address
	POP sourceMsg										;Retreive first arg - the ptr to the source array of 16 bit chars (UTF-16)
	POP sourceLength									;Retrieve from the stack the length of the source array
	POP desiredLength									;Retrieve the thrird arg - desired length

	INVOKE GetProcessHeap								;Retrieve the address of the heap for the process. Address returned in EAX.
	MOV EBX, desiredLength								;Allocation of memory is made in bytes. We need words...
	ROL EBX, 1											;... so multiply the desired length by 2 (or rotate to the left by one bit, like in this case).
	INVOKE HeapAlloc, EAX, heapAllocFlags, EBX   ;Tries to allocate array on the process' heap of desired length.
	MOV resultMsg, EAX									;If allocation was successful - the pointer will be in EAX register. Store it.
														;Declaration of new array of WORDs (chars in UTF-16), length of desiredLength, no need to initialize
												;Copy data from source to new array
														;Prepare the counters for data copying
	MOV ESI, sourceMsg							;ESI shall iterate through the source.
	MOV EDI, resultMsg							;EDI iterates through the result (destination)
	MOV ECX, sourceLength								;Number of WORDs (characters) to copy
	CLD													;Clear direction flag so the iterators are increasing
	REP MOVSW											;Copy from source to destination ECX words (WORD by WORD).
												;Now, fill the rest of the resultMsg with X and G characters (round robin)
	wasG BYTE 1h										;Set a boolean to true - We start with X letter.
	MOV AX, XCharacter									;Prepare fast read for the X character
	MOV BX, GCharacter									;Prepare fast read for the G character 
												;ECX stores the rest of WORDs that need to be copied. When it reaches 0 - the resultMsg is full.
KeepAddingCharacters:							;Beginning of the loop that adds the remaining characters.
	CMP ECX, 0											;If the ECX reaches 0...
	JZ EndProcedure										;...End the procedure - there's nothing more to fill in the resultMsg.

		CMP wasG, 0h										;check if wasG is false
		JZ wasntG											;if it was - jump to wasntG to put an X in there

		MOV WORD PTR [EDI], BX								;Set the character in the array to X.
		MOV wasG, 0h										;A 'X' was just set - set the flag to FALSE.

		JMP decrementIter									;The char was set, now it is needed to decrement the counter in ECX.
	wasntG:													;Last put character was X.
		MOV WORD PTR [EDI], AX								;Put a letter G in the array.
		MOV wasG, 1h										;A 'G' was just set in the array. Set the flag to TRUE.

decrementIter:									;Another 16 bit char was set in the array...
	DEC ECX												;... so decrease the counter.
	ADD EDI, 2h											;Set the array pointer two bytes further.
	JMP KeepAddingCharacters							;Begin next iteration of the loop.

EndProcedure:									;End of lengthening the string. Time to return its address through the stack. And restore the return address, too.
	PUSH resultMsg
	PUSH returnPtr
	RET
LengthenString ENDP
;********************************

;*****************************************************************
;*Entry encryption procedure. Called from the outside.
;**Input:
;***encoded in ADFGVX string with message 
;***string with key used in encryption
;***Length of the message to encrypt
;***Length of the key
;**The output is encrypted string
;*****
;*Note that the passed characters are in UTF-16
;*****************************************************************
EncryptMsg PROC	keyLength:DWORD, msgLength:DWORD, keyStr:DWORD, msgStr:DWORD					;Params loading from right to left (stdcall convention). keyStr and msgStr are 
																								;	pointers to chars array (16 bit chars, UTF-16 notation, little endian). 
	desiredLength DWORD ?							;The length of encrypted message (with added characters, each char is a WORD)
	lengthenedMsg DWORD ?							;Pointer to the lengthened message (with eventually added X and G characters).
												;Prepare the lengths of the key and the message to be passed to the procedure
	PUSH keyLength								;Put the first argument (keyLength) on the stack
	PUSH msgLength								;Put the second argument (msgLength) on the stack
	CALL CalcNeededLength						;Call the procedure that calculates needed length, using passed above arguments.
	MOV desiredLength, EAX						;Put the result of the CalcNeededLength procedure in DesiredLength (value returned in EAX).

	PUSH desiredLength							;Put the needed arguments on the stack (from right to left).
	PUSH msgLength
	PUSH msgStr
	CALL LengthenString							;Retrieve the address of lengthened 16 bit array of chars through the stack...
	POP lengthenedMsg							;...and assign it to lengthenedMsg DWORD.



	EncryptedMsg DW ?						;Variable pointer that will be pointing to the result message.
	
	RET																							;Return to the caller.

EncryptMsg ENDP
;********************************
END DllEntry

END

;Notki:
;-Zapis - little endian na wi�kszo�ci procesor�w x86 - st�d zapis np. litery '�' (dw 017Ch) w UTF16:
;		  db 7Ch, 01h