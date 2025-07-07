#include "ascon.h"
#include "permutation.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

//------------------------------------------------
// ASCON implementation following the NIST Special Publication 800, NIST SP 800-232 ipd
//------------------------------------------------

//unsure of the generalization of this IV, as t=128 is not defined,
//only given for this specific algorithm
uint64_t IV = ((((((((uint64_t) RATIO<<16) + 128)<<4) + NB_RNDS_B)<<4) + 
                                                    NB_RNDS_A)<<16) + VERSION;

//main functions
void ASCONEncrypt(uint8_t* C, uint8_t* T, uint8_t* P, int len_p,
                uint8_t* A, int len_a, uint8_t* n, uint8_t* key){
    State_t* state = initialization(P, len_p, A, len_a, n, key, true);
    
    associated_data_process(state);
    
    plaintext_process(state, len_p%RATIO);
    
    finalization(state, key, T);

    slice(state->blocktext_out, C, len_p);
    
    free_state(state);
    return;
}


void ASCONDecrypt(uint8_t* C, uint8_t* P, int len_p, uint8_t* A, int len_a,
                uint8_t* n, uint8_t* key, uint8_t* T, bool* fail){
    State_t* state = initialization(C, len_p, A, len_a, n, key,false);
    
    associated_data_process(state);
    
    ciphertext_process(state, len_p%RATIO);
    
    uint8_t* Tprim = malloc(KEY_LENGTH/BYTE_LENGTH*sizeof(uint8_t));
    
    finalization(state, key, Tprim);

    if (same_tag(T,Tprim)){
        *fail = false;
        slice(state->blocktext_out, P, len_p);
    }
    else{
        *fail = true;
    }
    
    free(Tprim);
    free_state(state);
    return;
}

//initialzation functions
uint64_t get_IV(void){
    return IV;
}

uint8_t** combine(uint8_t* text, int len, bool padding){
    //new_len : has to be incremented either for the added padding
    //or because the value has been floored
    //if padding=false and len%RATIO=0, adding an empty block
    int new_len  = len/RATIO + 1;
    uint8_t** new_text = malloc(new_len*sizeof(uint8_t*));
    for(int i=0; i<new_len;i++){
        new_text[i] = calloc(RATIO,sizeof(uint8_t));
    }

    for(int i=0; i<len; i++){//little endian for each 64bit block
        new_text[i/RATIO][8*((i%RATIO)/8) + 7 +(-i)%8] = text[i];
    }
    //adding a 1 at the end of the block if a padding is needed
    if(padding)
        new_text[new_len-1][8*((len%RATIO)/8) + 7 +(-len)%8] += 0x01;
    return new_text;
}

State_t* state_initialization(uint8_t* textin, int len_p, uint8_t* A,
                            int len_a, uint8_t* n, uint8_t* key, bool plain){
    
    State_t* state = (State_t*)malloc(sizeof(State_t));
    
    state->words[0] = get_IV();
    
    //|K| + |n| + 64 = 320, so K U n has 32 bytes,
    //adds K then n to the four last words of state
    state->words[1] = 0;
    state->words[2] = 0;
    state->words[3] = 0;
    state->words[4] = 0;
    for(int i = 0; i<32; i++){
        uint64_t curr_byte = (i<KEY_LENGTH/BYTE_LENGTH)?
                                key[i] : n[i-KEY_LENGTH/BYTE_LENGTH];
        state->words[1 + i/8] += curr_byte<<((i*BYTE_LENGTH)%64);
    }
    
    state->Ai = combine(A, len_a, true);
    state->s = len_a/RATIO + 1;
    
    state->blocktext_in = combine(textin, len_p, plain);
    state->t = len_p/RATIO + 1;
    
    state->blocktext_out = malloc(state->t*sizeof(uint8_t*));
    for(int i=0; i<state->t; i++){
        state->blocktext_out[i] = calloc(RATIO,sizeof(uint8_t));
    }
    
    return state;
}

State_t* initialization(uint8_t* textin, int len_p, uint8_t* A, int len_a,
                        uint8_t* n, uint8_t* key, bool plain){
    State_t* state = state_initialization(textin,len_p,A,len_a,n,key,plain);

    permutation(state,NB_RNDS_A);

    for(int i=0; i<KEY_LENGTH/BYTE_LENGTH;i++){
        //finds the first modified word to add the key at the end of the state 
        int ind = 5 - KEY_LENGTH/64 - (KEY_LENGTH%64 != 0) + i/8;
        state->words[ind] ^= (uint64_t) key[i]<<((i*BYTE_LENGTH)%64);
    }
    return state;
}

//processing associated data
void associated_data_process(State_t* state){
    for(int i=0; i<state->s; i++){
        for(int j=0; j<RATIO; j++){
            int shift = (RATE-((j+1)*BYTE_LENGTH))%64;
            state->words[j/8] ^= (uint64_t) state->Ai[i][j]<<shift;
        }
        permutation(state, NB_RNDS_B);
    }
    //update for the least significant byte in little endian
    state->words[4] ^= (uint64_t) 1<<63;
    return;
}

//processing plaintext/ciphertext
void plaintext_process(State_t* state, int l){
    for(int i=0; i<state->t-1; i++){
        for(int j=0; j<RATIO; j++){
            int shift = (RATE-((j+1)*BYTE_LENGTH))%64;
            state->words[j/8] ^= (uint64_t) state->blocktext_in[i][j]<<shift; 
            //too much bits for a uint8_t, only takes the smallest byte
            state->blocktext_out[i][j] = state->words[j/8]>>shift; 
        }
        permutation(state,NB_RNDS_B);
    }
    //C_l is going to have its RATIO-l least significant bytes uninitialized,
    //but it is unimportant because C will be computed only with its beginning
    for(int j=0; j<l+1; j++){
        int i = state->t - 1;
        //not every byte will be explored so the order matters
        int ind = 8*((j%RATIO)/8) + 7 +(-j)%8;
        int shift = (RATE-((ind+1)*BYTE_LENGTH))%64;
        state->words[ind/8] ^= (uint64_t) state->blocktext_in[i][ind]<<shift;
        state->blocktext_out[i][ind] = state->words[(ind-1)/8]>>shift;
    }
    return;
}

void ciphertext_process(State_t* state, int l){
    for(int i=0; i<state->t-1; i++){
        for(int j=0; j<RATIO; j++){
            uint8_t wbyte = state->words[j/8]>>((RATE-((j+1)*BYTE_LENGTH))%64);
            state->blocktext_out[i][j] = wbyte^state->blocktext_in[i][j];
            char* word = (char*) &(state->words[j/8]);
            word[(RATIO-1-j)%8] = state->blocktext_in[i][j];
        }
        permutation(state, NB_RNDS_B);
    }
    
    for(int j=0; j<l; j++){
        int i = state->t - 1;
        //not every byte will be explored so the order matters
        int ind = 8*((j%RATIO)/8) + 7 +(-j)%8;
        uint8_t wbyte = state->words[ind/8]>>((RATE-((ind+1)*BYTE_LENGTH))%64);
        state->blocktext_out[i][ind] = wbyte^state->blocktext_in[i][ind];
        char* word = (char*) &(state->words[j/8]);
        word[(RATIO-1-ind)%8] = state->blocktext_in[i][ind];
    }
    state->words[l/8] ^= (uint64_t) 1<<((BYTE_LENGTH*l)%64);
    return;
}

//finalization functions
void slice(uint8_t** blocktextout, uint8_t* textout, int len){
    for(int i=0; i<len; i++){
        textout[i] = (blocktextout[i/RATIO][8*((i%RATIO)/8) + 7 +(-i)%8]);
    }
    return;
}

void finalization(State_t* state, uint8_t* key, uint8_t* T){
    for(int i=0; i<KEY_LENGTH/BYTE_LENGTH;i++){
        //adding the key after the rate
        int ind = (RATIO-1)/8 + 1 + i/8;
        state->words[ind] ^= (uint64_t) key[i]<<((i*BYTE_LENGTH)%64);
    }

    permutation(state, NB_RNDS_A);
    
    for(int i=0; i<TAG_LENGTH/BYTE_LENGTH;i++){
        //xors the last TAG_LENGTH bits of the key and the state
        int ind = 5 - TAG_LENGTH/64 - (TAG_LENGTH%64 != 0) + i/8;
        uint8_t key_byte = key[i + (KEY_LENGTH-TAG_LENGTH)/BYTE_LENGTH];
        T[i] = state->words[ind]>>((i*BYTE_LENGTH)%64) ^ key_byte; 
    }
    return;
}

bool same_tag(uint8_t* T,uint8_t* Tprim){
    bool res = true; 
    for(int i=0; i<TAG_LENGTH/BYTE_LENGTH; i++){
        //to have the same computation time no matter the value of T and T'
        res = res && (T[i] == Tprim[i]);
    }
    return res;
}

void free_state(State_t* state){
    for(int i=0; i<state->s; i++)
        free(state->Ai[i]);
    free(state->Ai);
    for(int i=0; i<state->t; i++){
        free(state->blocktext_in[i]);
        free(state->blocktext_out[i]);
    }
    free(state->blocktext_in);
    free(state->blocktext_out);
    free(state);
    return;
}