// CDllTest.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "CDllTests.h"

//Calls the function from asm lib
extern "C" __declspec(dllexport) int __stdcall callFoo()
{
	return foo();

}
extern "C" __declspec(dllexport) int __stdcall debugCallCalcNeededLength(int msgLength, int keyLength)
{
	return CalcNeededLength(msgLength, keyLength);
}

extern "C" __declspec(dllexport) char16_t* __stdcall callLengthenString(char16_t* msgPtr, int sourceLength, int desiredLength)
{
	return LengthenString(&msgPtr[0], sourceLength, desiredLength);
}

//https://msdn.microsoft.com/en-us/library/ms235282.aspx
