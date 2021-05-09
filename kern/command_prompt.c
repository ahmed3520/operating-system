/*	Simple command-line kernel prompt useful for
	controlling the kernel and exploring the system interactively.


KEY WORDS
==========
CONSTANTS:	WHITESPACE, NUM_OF_COMMANDS
VARIABLES:	Command, commands, name, description, function_to_execute, number_of_arguments, arguments, command_string, command_line, command_found
FUNCTIONS:	readline, cprintf, execute_command, run_command_prompt, command_kernel_info, command_help, strcmp, strsplit, start_of_kernel, start_of_uninitialized_data_section, end_of_kernel_code_section, end_of_kernel
=====================================================================================================================================================================================================
 */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>


#include <kern/console.h>
#include <kern/command_prompt.h>
#include <kern/memory_manager.h>
#include <kern/trap.h>
#include <kern/kdebug.h>
#include <kern/user_environment.h>
#include <kern/tests.h>


//TODO:LAB3.Hands-on: declare start address variable of "My int array"

//=============================================================

//Structure for each command
struct Command
{
	char *name;
	char *description;
	// return -1 to force command prompt to exit
	int (*function_to_execute)(int number_of_arguments, char** arguments);
};

struct Arrays
{
	char name[20];
	int size;
	//int elements[MAX_ARGUMENTS];
	int *ptr;

};
struct TempArrays
{
	char name[20];
	int size;
	//int elements[MAX_ARGUMENTS];
	int *ptr;

};
struct Arrays arrays[MAX_ARGUMENTS];
int count=0;
  int  *intArrAddress =(int*)0xF1000000;
  int *ptr = (int*)0xF1000000;;
//Functions Declaration
int command_writemem(int number_of_arguments, char **arguments);
int command_readmem(int number_of_arguments, char **arguments);
int command_meminfo(int , char **);

//Lab2.Hands.On
//=============
//TODO: LAB2 Hands-on: declare the command function here


//Lab4.Hands.On
//=============
int command_show_mapping(int number_of_arguments, char **arguments);
int command_set_permission(int number_of_arguments, char **arguments);
int command_share_range(int number_of_arguments, char **arguments);

//Lab5.Examples
//=============
int command_nr(int number_of_arguments, char **arguments);
int command_ap(int , char **);
int command_fp(int , char **);

//Lab5.Hands-on
//=============
int command_asp(int, char **);
int command_cfp(int, char **);

//Lab6.Examples
//=============
int command_run(int , char **);
int command_kill(int , char **);
int command_ft(int , char **);


//Array of commands. (initialized)
struct Command commands[] =
{
		{ "help", "Display this list of commands", command_help },	//don't need arguments
		{ "kernel_info", "Display information about the kernel", command_kernel_info },	//don't need arguments
		{ "wum", "writes one byte to specific location" ,command_writemem},	//need arguments
		{ "rum", "reads one byte from specific location" ,command_readmem},	//need arguments
		{ "ver", "Print the FOS version" ,command_ver},//don't need arguments
		{ "add", "Add two integers" ,command_add},//need arguments

		//Assignment2 commands
		//====================
		{ "cnia", "Create named integer array with the given size", command_cnia},
		{ "ces", "Copy a range of elements from source array to dest array", command_ces},
		{ "fia", "Find item in the given array", command_fia},
		{ "cav", "Calculate the variance of the given array ", command_cav},

		//Assignment2.BONUS command
		//=========================
		{ "mta", "Merge two arrays into a third new one", command_mta},

		//TODO: LAB2 Hands-on: add the commands here


		//LAB4: Hands-on
		{ "sm", "Lab4.HandsOn: display the mapping info for the given virtual address", command_show_mapping},
		{ "sp", "Lab4.HandsOn: set the desired permission to a given virtual address page", command_set_permission},
		{ "sr", "Lab4.HandsOn: shares the physical frames of the first virtual range with the 2nd virtual range", command_share_range},

		//LAB5: Examples
		{ "nr", "Lab5.Example: show the number of references of the physical frame" ,command_nr},
		{ "ap", "Lab5.Example: allocate one page [if not exists] in the user space at the given virtual address", command_ap},
		{ "fp", "Lab5.Example: free one page in the user space at the given virtual address", command_fp},

		//LAB5: Hands-on
		{ "asp", "Lab5.HandsOn: allocate 2 shared pages with the given virtual addresses" ,command_asp},
		{ "cfp", "Lab5.HandsOn: count the number of free pages in the given range", command_cfp},

		//LAB6: Examples
		{ "ft", "Lab6.Example: Free table", command_ft},
		{ "run", "Lab6.Example: Load and Run User Program", command_run},
		{ "kill", "Lab6.Example: Kill User Program", command_kill},

};

//Number of commands = size of the array / size of command structure
#define NUM_OF_COMMANDS (sizeof(commands)/sizeof(commands[0]))

int firstTime = 1;

//invoke the command prompt
void run_command_prompt()
{
	cprintf("========================\n");
	//CAUTION: DON'T CHANGE OR COMMENT THESE LINE======
	if (firstTime)
	{
		firstTime = 0;
		TestAssignment2();

	}
	else
	{
		cprintf("Test failed.\n");
	}
	//================================================

	char command_line[1024];

	while (1==1)
	{
		//get command line
		readline("FOS> ", command_line);

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
				break;
	}
}

/***** Kernel command prompt command interpreter *****/

//define the white-space symbols
#define WHITESPACE "\t\r\n "

//Function to parse any command and execute it
//(simply by calling its corresponding function)
int execute_command(char *command_string)
{
	// Split the command string into whitespace-separated arguments
	int number_of_arguments;
	//allocate array of char * of size MAX_ARGUMENTS = 16 found in string.h
	char *arguments[MAX_ARGUMENTS];


	strsplit(command_string, WHITESPACE, arguments, &number_of_arguments) ;
	if (number_of_arguments == 0)
		return 0;

	// Lookup in the commands array and execute the command
	int command_found = 0;
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
	{
		if (strcmp(arguments[0], commands[i].name) == 0)
		{
			command_found = 1;
			break;
		}
	}

	if(command_found)
	{
		int return_value;
		return_value = commands[i].function_to_execute(number_of_arguments, arguments);
		return return_value;
	}
	else
	{
		//if not found, then it's unknown command
		cprintf("Unknown command '%s'\n", arguments[0]);
		return 0;
	}
}

/***** Implementations of basic kernel command prompt commands *****/
/***************************************/
/*DON'T change the following functions*/
/***************************************/
//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].description);

	cprintf("-------------------\n");

	return 0;
}

/*DON'T change this function*/
//print information about kernel addresses and kernel size
int command_kernel_info(int number_of_arguments, char **arguments )
{
	extern char start_of_kernel[], end_of_kernel_code_section[], start_of_uninitialized_data_section[], end_of_kernel[];

	cprintf("Special kernel symbols:\n");
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
	cprintf("Kernel executable memory footprint: %d KB\n",
			(end_of_kernel-start_of_kernel+1023)/1024);
	return 0;
}


/*DON'T change this function*/
int command_readmem(int number_of_arguments, char **arguments)
{
	unsigned int address = strtol(arguments[1], NULL, 16);
	unsigned char *ptr = (unsigned char *)(address ) ;

	cprintf("value at address %x = %c\n", ptr, *ptr);

	return 0;
}

/*DON'T change this function*/
int command_writemem(int number_of_arguments, char **arguments)
{
	unsigned int address = strtol(arguments[1], NULL, 16);
	unsigned char *ptr = (unsigned char *)(address) ;

	*ptr = arguments[2][0];

	return 0;
}

/*DON'T change this function*/
int command_meminfo(int number_of_arguments, char **arguments)
{
	cprintf("Free frames = %d\n", calculate_free_frames());
	return 0;
}

//===========================================================================
//Lab1 Examples
//=============
/*DON'T change this function*/
int command_ver(int number_of_arguments, char **arguments)
{
	cprintf("FOS version 0.1\n") ;
	return 0;
}

/*DON'T change this function*/
int command_add(int number_of_arguments, char **arguments)
{
	int n1 = strtol(arguments[1], NULL, 10);
	int n2 = strtol(arguments[2], NULL, 10);

	int res = n1 + n2 ;
	cprintf("res=%d\n", res);

	return 0;
}

//===========================================================================
//Lab2.Hands.On
//=============
//TODO: LAB2 Hands-on: write the command function here


//===========================================================================
//Lab4.Hands.On
//=============
int command_show_mapping(int number_of_arguments, char **arguments)
{
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sm"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0 ;
}

int command_set_permission(int number_of_arguments, char **arguments)
{
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sp"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0 ;
}

int command_share_range(int number_of_arguments, char **arguments)
{
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sr"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0;
}

//===========================================================================
//Lab5.Examples
//==============
//[1] Number of references on the given physical address
int command_nr(int number_of_arguments, char **arguments)
{
	//TODO: LAB5 Example: fill this function. corresponding command name is "nr"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0;
}

//[2] Allocate Page: If the given user virtual address is mapped, do nothing. Else, allocate a single frame and map it to a given virtual address in the user space
int command_ap(int number_of_arguments, char **arguments)
{
	//TODO: LAB5 Example: fill this function. corresponding command name is "ap"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0 ;
}

//[3] Free Page: Un-map a single page at the given virtual address in the user space
int command_fp(int number_of_arguments, char **arguments)
{
	//TODO: LAB5 Example: fill this function. corresponding command name is "fp"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0;
}

//===========================================================================
//Lab5.Hands-on
//==============
//[1] Allocate Shared Pages
int command_asp(int number_of_arguments, char **arguments)
{
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "asp"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0;
}


//[2] Count Free Pages in Range
int command_cfp(int number_of_arguments, char **arguments)
{
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "cfp"
	//Comment the following line
	panic("Function is not implemented yet!");

	return 0;
}

//===========================================================================
//Lab6.Examples
//=============
/*DON'T change this function*/
int command_run(int number_of_arguments, char **arguments)
{
	//[1] Create and initialize a new environment for the program to be run
	struct UserProgramInfo* ptr_program_info = env_create(arguments[1]);
	if(ptr_program_info == 0) return 0;

	//[2] Run the created environment using "env_run" function
	env_run(ptr_program_info->environment);
	return 0;
}

/*DON'T change this function*/
int command_kill(int number_of_arguments, char **arguments)
{
	//[1] Get the user program info of the program (by searching in the "userPrograms" array
	struct UserProgramInfo* ptr_program_info = get_user_program_info(arguments[1]) ;
	if(ptr_program_info == 0) return 0;

	//[2] Kill its environment using "env_free" function
	env_free(ptr_program_info->environment);
	ptr_program_info->environment = NULL;
	return 0;
}

int command_ft(int number_of_arguments, char **arguments)
{
	//TODO: LAB6 Example: fill this function. corresponding command name is "ft"
	//Comment the following line

	return 0;
}
/****************************************************************/

//========================================================
/*ASSIGNMENT-2 [MAIN QUESTIONS] */
//========================================================
//Q1:Create Named Int Array
//=========================
/*DON'T change this function*/
int command_cnia(int number_of_arguments, char **arguments )
{
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CreateIntArray() FUNCTION
	CreateIntArray(number_of_arguments, arguments);
	return 0;
}
/*---------------------------------------------------------*/

/*FILL this function
 * arguments[1]: array name
 * arguments[2]: array size
 * arguments[3...(K+3)]: first K items of the array
 * Return:
 * 		Start address of the FIRST ELEMENT in the created array
 *
 * Example:
 * 	FOS> cnia	x	5	10	20	30
 * 				^
 * 				|
 * arguments	[1]	[2]	[3]	...
 * Create integer array named "x", with 5 elements: 10, 20, 30, 0, 0
 * It should return the start address of the FIRST ELEMENT in the created array
 */
int* CreateIntArray(int numOfArgs, char** arguments)
{
	  int offset = 0;
	 strcpy(arrays[count].name,arguments[1]) ;
     arrays[count].size=strtol(arguments[2], NULL, 10);
     int* ptrToInt= (int*)intArrAddress;
     int counterLoc=0;
     int newCounter=0;
     while (*(arguments + offset) != '\0')
      {
          ++counterLoc;
          ++offset;
      }
     newCounter  = counterLoc-3;
     int x=strtol(arguments[2],NULL,10);
     char *ptrr;
     int tottal_index =x-newCounter;

     for(int i=3;i<newCounter+3;i++){

    	*intArrAddress =strtol(arguments[i],NULL,10);
    	 intArrAddress++;
     }
     int k=0;
    while(k<tottal_index){
         if(tottal_index>0){
         		*intArrAddress=0;
         		intArrAddress++;
         	}
         k++;
     }
     arrays[count].ptr=ptrToInt;
    count++;
    return ptrToInt;
}
//========================================================

//Q2:Copy Elements from One Array to Another
//==========================================
/*DON'T change this function*/
int command_ces(int number_of_arguments, char **arguments )
{
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CopyElements() FUNCTION
	CopyElements(arguments) ;
	return 0;
}
/*---------------------------------------------------------*/

/*FILL this function
 * arguments[1]: name of the source array
 * arguments[2]: name of the destination array
 * arguments[3]: start index in the source array
 * arguments[4]: start index in the destination array
 * arguments[5]: number of elements to be copied
 */
void CopyElements(char** arguments)
{
	//TODO: Assignment2.Q2
	//put your logic here
	//...

	int coppied_array[MAX_ARGUMENTS];
	int requested_position;
	int requested_destination;
	for(int i=0;i<count;i++){

		if(strcmp(arrays[i].name, arguments[1])==0){
			requested_position=i;
		}
	}


	for(int i=0;i<count;i++){
		if(strcmp(arguments[2],arrays[i].name)==0){
			requested_destination=i;
			break;

		}else{

			continue;
		}
	}
	  int *destPtr =arrays[requested_destination].ptr;



	  int *pttr = arrays[requested_position].ptr;
	  for(int j=0;j<arrays[requested_position].size;j++){
		  coppied_array[j]=pttr[j];
	  }
	  destPtr+=strtol(arguments[4], NULL, 10);
	  int requestedSize = strtol(arguments[5], NULL, 10);
	  int i=strtol(arguments[3], NULL, 10);
	while(requestedSize--){
		*destPtr=coppied_array[i];
		i++;
		destPtr++;
	}
}
//========================================================

//Q3:Find Element in the Array
//============================
/*DON'T change this function*/
int command_fia(int number_of_arguments, char **arguments )
{
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE FindInArray() FUNCTION
	int itemLoc = FindElementInArray(arguments) ;
	if (itemLoc != -1)
	{
		cprintf("Item is found @ %d\n", itemLoc) ;
	}
	else
	{
		cprintf("Item not found\n");
	}
	return 0;
}
/*---------------------------------------------------------*/

/*FILL this function
 * arguments[1]: array name
 * arguments[2]: item to search on
 * Return:
 * 		If array doesn't exist, return -1
 * 		Else If Item is Found: return item index
 * 		Else: return -1
 */
int FindElementInArray(char** arguments)
{
	//Assignment2.Q3
	//put your logic here
	//...
	int requested_position;
	int requested_destination=-1;
	int status=1;
	for(int i=0;i<count;i++){

		if(strcmp(arrays[i].name, arguments[1])==0){
			requested_position=i;
			status=0;
		}
	}
	if(status==0){
	int *address=arrays[requested_position].ptr;
	for(int i=0;i<arrays[requested_position].size;i++){
		if(address[i]==strtol(arguments[2],NULL,10)){
			requested_destination=i;
			break;
		}
	}
	}

	return requested_destination;
}
//========================================================

//Q4:Calculate Array Variance
//===========================
/*DON'T change this function*/
int command_cav(int number_of_arguments, char **arguments )
{
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CalcArrVar() FUNCTION
	int var = CalcArrVar(arguments);
	cprintf("variance of %s = %d\n", arguments[1], var);
	return 0;
}
/*---------------------------------------------------------*/

/*FILL this function
 * arguments[1]: array name
 */
int CalcArrVar(char** arguments)
{
	//TODO: Assignment2.Q4
	//put your logic here
	//...
	int requested_position;
	int requested_destination=-1;
	int status=1;
	for(int i=0;i<count;i++){
		//cprintf("arrays name %p \n",arrays[5].ptr);
		if(strcmp(arrays[i].name, arguments[1])==0){
			requested_position=i;
			status=0;

		}
	}
	int summisionOfArray=0;
	int *address=arrays[requested_position].ptr;
	for(int i=0;i<arrays[requested_position].size;i++){
		summisionOfArray+=address[i];
	}
	int mainCalc = summisionOfArray/arrays[requested_position].size;
	int bVariance=0;
	for(int i=0;i<arrays[requested_position].size;i++){
		bVariance+=(address[i]-mainCalc)*(address[i]-mainCalc);
	}
	int variance = bVariance/arrays[requested_position].size;
	return variance;
}

//========================================================
/*ASSIGNMENT-2 [BONUS QUESTION] */
//========================================================
//BONUS: Merge Two Arrays
//=======================
/*DON'T change this function*/
int command_mta(int number_of_arguments, char **arguments )
{
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE MergeTwoArrays() FUNCTION
	MergeTwoArrays(arguments);
	return 0;
}
/*---------------------------------------------------------*/

/*FILL this function
 * arguments[1]: name of the first array to be merged
 * arguments[2]: name of the second array to be merged
 * arguments[3]: name of the NEW array
 * After merging the two arrays, they become not accessible anymore [i.e. removed].
 */
void MergeTwoArrays(char** arguments)
{
	//TODO: Assignment2.BONUS
	//put your logic here
	//...
	int*farrPointer;
	int*sarrPointer;
	int*lastArrPointer=arrays[count-1].ptr;
	lastArrPointer+=(arrays[count-1].size*2);
	int *mergedArrayPointer=(int *)lastArrPointer;
	int *scPointer = (int *)lastArrPointer;
	int firstArraySize=0;
	int secondArraySize=0;
	int frstCounter=0;
	int scCounter=0;
	for(int i=0;i<count;i++){
		if(strcmp(arguments[1],arrays[i].name)==0){
		farrPointer=arrays[i].ptr;
		firstArraySize=arrays[i].size;
		frstCounter=i;
		}
		if(strcmp(arguments[2],arrays[i].name)==0){
		sarrPointer=arrays[i].ptr;
		secondArraySize=arrays[i].size;
		scCounter=i;
		}
	}


	//merge first array

	for(int i=0;i<firstArraySize;i++){

		*mergedArrayPointer=farrPointer[i];

		mergedArrayPointer++;

	}

	for(int i=0;i<secondArraySize;i++){

		*mergedArrayPointer=sarrPointer[i];

		mergedArrayPointer++;
	}

	 strcpy(arrays[frstCounter].name,"//") ;
	 strcpy(arrays[scCounter].name,"//") ;

	 strcpy(arrays[count].name,arguments[3]) ;
	 arrays[count].ptr=scPointer;
	 arrays[count].size=arrays[frstCounter].size+arrays[scCounter].size;
	 count++;


}
