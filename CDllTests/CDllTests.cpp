// CDllTest.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "CDllTests.h"
extern "C" __declspec(dllexport) char16_t* __stdcall CallEncryptMessage(int keyLength, int msgLength, char16_t* keyStr, char16_t* msgStr)
{
	return EncryptMsg(keyLength, msgLength, keyStr, msgStr);
}
extern "C" __declspec(dllexport) void __stdcall CallFreeUtf16TextChunk(char16_t* characterArray)
{
	FreeUtf16TextChunk(characterArray);
}
//////////////////////////////////////////////////
//////DEBUGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
//////////////////////////////////////////////////
extern "C" __declspec(dllexport) int __stdcall debugCallCalcNeededLength(int msgLength, int keyLength)
{
	return CalcNeededLength(msgLength, keyLength);
}

extern "C" __declspec(dllexport) char16_t* __stdcall callLengthenString(char16_t* msgPtr, int sourceLength, int desiredLength)
{
	return LengthenString(&msgPtr[0], sourceLength, desiredLength);
}

//https://msdn.microsoft.com/en-us/library/ms235282.aspx
