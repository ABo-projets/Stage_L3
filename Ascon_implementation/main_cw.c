/**
* main for communication with a ChipWhisperer-AE
* @author Alexane Boldo
* @date 11/07/25
*/

#include "ascon.h"
#include "hal/hal.h"
#include "hal/simpleserial.h"
#include <stdint.h>
#include <stdlib.h>

uint8_t key[KEY_LENGTH/BYTE_LENGTH];
uint8_t A[MAX_DATA_SIZE];
uint8_t P[MAX_DATA_SIZE];
uint8_t C[2*MAX_DATA_SIZE];
uint8_t* T = &(C[MAX_DATA_SIZE]);
uint8_t n[NONCE_LENGTH];

uint8_t set_key(uint8_t* k, uint8_t len)
{
    if (len != KEY_LENGTH/BYTE_LENGTH) {
        led_error(1);
        return 0x01;
    }

	for(int i = 0; i < KEY_LENGTH/BYTE_LENGTH; i++) {
        key[i] = k[i];
    }
	return 0x00;
}

uint8_t set_assodata(uint8_t* ad, uint8_t len){
    if (len != MAX_DATA_SIZE) {
        led_error(1);
        return 0x01;
    }

	for(int i = 0; i < MAX_DATA_SIZE; i++) {
        A[i] = ad[i];
    }
	return 0x00;
}

uint8_t set_nonce(uint8_t* nonce, uint8_t len){
    if (len != NONCE_LENGTH/BYTE_LENGTH){
        led_error(1);
        return 0x01;
    }

    for(int i=0; i < NONCE_LENGTH/BYTE_LENGTH; i++){
        n[i] = nonce[i];
    }
    return 0x00;
}

uint8_t set_pt(uint8_t* pt, uint8_t len)
{
    if (len != MAX_DATA_SIZE) {
        led_error(1);
        return 0x01;
    }

    for(int i = 0; i < MAX_DATA_SIZE; i++) {
        P[i] = pt[i];
    }

    /*
    Encrypt here using ciphertext, plaintext, tag, associated data and key variables.
    */
	ASCONEncrypt(C,T,P,len,A,len,n,key);
	
	simpleserial_put('r', 16, C);//sends ciphertext
	return 0x00;
}

int main(void)
{
    platform_init();
    init_uart();
    trigger_setup();

    led_ok(1);
    led_error(0);

    simpleserial_init();
    simpleserial_addcmd('k', 16, set_key);
    simpleserial_addcmd('a', 16, set_assodata);
    simpleserial_addcmd('n', 16,  set_nonce);
    simpleserial_addcmd('p', 16,  set_pt);


    while(1) {
        simpleserial_get();// get next command and react to it
    }
}