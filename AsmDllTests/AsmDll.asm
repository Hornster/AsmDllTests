.686										;use .686 instruction set in the assembly
.MODEL FLAT, STDCALL						;set flat memory model, calling convention shall be standard
.XMM										;SSE extension will be used

OPTION CASEMAP:NONE							;case matters
INCLUDE D:/masm32/include/windows.inc		;necessary library
INCLUDE  D:\masm32\include\kernel32.inc
INCLUDELIB  D:\masm32\lib\kernel32.lib

.CONST										;read only segment - constant
ExampleConst DWORD 145d						;edxamplary constant used in the procedure foo. value 145, decimal

heapAllocFlags DWORD HEAP_ZERO_MEMORY

XCharacter WORD 0058h						;UTF-16 encoding of the X character (two bytes, the processor will save in little endian format).
GCharacter WORD 0047h						;UTF-16 encoding of the G character (two bytes, the processor will save in little endian format).

.DATA										;Data segment, with variables

.CODE										;Code segment beginning

DllEntry PROC hInstDll:HINSTANCE, reason:DWORD, reserved1:DWORD

MOV EAX, TRUE
RET
DllEntry ENDP
;*****************************************************************
;*Checks if passed amount of bytes is dividable by DWORD (by 4). If yes - returns 0h, otherwise returns non-zero value.
;*Uses EAX, EBX, EDX
;*Preserves EBX, EDX
;*Result returned in EAX
;******************************************************************
IsDividableByDWORD PROC bytesAmount:DWORD
	PUSH EBX										;Store values of registers used by the IsDividableByDWORD procedure.
	PUSH EDX										;^^

	XOR EDX, EDX										;Division by 32 bit number - 64 bit divident is stored in EDX (higher 32 bits) and EAX (lower 32 bits). Since the value won't exceed 32 bits - set the EDX to 0x0h
	MOV EAX, bytesAmount								;Prepare the amount of bytes to test.
	MOV EBX, 4h											;The amount of bytes will be divided by 4 - amount of bytes that make the DWORD.

	DIV EBX												;Perform division. If the amount of bytes fills perfectly in DWORDs - value in EDX will be 0h. Non-zero otherwise.

	MOV EAX, EDX									;Store the result.
	POP EDX											;Restore values of registers used by the IsDividableByDWORD procedure.
	POP EBX											;^^

	RET													;Return
IsDividableByDWORD ENDP

;***************************************************************
;*Calculates needed length for the encrypted message.
;**Input:
;***message to encrypt length
;***key length
;*Output is the desired length of the message (int, DWORD) in EAX.
;***************************************************************
CalcNeededLength PROC msgLength:DWORD, keyLength:DWORD

	MOV EAX, msgLength									;Prepare the current message length for division.
	MOV EBX, keyLength									;Prepare the key length for division.

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
;*****
;*Note that the passed characters are in UTF-16
;*****************************************************************
LengthenString PROC sourceMsg:PTR DWORD, sourceLength:DWORD, desiredLength:DWORD
				;;;;;;LOCALs are thrown on the stack
	LOCAL resultMsg : DWORD								;Variable for storing the return address.
	LOCAL wasG : DWORD									;Boolean that is used to check if a G letter was the last added letter. Used when the desired amount of characters and the current amount do not match.


	MOV EBX, desiredLength								;Allocation of memory is made in bytes. We need words...
	ROL EBX, 1											;... so multiply the desired length by 2 (or rotate to the left by one bit, like in this case).
														;Since an array is to be declared, the last character has to be \0. So, in case the needed amount of BYTEs is dividable by DWORD capacity - add one more BYTE.
	PUSH EBX											;Put the length to check on the stack...
	CALL IsDividableByDWORD								;...and check if the amount of required bytes is dividable by DWORD. Result on stack.

	CMP EAX, 0h											;Is the amount of bytes to declare dividable by DWORD?...
	JNZ NoNeedToAdd										;...If yes - add two bytes.
	ADD EBX, 2h											
						

NoNeedToAdd:											;...If not, simply jump here and proceed.
	INVOKE GetProcessHeap								;Retrieve the address of the heap for the process. Address returned in EAX.
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
	MOV ECX, desiredLength								;Put desired length in the ECX - this will be used to find out how many more letters need to be added
	SUB ECX, sourceLength								;Subtract the length of the source - result is the amount of letters that still have to be added

	MOV wasG, 1h										;We start with X letter.
	MOV AX, XCharacter									;Prepare fast read for the X character
	MOV BX, GCharacter									;Prepare fast read for the G character 
												;ECX stores the rest of WORDs that need to be copied. When it reaches 0 - the resultMsg is full.
KeepAddingCharacters:							;Beginning of the loop that adds the remaining characters.
	CMP ECX, 0											;If the ECX reaches 0...
	JZ EndProcedure										;...End the procedure - there's nothing more to fill in the resultMsg.

		CMP wasG, 0h										;check if wasG is false
		JZ wasntG											;if it was - jump to wasntG to put an X in there

		MOV WORD PTR [EDI], AX								;Set the character in the array to X.
		MOV wasG, 0h										;A 'X' was just set - set the flag to FALSE.

		JMP decrementIter									;The char was set, now it is needed to decrement the counter in ECX.
	wasntG:													;Last put character was X.
		MOV WORD PTR [EDI], BX								;Put a letter G in the array.
		MOV wasG, 1h										;A 'G' was just set in the array. Set the flag to TRUE.

decrementIter:									;Another 16 bit char was set in the array...
	DEC ECX												;... so decrease the counter.
	ADD EDI, 2h											;Set the array pointer two bytes further.
	JMP KeepAddingCharacters							;Begin next iteration of the loop.

EndProcedure:									;End of lengthening the string. Time to return its address through the stack. And restore the return address, too.
	POP EBX												;Get rid of the local values on the stack
	POP EBX												;^^^

	MOV EAX, resultMsg									;Move the pointer to result string to EAX
	
	RET
LengthenString ENDP
;********************************


;*****************************************************************
;*Sorts the two arrays. First argument (from right) is the source array which values will be sorted (from smaller to bigger).
;*Second argument (from right) is an array which will mimic all changes in the first one (in other words, changes will be sync with first one).
;*Passed key will become sorted, too (rising).
;**Input:
;***Address of the process' heap.
;***Length of the array to sort.
;***Pointer to array of WORDs that will be sorted.
;***Pointer to array of DWORDs that will be sorted accordingly to the first array (of WORDs).
;**Nothing is returned.
;*Used registers: EAX, EBX, ECX, EDX, ESI, EDI
;*Preserved registers: EAX, EBX, ECX, EDX, ESI, EDI
;*****************************************************************
SortFirstSecondMimics PROC  sortArrayPtr:DWORD, mimickingArrayPtr:DWORD, sortArrayLength:DWORD
	LOCAL smallest:DWORD					;Smallest index in current iteration of OuterLoop
	LOCAL smallestChar:WORD					;Currently smallest character
	LOCAL tempVal:WORD						;Variable used for character changing
	LOCAL tempPtr:DWORD						;Variable used for pointer exchanging

	PUSH EAX								;Store values in registers. At the end of the procedure, these will be restored.
	PUSH EBX								;^^
	PUSH ECX								;^^
	PUSH EDX								;^^
	PUSH ESI								;^^
	PUSH EDI								;^^

	MOV ESI, sortArrayPtr					;Prepare counters - sortArrayPtr
	MOV EDI, mimickingArrayPtr				;mimickingArrayPtr - the one that stores pointers to message arrays
										;Pointers that store current position in the table (by keyLength, that is, not dependent from size of single item)
	MOV ECX, 0h								;Pointer used to iterate in OuterLoop
	MOV EBX, 0h								;Counter for iteration in InnerLoop
	MOV EAX, sortArrayLength				;store the sortArrayLength for faster access
	SUB EAX, 1h								;Decrease the length by 1 - otherwise, the outer loop could stop too late, making the inner one reach too far (by one position behind the array).
											;Same operation happens right before comparison of the OuterLoop counter (ECX). For the InnerLoop, the EAX value is increased by 1.

OuterLoop:									;Iterates through the sortArray
	MOV smallest, ECX						;Put new index in the smallest index variable.
	MOV EBX, ECX							;With each new iteration the amount of items to check is decreased by 1. Sorted items are saved in the left part of the array.
	ADD EBX, 1h								;There's no need in comparing the same item with itself so skip to next one instantly.
	MOV DX, WORD PTR [ESI+ECX*2]			;Set the first unsorted character as smallest.
	MOV smallestChar, DX					;And save it in temporary location.
	ADD EAX, 1h								;Lastly, increase the range for the InnerLoop by 1 so it can reach the last element in the array. At the end of the OuterLoop, this shall be
											;decreased by 1 before comparison with ECX (OuterLoop counter).

	InnerLoop:
		MOV DX, WORD PTR [ESI+EBX*2]		;Put the value pointed at by ESI+EBX*2 in DX since cannot perform memory-memory comparsion. 
		CMP DX, smallestChar	;WORD PTR [ESI+ECX*2]		;Compare currently iterated values - ESI+EBX is currently seen, ESI+ECX is currently checked against. Times 2 since both are of WORD type.
		JGE Continue						;If the ESI+EBX is greater or equal ESI+ECX - ignore the item and continue.
		MOV smallest, EBX					;At the end, store the smallest index value.
		MOV smallestChar, DX				;Store the new smallest character, too.

	Continue:							;Continue iteration
		ADD EBX, 1h							;Increase the iterator
		CMP EBX, EAX						;Check if the counter for InnerLoop reached the end of the array.
		JNZ InnerLoop						;If the counter did not reach the end - jump back to the InnerLoop.
	EndInnerLoop:

	PUSH EAX								;Temporarily store the value of the EAX on the stack - one free register is needed
											;since memory-memory passes ar a big no-no.
	ROL ECX, 1								;multiply ECX by 2 (switching of 16bit chars is about to happen)
	ROL smallest, 1							;Multiply smallest by 2 (switching of 16bit chars is about to happen)
										;Prepare the first register - pointer values
	PINSRD XMM0, ESI, 0						;Load the ESI (pointer to sortArrayPtr) to bottom 64bit half, two times
	PINSRD XMM0, ESI, 1						;^^
	PINSRD XMM0, EDI, 2						;Load the EDI (pointer to mimickingArrayPtr) to upper 64bit half, two times
	PINSRD XMM0, EDI, 3						;^^
									;Prepare second register - values to add
	PINSRD XMM1, ECX, 0						;ECX value to add to the base register (sortArrayPtr).
	PINSRD XMM1, smallest, 1					;Value in smallest to add to the base register (sortArrayPtr).
										;Switch from WORDs to DWORDs
	ROL ECX, 1								;multiply ECX by 2 (switching of 32bit pointers is about to happen)
	ROL smallest, 1							;Multiply smallest by 2 (switching of 32bit pointers is about to happen)
										
	PINSRD XMM1, ECX, 2						;ECX value to add to the base register (mimickingArrayPointer).
	PINSRD XMM1, smallest, 3					;Value in smallest to add to the base register (mimickingArrayPointer).

	PADDD XMM0, XMM1						;Perform addition of four pointer (DWORD) values. Results stored in XMM0.

	PEXTRD EBX, XMM0, 0						;Extract the ESI+ECX result and save it in EBX (pointer to sortArray).
	PEXTRD EDX, XMM0, 1						;Extract the ESI+smallest result and save it in EDX (pointer to SortArray).

	MOV AX, [EBX]							;Switch two characters (16 bit) in the sortArray array - Pass the sortArrayPtr[ESI+ECX] to AX
	MOV tempVal, AX							;and store it in tempVal
	MOV AX, [EDX]							;Then, Pass the  sortArrayPtr[ESI+smallest] to AX...
	MOV [EBX], AX							;...and from there to sortArrayPtr[ESI+ECX]
	MOV AX, tempVal							;Finally, retrieve the value stored in tempVal...
	MOV [EDX], AX							;...and save it at sortArrayPtr[ESI+smallest]

	PEXTRD EBX, XMM0, 2						;Extract the EDI+ECX result and save it in EBX (pointer to mimickingArray).
	PEXTRD EDX, XMM0, 3						;Extract the EDI+smallest result and save it in EDX (pointer to mimickingArray).
										;Switch pointers in the mimicking array
	MOV EAX, [EBX]							;Pass the value of mimickingArrayPtr[EDI + ECX] to EAX...
	MOV tempPtr, EAX						;...and store it in tempPtr DWORD
	MOV EAX, [EDX]							;Pass the value of mimickingArrayPtr[EDI + smallest] to EAX...
	MOV [EBX], EAX							;...and overwrite the value in mimickingArrayPtr[EDI + ECX]
	MOV EAX, tempPtr						;At the end, get the value stored in tempPtr...
	MOV [EDX], EAX							;...and overwrite the mimickingArrayPtr[EDI + smallest]. The values are switched now.

	POP EAX									;Return the key length value to the EAX

	ROR ECX, 2								;Divide ECX by 4 (bring it back to 1x counter). No need to reset smallest since it will have new value assigned before any other type of use.
	ADD ECX, 1h								;Increase the iterator
	SUB EAX, 1h								;And decrease temporarily the length (as 'n') of the array - the outer loop needs to stop when its counter (ECX) reaches n-1. If it reaches one step further - the last character
											;will be compared with character after the last one, which does not belong to the array.
	CMP ECX, EAX							;Check if the counter for OuterLoop reached the end of the array.
	JNZ OuterLoop							;If the counter did not reach the end - jump back to the OuterLoop.
EndOuterLoop:

	POP EDI									;Restore the used registers value.
	POP ESI
	POP EDX
	POP ECX
	POP EBX
	POP EAX

	RET
SortFirstSecondMimics ENDP
;*****************************************************************

;*****************************************************************
;*Performs the encryption process by sorting the key (and data assigned to its parts) and reading the result.
;**Input:
;***encoded in ADFGVX string with message 
;***string with key used in encryption
;***Length of the message to encrypt
;***Length of the key
;**The output is encrypted string, in msgStr pointer.
;*Uses registers: EAX, EBX, ECX, EDX, EDI, ESI
;*Preserves registers: EAX, EBX, ECX, EDX, EDI, ESI
;*****
;*Note that the passed characters are in UTF-16
;*****************************************************************
PerformEncryption PROC keyLength:DWORD, msgLength:DWORD, keyStr:DWORD, msgStr:DWORD
	LOCAL encryptedMsg, keyStrPtr:DWORD, processHeap:DWORD		;Local variables that will be used to store addresses to finally encrypted message and pointer array (used to read encrypted message).\

	PUSH EAX									;Preserve the values of the used registers.
	PUSH EBX
	PUSH ECX
	PUSH EDX
	PUSH ESI
	PUSH EDI

	MOV EBX, keyLength							;Put the length of the string into EBX register. Needed for declaration of pointers array.
	ROL EBX, 2									;Multiply by 4 amount of BYTEs needed for the pointers array (stores DWORDs).
	INVOKE GetProcessHeap						;Retrieve the address of the heap for the process. Address returned in EAX.
	MOV processHeap, EAX
	INVOKE HeapAlloc, EAX, heapAllocFlags, EBX   ;Tries to allocate array on the process' heap of desired length.
	MOV keyStrPtr, EAX							;Save the address of the pointer array.

				;Set the pointers in keyStrPtr
	MOV ECX, 0h									;Prepare a counter to iterate through the pointer array. We start with the 0 index.
	MOV EBX, 2h									;Prepare the length in bytes of a single characer (faster operations)
	MOV EDX, 4h									;Prepare the length in bytes of a DWORD (faster operations)
	MOV ESI, msgStr								;Source array address in ESI
	MOV EDI, EAX								;Destination array in EDI

SetPointersLoop:							;Loop that prepares pointers to first elements of the msgStr by filling the keyStrPtr array with pointers to the source (msgStr).
	MOV [EDI], ESI							;Pass the address of current element from the source to array (ESI) field under address in EDI
	ADD ESI, EBX							;Increase pointer of source by 2 BYTEs
	ADD EDI, EDX							;Increase pointer to destination by 4 BYTEs
	ADD ECX, 1h								;Increase the step of the loop. Limit is the size of the key.
	CMP ECX, keyLength						;If the next iteration number equals the keyLength...
	JZ StartSorting							;...begin sorting the key.
	JMP SetPointersLoop						;...else perform next iteration and assign next pointer.

StartSorting:
	PUSH keyLength							;Push the length of both arrays
	PUSH keyStrPtr							;Push the array of pointers to characters given positions in keyStrPtr
	PUSH keyStr								;Push the key characters on the stack
	CALL SortFirstSecondMimics				;Call the sorting procedure. The keyStr shall be sroted from now on (increasingly) and the keyStrPtr shall resemble keyStr.
	
	MOV EAX, msgLength						;Prepare the amount of bytes for the encryptedMsg allocation (will store WORD length characters)...
	ROL EAX, 1								;...and multiply it by 2 to make all the WORDs fit in there.

	INVOKE HeapAlloc, processHeap, heapAllocFlags, EAX	;Alllocate array that will temporarily store read encrypted message.
	MOV encryptedMsg, EAX					;Store the address of the newly created array.

	MOV ESI, keyStrPtr						;Prepare the source (pointers to - keyStrPtr) for iteration
	MOV EDI, EAX							;Prepare the pointer to result array.

	MOV ECX, 0h								;Set the counter to 0
ReadingLoop:								;Outer loop - for iteration through the source message
	MOV EBX, 0h								;Reset the inner counter to 0
	
	ReadingLoopInner:						;Inner loop - iterates through the keyStrPtr
		MOV EDX, [ESI + EBX*4]				;Take address to a WORD character from source array using pointers array pointer...
		MOV DX, WORD PTR [EDX]						;...and dereference the pointer once again in order to retrieve the WORD character.
		MOV WORD PTR [EDI+ECX*2], DX		;...and put it in next WORD type spot in the result array.
		MOV EDX, DWORD PTR keyLength					;Prepare for pointer move - add base of the movement...
		ROL EDX, 1h							;...then multiply the amount of BYTEs to move by 2 since the characters are WORDs...
		ADD EDX, [ESI + EBX*4]				;...and add the current address of the pointer.
		MOV [ESI + EBX*4], EDX				;Finally, save the new value of the pointer (positioned right after all of the remaining pointers).

		ADD ECX, 1h							;Increment the outer loop counter (msgStr)
		ADD EBX, 1h							;Increment the inner loop counter (keyStrPtr)
		CMP EBX, keyLength					;Compare the inner loop counter with length of the key...
		JNZ ReadingLoopInner				;...if the values are not equal - keep iterating, else leave the loop.

	CMP ECX, msgLength						;Compare the outer loop counter with the length of the message...
	JNZ ReadingLoop							;...if the values are not equal - perform another iteration. Else exit loop.
	
	MOV ESI, EAX							;Move the encryptedMsg address to source reqister
	MOV EDI, msgStr							;Move the message source to the result register
	MOV ECX, msgLength						;Prepare the counter
	CLD										;We iterate backwards
	REP MOVSW								;Copy all WORDs
	
	INVOKE HeapFree, processHeap, 0h, keyStrPtr		;Clear allocated temporary memory for array of pointers that created reading window.
	INVOKE HeapFree, processHeap, 0h, encryptedMsg	;Clear the allocated temporary memory for ready message reading.

	
	POP EDI									;Restore values of used registers.
	POP ESI
	POP EDX
	POP ECX
	POP EBX
	POP EAX

	RET
PerformEncryption ENDP
;*****************************************************************

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
	LOCAL desiredLength: DWORD						;The length of encrypted message (with added characters, each char is a WORD)
	LOCAL lengthenedMsg: DWORD						;Pointer to the lengthened message (with eventually added X and G characters).
												;Prepare the lengths of the key and the message to be passed to the procedure
	PUSH keyLength								;Put the first argument (keyLength) on the stack
	PUSH msgLength								;Put the second argument (msgLength) on the stack
	CALL CalcNeededLength						;Call the procedure that calculates needed length, using passed above arguments.
	MOV desiredLength, EAX						;Put the result of the CalcNeededLength procedure in DesiredLength (value returned in EAX).

	PUSH desiredLength							;Put the needed arguments on the stack (from right to left).
	PUSH msgLength
	PUSH msgStr
	CALL LengthenString							;Retrieve the address of lengthened 16 bit array of chars through the stack...
		;POP lengthenedMsg							;...and assign it to lengthenedMsg DWORD.
	MOV lengthenedMsg, EAX						;...and assign it to lengthenedMsg DWORD.
	
	PUSH lengthenedMsg							;Put the message to encrypt, ...
	PUSH keyStr									;...the pointer to the string with the key, ...
	PUSH desiredLength							;...the length of the message to encrypt...	
	PUSH keyLength								;...and the length of the key on the stack.
	CALL PerformEncryption						;Then begin the encryption process.

	MOV EAX, lengthenedMsg						;Prepare the result - encrypted message - for return

	RET											;Return to the caller.

EncryptMsg ENDP
;********************************

;*****************************************************************
;*Allows managed programs to release unmanaged memory that has been declared in this library.
;**Input:
;***Pointer to memory chunk, allocated via HeapAlloc()
;*No output.
;*Uses EAX register.
;*Preserves EAX register.
;*****************************************************************
FreeUtf16TextChunk PROC memChunkPtr:DWORD
	PUSH EAX									;Preserve previous value of EAX.

	INVOKE GetProcessHeap						;Retrieve the heap of the process. Address stored in EAX
	INVOKE HeapFree, EAX, 0h, memChunkPtr		;Free memory pointed to by memChunkPtr

	MOV EAX, 0h
	MOV memChunkPtr, EAX						;Set the pointer to 0h (nullptr)

	POP EAX										;Recover the value of the EAX register.

	RET											;Returnto caller
FreeUtf16TextChunk ENDP
;*****************************************************************


END DllEntry

END

;Notki:
;-Zapis - little endian na wiêkszoœci procesorów x86 - st¹d zapis np. litery '¿' (dw 017Ch) w UTF16:
;		  db 7Ch, 01h
;TODO
;Z jednej z procedur zwracana jest dynamicznie zaalokowana pamiêæ. Trzeba bêdzie dopisaæ procedurê zwalniaj¹c¹ pamiêæ t¹ (wywo³ana z g³ównego programu, 
;poibiera adres sterty procesu i dostaje jako arg. adres tablicy).
;DONE






;;;;;;;;;;
;BACKUP
;;;;;;;;;;
;ROL ECX, 1								;multiply ECX by 2 (switching of 16bit chars is about to happen)
;	ROL smallest, 1							;Multiply smallest by 2 (switching of 16bit chars is about to happen)
;	MOV EBX, ESI							;Prepare the first base register value for switching values in sortArrayPtr
;	ADD EBX, ECX							;Add ECX value to the base register.
;	MOV EDX, ESI							;Prepare the second base register value for switching values in sortArrayPtr
;	ADD EDX, smallest						;Add value in smallest to the base register.		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Make it SSE instructions;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	MOV AX, [EBX]							;Switch two characters (16 bit) in the sortArray array - Pass the sortArrayPtr[ESI+ECX] to AX
;	MOV tempVal, AX							;and store it in tempVal
;	MOV AX, [EDX]							;Then, Pass the  sortArrayPtr[ESI+smallest] to AX...
;	MOV [EBX], AX							;...and from there to sortArrayPtr[ESI+ECX]
;	MOV AX, tempVal							;Finally, retrieve the value stored in tempVal...
;	MOV [EDX], AX							;...and save it at sortArrayPtr[ESI+smallest]

;	ROL ECX, 1								;multiply ECX by 2 (switching of 32bit pointers is about to happen)
;	ROL smallest, 1							;Multiply smallest by 2 (switching of 32bit pointers is about to happen)
;	MOV EBX, EDI							;Prepare the first base register value for switching values in sortArrayPtr
;	ADD EBX, ECX							;Add ECX value to the base register.
;	MOV EDX, EDI							;Prepare the second base register value for switching values in sortArrayPtr
;	ADD EDX, smallest						;Add value in smallest to the base register.		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Make it SSE instructions;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
										;Switch pointers in the mimicking array
;	MOV EAX, [EBX]							;Pass the value of mimickingArrayPtr[EDI + ECX] to EAX...
;	MOV tempPtr, EAX						;...and store it in tempPtr DWORD
;	MOV EAX, [EDX]							;Pass the value of mimickingArrayPtr[EDI + smallest] to EAX...
;	MOV [EBX], EAX							;...and overwrite the value in mimickingArrayPtr[EDI + ECX]
;	MOV EAX, tempPtr						;At the end, get the value stored in tempPtr...
;	MOV [EDX], EAX							;...and overwrite the mimickingArrayPtr[EDI + smallest]. The values are switched now.