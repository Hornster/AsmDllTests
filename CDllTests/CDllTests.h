#pragma once

extern "C" __declspec(dllexport) char16_t* __stdcall CallEncryptMessage(int keyLength, int msgLength, char16_t* keyStr, char16_t* msgStr);
extern "C" char16_t* __stdcall EncryptMsg(int keyLength, int msgLength, char16_t* keyStr, char16_t* msgStr);
extern "C" __declspec(dllexport) void __stdcall CallFreeUtf16TextChunk(char16_t* characterArray);
extern "C" void __stdcall FreeUtf16TextChunk(char16_t* characterArray);
////////////
///DEBUGS///
////////////
extern "C" __declspec(dllexport) int __stdcall debugCallCalcNeededLength(int msgLength, int keyLength);
extern "C" int __stdcall CalcNeededLength(int msgLength, int keyLength);
extern "C" __declspec(dllexport) char16_t* __stdcall callLengthenString(char16_t* msgPtr, int sourceLength, int desiredLength);
extern "C" char16_t* __stdcall LengthenString(char16_t* msgPtr, int sourceLength, int desiredLength);