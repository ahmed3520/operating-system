#ifndef FOS_KERN_MONITOR_H
#define FOS_KERN_MONITOR_H
#ifndef FOS_KERNEL
# error "This is a FOS kernel header; user programs should not #include it"
#endif

#include <inc/types.h>

// Function to activate the kernel command prompt
void run_command_prompt();
int execute_command(char *command_string);

// Declaration of functions that implement command prompt commands.
int command_help(int , char **);
int command_kernel_info(int , char **);
int command_ver(int number_of_arguments, char **arguments);
int command_add(int number_of_arguments, char **arguments);

/*ASSIGNMENT2*/
int* CreateIntArray(int numOfArgs, char** arguments);
void CopyElements(char** arguments);
int FindElementInArray(char** arguments);
int CalcArrVar(char** arguments);

int command_cnia(int , char **);
int command_ces(int , char **);
int command_fia(int , char **);
int command_cav(int , char **);

/*ASSIGNMENT2 - BONUS*/
void MergeTwoArrays(char** arguments);
int command_mta(int , char **);

#endif	// !FOS_KERN_MONITOR_H
