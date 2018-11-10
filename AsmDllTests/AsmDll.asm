.686										;use .686 instruction set in the assembly
.XMM										;SSE extension will be used
.MODEL FLAT, STDCALL						;set flat memory model, calling convention shall be standard

OPTION CASEMAP:NONE							;case matters
INCLUDE C:/masm32/include/windows.inc		;necessary library

.CONST										;read only segment - constant
ExampleConst DWORD 145d						;edxamplary constant used in the procedure foo. value 145, decimal

XCharacter WORD 0058h						;UTF-16 encoding of the X character (two bytes).
GCharacter WORD 0047h						;UTF-16 encoding of the G character (two bytes).

.DATA										;Data segment, with variables

.CODE										;Code segment beginning

DllEntry PROC hInstDll:HINSTANCE, reason:DWORD, reserved1:DWORD

MOV EAX, TRUE
RET
DllEntry ENDP
;********************************
;*Testing procedure - for checking if library has been loaded correctly.
;********************************
foo PROC
	MOV EAX, ExampleConst
	INC EAX
	POP EDX
	PUSH EDX
	RET
foo ENDP

;********************************
;*Calculates needed length for the encrypted message.
;**Input:
;***message to encrypt length
;***key length
;*Output is the desired length of the message (int, DWORD).
;********************************
CalcNeededLength PROC msgLength:DWORD, keyLength:DWORD

	POP EDX
	PUSH EDX

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

;********************************
;*Entry encryption procedure. Called from the outside.
;**Input:
;***encoded in ADFGVX string with message 
;***string with key used in encryption
;***Length of the message to encrypt
;***Length of the key
;**The output is encrypted string
;*****
;*Note that the passed characters are in UTF-16
;********************************
EncryptMsg PROC	keyLength:DWORD, msgLength:DWORD, keyStr:DWORD, msgStr:DWORD					;Params loading from right to left (stdcall convention). keyStr and msgStr are 
																								;	pointers to chars array (16 bit chars, UTF-16 notation, little endian). 
	EncryptedMsg DW ?						;Variable pointer that will be pointing to the result message.
	
	RET																							;Return to the caller.

EncryptMsg ENDP
;********************************
END DllEntry

END

;Notki:
;-Zapis - little endian na wiêkszoœci procesorów x86 - st¹d zapis np. litery '¿' (dw 017Ch) w UTF16:
;		  db 7Ch, 01h