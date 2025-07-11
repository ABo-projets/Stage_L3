/**
* main for testing
* @author Alexane Boldo
* @date 11/07/25
*/

#include "ascon.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

//debug functions
bool same_message(uint8_t* P, uint8_t* Pprim, int len_p, bool authenticated){
    for (int i=0; i<len_p; i++){
        if (P[i] != Pprim[i]){
            return false;
        }
    }
    return authenticated;
}

int diff_messages(uint8_t* P, uint8_t* Pprim, int len_p){
    int nb = 0;
    for(int i=0; i<len_p; i++){
        if (P[i] != Pprim[i])
            nb++;
    }
    return nb;
}

void printf_listes_8(uint8_t* lst, int len){
    for(int i=0; i<len; i++){
        printf("%x ",lst[i]);
    }
    printf("\n");
}

void printf_listes_64(uint64_t* lst, int len){
    for(int i=0; i<len; i++){
        printf("%lx ",lst[i]);
    }
    printf("\n");
}

void printf_state(State_t* state){
    printf("x0 : %lx\n",state->words[0]);
    printf("x1 : %lx\n",state->words[1]);
    printf("x2 : %lx\n",state->words[2]);
    printf("x3 : %lx\n",state->words[3]);
    printf("x4 : %lx\n",state->words[4]);
    printf("s : %d, t : %d\n",state->s,state->t);
    for(int i=0; i<state->s; i++){
        for(int j=0; j<RATIO; j++)
            printf("%x ",state->Ai[i][j]);
        printf("   ");
    }
    printf("\n");
    for(int i=0; i<state->t; i++){
        for(int j=0; j<RATIO; j++)
            printf("%x ",state->blocktext_in[i][j]);
        printf("   ");
    }
    printf("\n");
}

int main(int argc, char** argv){
    int len_p = 35;
    uint8_t* P = malloc(len_p*sizeof(uint8_t));
    for(int i=1; i<=len_p; i++)
        P[i-1] = i;

    uint8_t* C = malloc(len_p*sizeof(uint8_t));

    int len_a = 7;
    uint8_t A[7] = {0x41,0x42,0x43,0x44,0x45,0x46,0x47};

    uint8_t n[NONCE_LENGTH/BYTE_LENGTH] = {0xd7,0x9a,0x48,0xcf,0x8b,0x55,0xb7,0x37,0x84,0xfb,0x86,0x21,0xeb,0xd7,0x40,0xdd};

    uint8_t key[KEY_LENGTH/BYTE_LENGTH] = {0xf5,0x29,0x6d,0x3b,0xa5,0xe2,0x10,0xc4,0x63,0xb9,0xb0,0x14,0x0b,0xcc,0x33,0x5b};

    uint8_t* T = malloc(TAG_LENGTH/BYTE_LENGTH*sizeof(uint8_t));

    //State_t* state = state_initialization(P,len_p,A,len_a,n,key,true); 
    //printf_state(state);

    ASCONEncrypt(C, T, P, len_p, A, len_a, n, key);

    uint8_t* Pprim = malloc(len_p*sizeof(uint8_t));
    bool fail;

    ASCONDecrypt(C, Pprim, len_p, A, len_a, n, key, T, &fail);

    if (same_message(P, Pprim, len_p, !fail)){
        printf("It was well encrypted/decrypted\n");
        printf_listes_8(C,len_p);
        printf_listes_8(T,TAG_LENGTH/BYTE_LENGTH);
        printf("\n");
    }
    else{
        printf_listes_8(T,TAG_LENGTH/BYTE_LENGTH);
        printf("There are %d differences is the message authenticated ? : %d\n",diff_messages(P, Pprim, len_p), !fail);
        for(int i=0; i<len_p; i++){
            printf(" P : %x, C : %x, Pprim : %x\n", P[i],C[i],Pprim[i]);
        }
    }

    free(P);
    free(C);
    free(T);
    free(Pprim);
    return 0;
}