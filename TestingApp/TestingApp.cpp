// TestingApp.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include "pch.h"
#include <iostream>
#include <CDllTests.h>
using namespace std;


class Assert
{
public:
	static void AreEqual(int expected, int result)
	{
		if (!(expected == result))
		{
			cout << "NOT EQUAL: Expected " << expected << "  RESULT: " << result << endl;
		}
	}
	
};
void TestCalcNeededLength()
{
	int msgLength = 20;
	int keyLength = 6;
	int expectedToAdd = keyLength - msgLength % keyLength + msgLength;
	int toAdd = debugCallCalcNeededLength(msgLength, keyLength);


	Assert::AreEqual(expectedToAdd, toAdd);

	msgLength = 18;
	expectedToAdd = 0;
	toAdd = debugCallCalcNeededLength(msgLength, keyLength);

	Assert::AreEqual(msgLength, toAdd);

	msgLength = 5;
	keyLength = 7;
	toAdd = debugCallCalcNeededLength(msgLength, keyLength);

	Assert::AreEqual(keyLength, toAdd);

	msgLength = 0;
	keyLength = 11;
	toAdd = debugCallCalcNeededLength(msgLength, keyLength);

	Assert::AreEqual(keyLength, toAdd);
}
void TestLengthenString()
{
	char16_t* resultMsg = nullptr;
	int keyLength = 6;
	char16_t key[] = { L'k', L'ą', L's', L'e',L'k', L'!' };
	char16_t msgSmallerThanKey[] = { L'k', L'ą', L's' };
	char16_t msgAsLongAsKey[] = { L'k', L'ą', L's', L'e',L'k', L'!' };
	char16_t msgLongerThanKey[] = { L'k', L'ą', L's', L'e',L'k', L'!', L'k', L'ą', L's', L'e' };
	char16_t msgDividableByKey[] = { L'k', L'ą', L's', L'e',L'k', L'!', L'k', L'ą', L's', L'e',L'k', L'!' };

	resultMsg = callLengthenString(msgSmallerThanKey, 3, keyLength);
	CallFreeUtf16TextChunk(resultMsg);
	resultMsg = callLengthenString(msgAsLongAsKey, keyLength, keyLength);
	CallFreeUtf16TextChunk(resultMsg);
	resultMsg = callLengthenString(msgLongerThanKey, keyLength+4, keyLength*2);
	CallFreeUtf16TextChunk(resultMsg);
	resultMsg = callLengthenString(msgDividableByKey, keyLength * 2, keyLength*2);
	CallFreeUtf16TextChunk(resultMsg);

}
void TestEncrypt()
{
	int keyLength = 10;
	int msgLength = 40;
	char16_t key[] = { L'E', L'n', L'c', L'r', L'y',L'p', L't',L'i', L'o', L'n' };
	char16_t msg[] = { L'G', L'X', L'A', L'A',L'F', L'V', L'X', L'D', L'D', L'D', L'D', L'X', L'F', L'A', L'X', L'A',
		L'X', L'A', L'A', L'D', L'G', L'G', L'F', L'A', L'G', L'G', L'D', L'V', L'F', L'A', L'X', L'A', L'A', L'X',
		L'F', L'A', L'F', L'G', L'F', L'A' };
	std::string expected("GADXDDVAXFDFAXDAAAXXGFVGAFGADGXAGAAFAXFF");
	char16_t* result = CallEncryptMessage(keyLength, msgLength, key, msg);
	std::u16string theResult(result);
}
int main()
{
    std::cout << "Hello World!\n"; 
	try
	{
		//TestCalcNeededLength();
		//TestLengthenString();
		TestEncrypt();
	}
	catch (exception ex)
	{
		cout << ex.what();
	}

	getchar();
}

/*TODO
-test the LengthenString procedure! DONE, MAGGTS!*/
/*
"Input message goes here"
"GXAAFVXDDDDXFAXAXAADGGFAGGDVFAXAAXFAFGFA"
"GXAAFVXDDDDXFAXAXAADGGFAGGDVFAXAAXFAFGFA"
"GADXDDVAXFDFAXDAAAXXGFVGAFGADGXAGAAFAXFF"

key:
Encryption*/

/*
projekt pobierajacy bibliotekę -
-Properties->Linker->Input->AdditionalDepediencies->AssemblyLib.lib
-Zbudowanie wymaga .lib'a, .dll podrzucany jest do folderu z .exe później przy odpaleniu programu

biblioteka C++ pobierająca asemblerową:
-ma być .lib
-Linker zamienia się w Librarian - trzeba też wpisać w Additional Dependiences (I lub library directories) nazwę assemblerowej.lib*/


// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
