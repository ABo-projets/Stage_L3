/**
* function implementation for Ascon's permutation
* @author Alexane Boldo
* @date 11/07/25
*/

#include "permutation.h"

//-----------------------------------------------------------------------------------------------------------------------------
// permutation implementation for Ascon, following the NIST Special Publication 800, NIST SP 800-232 ipd
//-----------------------------------------------------------------------------------------------------------------------------
 
void permutation(State_t* state, int nb_rounds){
    for (int r=0; r<nb_rounds; r++){
        uint8_t c = round_const(nb_rounds,r);
        perm_const(state, c);
        
        perm_sub(state);
        
        perm_lin(state);
        
    }
    return;
}

uint8_t round_const(int nb_rounds, int round){
    //finds the right index, defining for 12 rounds c_0 = 0xf0
    int i = 12 - nb_rounds + round;

    //relationship between index and value, defined for i in (-4,11)
    return 0xf0 - i*0x10 + (0x10+i)%0x10;
}

void perm_const(State_t* state, uint8_t c){
    state->words[2] ^= (uint64_t)c;
    return;
}

void perm_sub(State_t* state){
    //applies the bitsliced implementation as given in the norm
    state->words[0] ^= state->words[4]; state->words[4] ^= state->words[3] ; state->words[2] ^= state->words[1];
    uint64_t t0 = state->words[0]; uint64_t t1 = state->words[1] ; uint64_t t2 = state->words[2]; 
    uint64_t t3 = state->words[3] ; uint64_t t4 = state->words[4];
    t0 =~ t0; t1 =~ t1 ; t2 =~ t2 ; t3 =~ t3 ; t4 =~ t4;
    t0 &= state->words[1] ; t1 &= state->words[2] ; t2 &= state->words[3] ; t3 &= state->words[4] ; t4 &= state->words[0];
    state->words[0] ^= t1 ; state->words[1] ^= t2 ; state->words[2] ^= t3 ; state->words[3] ^= t4 ; state->words[4] ^= t0;
    state->words[1] ^= state->words[0] ; state->words[0] ^= state->words[4];
    state->words[3] ^= state->words[2] ; state->words[2] =~ state->words[2];
    return;
}

uint64_t circular_shift(uint64_t word, int nb){
    uint64_t shifted = word>>nb;
    uint64_t extracted = word<<(RATE-nb);
    return shifted+extracted;
}

void perm_lin(State_t* state){
    //calculates the sigma functions
    state->words[0] = state->words[0]^circular_shift(state->words[0],19)^circular_shift(state->words[0],28);
    state->words[1] = state->words[1]^circular_shift(state->words[1],61)^circular_shift(state->words[1],39);
    state->words[2] = state->words[2]^circular_shift(state->words[2],1)^circular_shift(state->words[2],6);
    state->words[3] = state->words[3]^circular_shift(state->words[3],10)^circular_shift(state->words[3],17);
    state->words[4] = state->words[4]^circular_shift(state->words[4],7)^circular_shift(state->words[4],41);
    return;
}