
#ifndef ASCON_H
#define ASCON_H

#define KEY_LENGTH 128
#define TAG_LENGTH 128
#define NONCE_LENGTH (256 - KEY_LENGTH)
#define RATE 128
#define BYTE_LENGTH 8
#define NB_RNDS_A 12
#define NB_RNDS_B 8
#define VERSION 1
#define RATIO (RATE/BYTE_LENGTH)

#include <stdint.h>
#include <stdbool.h>

//defining a type State_t in order to implement the state with the data
typedef struct State_s {
    uint64_t words[5];
    uint8_t** Ai;//asociated data in blocks of size RATE
    int s; //number of blocks in Ai
    uint8_t** blocktext_in; //blocks of the plaintext when encryption, 
                            // when decryption blocks of ciphertext
    int t; //number of blocks in the given text, whether plain or ciphered
    uint8_t** blocktext_out;// output blocks (resp. ciphered or plain)
} State_t;


//main functions
void ASCONEncrypt(uint8_t* C, uint8_t* T, uint8_t* P, int len_p,
                uint8_t* A, int len_a, uint8_t* n, uint8_t* key);
//takes a pointer C pointing towards allocated memory of size len_p,
//and a pointer T for the tag for a space of TAG_LENGTH 

void ASCONDecrypt(uint8_t* C, uint8_t* P, int len_p, uint8_t* A, int len_a,
                uint8_t* n, uint8_t* key, uint8_t* T, bool* fail);
//same thing but for P
//modifies fail thanks to the pointer if authentication failed


//initialization functions
uint64_t get_IV(void);//getter for the IV

State_t* state_initialization(uint8_t* textin, int len_p, uint8_t* A,
                            int len_a, uint8_t* n, uint8_t* key, bool plain);
//creates the state with the five words
//and the blocks for the plaintext, ciphertext and associated data

uint8_t** combine(uint8_t* text, int len, bool padding);
//transforms list of uint8_t in list of lists of RATE uint8_t,
//gives the responsability to free the list, adds a padding if padding=true

State_t* initialization(uint8_t* textin, int len_p, uint8_t* A, int len_a,
                        uint8_t* n, uint8_t* key, bool plain);
//creates the state and does the initialization phase, if plain=true encryption
//therefore there will be a padding, otherwise not
//gives responsability to free the state

//processing associated data
void associated_data_process(State_t* state);


//processing plaintext/ciphertext
void plaintext_process(State_t* state, int l);
//l, the length in bytes of the last block in the original text
void ciphertext_process(State_t* state, int l);


//finalization functions
void slice(uint8_t** blocktextout, uint8_t* textout, int len);
//flattens the list of list blocktextout in a list textout
//returns text of length len

void finalization(State_t* state, uint8_t* key, uint8_t* T);

bool same_tag(uint8_t* T,uint8_t* Tprim); //checks T=T'

void free_state(State_t* state);

#endif