#include <kern/tests.h>

//define the white-space symbols
#define WHITESPACE "\t\r\n "

void TestAssignment2()
{
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q1:\n");
	cprintf("========================\n");
	TestAss2Q1();
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q2:\n");
	cprintf("========================\n");
	TestAss2Q2();
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q3:\n");
	cprintf("========================\n");
	TestAss2Q3();
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q4:\n");
	cprintf("========================\n");
	TestAss2Q4();
	cprintf("\n===========================\n");
	cprintf("Automatic Testing of BONUS:\n");
	cprintf("===========================\n");
	TestAss2BONUS();
}

int TestAss2Q1()
{
	int retValue = 1;
	int i = 0;
	//Create first array
	char cr1[100] = "cnia x 3 1 2 3";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int* ptr1 = CreateIntArray(numOfArgs, args) ;
	assert(ptr1 >= (int*)0xF1000000);

	//Check elements of 1st array
	int expectedArr1[] = {1, 2, 3};
	if (!CheckArrays(expectedArr1, ptr1, 3))
	{
		cprintf("[EVAL] #1 CreateIntArray: Failed\n");
		return retValue;
	}

	//Create second array
	char cr2[100] = "cnia myArr 4 7 8";
	numOfArgs = 0;
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
	assert(ptr2 >= (int*)0xF100000C);

	//Check elements of 2nd array
	int expectedArr2[] = {7, 8, 0, 0};
	if (!CheckArrays(expectedArr2, ptr2, 4))
	{
		cprintf("[EVAL] #2 CreateIntArray: Failed\n");
		return retValue;
	}

	//Check elements of 1st array
	if (!CheckArrays(expectedArr1, ptr1, 3))
	{
		cprintf("[EVAL] #3 CreateIntArray: Failed\n");
		return retValue;
	}

	//Create third array
	char cr3[100] = "cnia zeros 10";
	numOfArgs = 0;
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
	assert(ptr3 >= (int*)0xF100001C);

	//Check elements of 3rd array
	for (i=0 ; i<10; i++)
	{
		if (ptr3[i] != 0)
		{
			cprintf("[EVAL] #4 CreateIntArray: Failed\n");
			return retValue;
		}
	}
	//Check elements of 2nd array
	if (!CheckArrays(expectedArr2, ptr2, 4))
	{
		cprintf("[EVAL] #5 CreateIntArray: Failed\n");
		return retValue;
	}

	//Check elements of 1st array
	if (!CheckArrays(expectedArr1, ptr1, 3))
	{
		cprintf("[EVAL] #6 CreateIntArray: Failed\n");
		return retValue;
	}

	cprintf("[EVAL] CreateIntArray: Succeeded\n");

	return retValue;
}

int TestAss2Q2()
{
	int retValue = 1;
	int i = 0;
	//Create first array
	char cr1[100] = "cnia final 10";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
	assert(ptr1 >= (int*)0xF1000000);

	//Create second array
	char cr2[100] = "cnia srcArr 3 1 2 3";
	numOfArgs = 0;
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
	assert(ptr2 >= (int*)0xF1000000);

	//Create third array
	char cr3[100] = "cnia dstArr 5 7 8";
	numOfArgs = 0;
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
	assert(ptr3 >= (int*)0xF1000000);

	//Copy: Test1
	char cr4[100] = "ces srcArr dstArr 0 2 3";
	numOfArgs = 0;
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;

	CopyElements(args) ;

	int expectedArr1[] = {7, 8, 1, 2, 3};
	if (!CheckArrays(expectedArr1, ptr3, 5))
	{
		cprintf("[EVAL] #1 CopyElements: Failed\n");
		return 1;
	}

	//Copy: Test2
	char cr5[100] = "ces dstArr final 0 0 5";
	numOfArgs = 0;
	strsplit(cr5, WHITESPACE, args, &numOfArgs) ;

	CopyElements(args) ;

	int expectedArr2[] = {7, 8, 1, 2, 3, 0, 0, 0, 0, 0};
	if (!CheckArrays(expectedArr2, ptr1, 10))
	{
		cprintf("[EVAL] #2 CopyElements: Failed\n");
		return 1;
	}

	//Copy: Test3
	char cr6[100] = "ces final final 0 5 5";
	numOfArgs = 0;
	strsplit(cr6, WHITESPACE, args, &numOfArgs) ;

	CopyElements(args) ;

	int expectedArr3[] = {7, 8, 1, 2, 3, 7, 8, 1, 2, 3};
	if (!CheckArrays(expectedArr3, ptr1, 10))
	{
		cprintf("[EVAL] #3 CopyElements: Failed\n");
		return 1;
	}

	//Check other arrays
	int expectedArr4[] = {1, 2, 3};
	if (!CheckArrays(expectedArr4, ptr2, 3))
	{
		cprintf("[EVAL] #4 CopyElements: Failed\n");
		return 1;
	}
	if (!CheckArrays(expectedArr1, ptr3, 5))
	{
		cprintf("[EVAL] #5 CopyElements: Failed\n");
		return 1;
	}


	cprintf("[EVAL] CopyElements: Succeeded\n");

	return retValue;
}

int TestAss2Q3()
{
	int ret = 1;
	int i = 0;
	//Create first array
	char cr1[100] = "cnia y 5 10 20 30 40 30";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
	assert(ptr1 >= (int*)0xF1000000);

	//Create second array
	char cr2[100] = "cnia z 8 1 2 3 4";
	numOfArgs = 0;
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
	assert(ptr2 >= (int*)0xF1000000);

	//Create third array
	char cr3[100] = "cnia w 3 5 4 3";
	numOfArgs = 0;
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
	assert(ptr3 >= (int*)0xF1000000);

	//Find (Arr not Exist)
	char f2[100] = "fia m 3";
	strsplit(f2, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #1 FindElementInArray: Failed\n");
		return 1;
	}
	//Find (Exist)
	char f3[100] = "fia y 30";
	strsplit(f3, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 2)
	{
		cprintf("[EVAL] #2 FindElementInArray: Failed\n");
		return 1;
	}

	//Find (Not Exist)
	char f4[100] = "fia y 1";
	strsplit(f4, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #3 FindElementInArray: Failed\n");
		return 1;
	}

	//Create fourth array
	char cr4[100] = "cnia m 3 1 3 5";
	numOfArgs = 0;
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;

	int* ptr4 = CreateIntArray(numOfArgs,args) ;
	assert(ptr4 >= (int*)0xF1000000);

	//Find (Not Exist)
	char f5[100] = "fia z 1";
	strsplit(f5, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 0)
	{
		cprintf("[EVAL] #4 FindElementInArray: Failed\n");
		return 1;
	}

	//Find
	char f6[100] = "fia z 0";
	strsplit(f6, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 4)
	{
		cprintf("[EVAL] #5 FindElementInArray: Failed\n");
		return 1;
	}

	char f7[100] = "fia w 3";
	strsplit(f7, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 2)
	{
		cprintf("[EVAL] #6 FindElementInArray: Failed\n");
		return 1;
	}

	char f8[100] = "fia m 3";
	strsplit(f8, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 1)
	{
		cprintf("[EVAL] #7 FindElementInArray: Failed\n");
		return 1;
	}

	cprintf("[EVAL] FindElementInArray: Succeeded\n");

	return 1;
}

int TestAss2Q4()
{
	int retValue = 1;
	int i = 0;
	//Create first array
	char cr1[100] = "cnia _x4 3 10 20 30";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
	assert(ptr1 >= (int*)0xF1000000);


	//Create second array
	char cr2[100] = "cnia _y4 4 400 400";
	numOfArgs = 0;
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	int* ptr2 = CreateIntArray(numOfArgs,args);
	assert(ptr2 >= (int*)0xF1000000);

	int ret =0 ;

	//Calculate var of 1st array
	char v1[100] = "cav _x4";
	strsplit(v1, WHITESPACE, args, &numOfArgs) ;
	ret = CalcArrVar(args) ;

	if (ret != 66)
	{
		cprintf("[EVAL] #1 CalcArrVar: Failed\n");
		return 1;
	}

	//Calculate var of 2nd array
	char v2[100] = "cav _y4";
	strsplit(v2, WHITESPACE, args, &numOfArgs) ;
	ret = CalcArrVar(args) ;

	if (ret != 40000)
	{
		cprintf("[EVAL] #2 CalcArrVar: Failed\n");
		return 1;
	}

	cprintf("[EVAL] CalcArrVar: Succeeded\n");

	return 1;
}

int TestAss2BONUS()
{
	int ret = 1;
	int i = 0;
	//Create first array
	char cr1[100] = "cnia x1 20 1 2 3";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
	assert(ptr1 >= (int*)0xF1000000);

	//Create second array
	char cr2[100] = "cnia y1 30 10 20 30";
	numOfArgs = 0;
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
	assert(ptr2 >= (int*)0xF1000000);

	//Create third array
	char cr3[100] = "cnia z1 10 100 200 300";
	numOfArgs = 0;
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
	assert(ptr3 >= (int*)0xF1000000);

	//Create fourth array
	char cr4[100] = "cnia w1 40 -1 -2 -3";
	numOfArgs = 0;
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;

	int* ptr4 = CreateIntArray(numOfArgs,args) ;
	assert(ptr4 >= (int*)0xF1000000);

	//Merge1
	char mr1[100] = "mta x1 y1 x2";
	numOfArgs = 0;
	strsplit(mr1, WHITESPACE, args, &numOfArgs) ;

	MergeTwoArrays(args) ;

	//Find
	char f1[100] = "fia x1 1";
	strsplit(f1, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #1 MergeTwoArrays: Failed\n");
		return 1;
	}
	char f2[100] = "fia y1 30";
	strsplit(f2, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #2 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f3[100] = "fia x2 1";
	strsplit(f3, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 0)
	{
		cprintf("[EVAL] #3 MergeTwoArrays: Failed\n");
		return 1;
	}

	//Create fifth array
	char cr5[100] = "cnia m1 5 -1 1 -1";
	numOfArgs = 0;
	strsplit(cr5, WHITESPACE, args, &numOfArgs) ;

	int* ptr5 = CreateIntArray(numOfArgs,args) ;
	assert(ptr5 >= (int*)0xF1000000);


	char f4[100] = "fia x2 0";
	strsplit(f4, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 3)
	{
		cprintf("[EVAL] #4 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f5[100] = "fia x2 30";
	strsplit(f5, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 22)
	{
		cprintf("[EVAL] #5 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f6[100] = "fia x2 -1";
	strsplit(f6, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;

	if (ret != -1)
	{
		cprintf("[EVAL] #6 MergeTwoArrays: Failed\n");
		return 1;
	}

	//Merge2
	char mr2[100] = "mta z1 x2 z1";
	numOfArgs = 0;
	strsplit(mr2, WHITESPACE, args, &numOfArgs) ;

	MergeTwoArrays(args) ;

	char f7[100] = "fia z1 100";
	strsplit(f7, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 0)
	{
		cprintf("[EVAL] #7 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f8[100] = "fia x2 1";
	strsplit(f8, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #8 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f9[100] = "fia z1 1";
	strsplit(f9, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 10)
	{
		cprintf("[EVAL] #9 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f10[100] = "fia z1 30";
	strsplit(f10, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 32)
	{
		cprintf("[EVAL] #10 MergeTwoArrays: Failed\n");
		return 1;
	}

	char f11[100] = "fia z1 -1";
	strsplit(f11, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #11 MergeTwoArrays: Failed\n");
		return 1;
	}

	//Check ALL other arrays
	char ff1[100] = "fia x1 1";
	strsplit(ff1, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #12 MergeTwoArrays: Failed\n");
		return 1;
	}

	char ff2[100] = "fia y1 30";
	strsplit(ff2, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != -1)
	{
		cprintf("[EVAL] #12 MergeTwoArrays: Failed\n");
		return 1;
	}

	char ff3[100] = "fia w1 -1";
	strsplit(ff3, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 0)
	{
		cprintf("[EVAL] #13 MergeTwoArrays: Failed\n");
		return 1;
	}

	char ff4[100] = "fia m1 -1";
	strsplit(ff4, WHITESPACE, args, &numOfArgs) ;
	ret = FindElementInArray(args) ;
	if (ret != 0)
	{
		cprintf("[EVAL] #14 MergeTwoArrays: Failed\n");
		return 1;
	}

	return 1;
}

//========================================================
int CheckArrays(int *expectedArr, int *actualArr, int N)
{

	int equal = 1 ;
	for(int i = 0; i < N; i++)
	{
		if(expectedArr[i] != actualArr[i])
			return 0;

	}
	return equal;
}

