#include "ascon.h"

#ifndef PERMUTATION_H
#define PERMUTATION_H

//functions for the permutation
void permutation(State_t* state, int nb_rounds); 
//modifies the current state by applying nb_rounds times the permutation

uint8_t round_const(int nb_rounds, int round);
//computes the constant as shown in table 2 of the permutation section
void perm_const(State_t* state, uint8_t c);

void perm_sub(State_t* state);

uint64_t circular_shift(uint64_t word, int nb);
//shifts the word nb spaces right (in a circular way)
void perm_lin(State_t* state);

#endif