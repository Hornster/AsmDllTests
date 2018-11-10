#pragma once

extern "C" __declspec(dllexport) int __stdcall callFoo();
extern "C" int __stdcall foo();
////////////
///DEBUGS///
////////////
extern "C" __declspec(dllexport) int __stdcall debugCallCalcNeededLength(int msgLength, int keyLength);
extern "C" int __stdcall CalcNeededLength(int msgLength, int keyLength);