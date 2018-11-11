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
int main()
{
    std::cout << "Hello World!\n"; 
	int data = callFoo();

	try
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
	catch (exception ex)
	{
		cout << ex.what();
	}

	getchar();
}

/*TODO
-test the LengthenString procedure!*/

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
