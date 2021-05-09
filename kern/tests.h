/* See COPYRIGHT for copyright information. */
#ifndef FOS_KERN_TESTS_H
#define FOS_KERN_TESTS_H
#ifndef FOS_KERNEL
# error "This is a FOS kernel header; user programs should not #include it"
#endif

#include <kern/command_prompt.h>
#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

void TestAssignment2();
int TestAss2Q1();
int TestAss2Q2();
int TestAss2Q3();
int TestAss2Q4();
int TestAss2BONUS();
int CheckArrays(int *expectedArr, int *actualArr, int N);

#endif /* !FOS_KERN_TESTS_H */
