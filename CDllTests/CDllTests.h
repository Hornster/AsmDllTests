#pragma once

extern "C" __declspec(dllexport) int __stdcall callFoo();
extern "C" int __stdcall foo();

////////////
///DEBUGS///
////////////
extern "C" __declspec(dllexport) int __stdcall debugCallCalcNeededLength(int msgLength, int keyLength);
extern "C" int __stdcall CalcNeededLength(int msgLength, int keyLength);
extern "C" __declspec(dllexport) char16_t* __stdcall callLengthenString(char16_t* msgPtr, int sourceLength, int desiredLength);
extern "C" char16_t* __stdcall LengthenString(char16_t* msgPtr, int sourceLength, int desiredLength);