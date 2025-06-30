import chipwhisperer as cw
import matplotlib.pyplot as plt
import numpy as np
import random as rd
from tqdm import tqdm
import time

def reset_target(scope):
    scope.io.pdic = 'low'        
    time.sleep(0.05)
    scope.io.pdic = 'high'
    time.sleep(0.05)

def generate_words(start1,start2) :
    words = np.random.randint(0,1<<63,2,dtype=np.uint64)
    
    words[0] = (words[0] & np.uint64(0x7fffffffffffffff)) + (np.uint64(start1)<<np.uint64(63))
    words[1] = (words[1] & np.uint64(0x7fffffffffffffff)) + (np.uint64(start2)<<np.uint64(63))

    words = bytearray(words)
    return words

IV = [0x00,0x00,0x10,0x00,0x80,0x8c,0x00,0x01]

scope = cw.scope()

scope.default_setup()
scope.adc.samples = 2000

target = cw.target(scope)

ktp = cw.ktp.Basic()
"""key, pt = ktp.new_pair()
tag = ktp.next_text()
ad = ktp.next_text()
nonce = generate_nonce()

target.simpleserial_write('k',key)
target.simpleserial_wait_ack()
target.simpleserial_write('a',ad)
target.simpleserial_wait_ack()
target.simpleserial_write('n',nonce)
target.simpleserial_wait_ack()
target.simpleserial_write('t',tag)
target.simpleserial_wait_ack() """

nonces = []
keys = []
traces = []
pts = []
cts = []
tags = []
input_HW3 = ["00001","00101","00100","01111"]

for i in tqdm(range(5000)):

    pt = ktp.next_text()
    tag = ktp.next_text()
    ad = ktp.next_text()

    S0 = rd.choice(input_HW3)
    nonce = generate_words(int(S0[3]),int(S0[4]))
    key = generate_words(int(S0[1]),int(S0[2]))
    target.simpleserial_write('k',key)
    target.simpleserial_wait_ack()
    target.simpleserial_write('n',nonce)
    target.simpleserial_wait_ack()

    target.simpleserial_write('a',ad)
    target.simpleserial_wait_ack()
    target.simpleserial_write('t',tag)
    target.simpleserial_wait_ack()
    target.simpleserial_write('n',nonce)
    target.simpleserial_wait_ack()

    trace = cw.capture_trace(scope,target,pt,key)
    traces.append(trace.wave)
    cts.append(trace.textout)
    pts.append(trace.textin)
    tags.append(tag)
    nonces.append(nonce)
    keys.append(key)

nptraces = np.asarray(traces)
np.save("Mesures_HW3/traces.npy", nptraces)

nppts = np.asarray(pts)
np.save("Mesures_HW3/pts.npy", nppts)

npcts = np.asarray(cts)
np.save("Mesures_HW3/cts.npy", npcts)

npnonces = np.asarray([nonces])
np.save("Mesures_HW3/nonces.npy", npnonces)

nptags = np.asarray(tags)
np.save("Mesures_HW3/tags.npy", nptags)





keys = []
nonces = []
traces = []
pts = []
cts = []
tags = []
input_HW2 = ["01101","01001","01110","00110","01011","00011"]

for i in tqdm(range(5000)):

    pt = ktp.next_text()
    tag = ktp.next_text()
    ad = ktp.next_text()

    S0 = rd.choice(input_HW2)
    nonce = generate_words(int(S0[3]),int(S0[4]))
    key = generate_words(int(S0[1]),int(S0[2]))
    target.simpleserial_write('k',key)
    target.simpleserial_wait_ack()
    target.simpleserial_write('n',nonce)
    target.simpleserial_wait_ack()

    target.simpleserial_write('a',ad)
    target.simpleserial_wait_ack()
    target.simpleserial_write('t',tag)
    target.simpleserial_wait_ack()
    target.simpleserial_write('n',nonce)
    target.simpleserial_wait_ack()

    trace = cw.capture_trace(scope,target,pt, key)
    traces.append(trace.wave)
    cts.append(trace.textout)
    pts.append(trace.textin)
    tags.append(tag)
    nonces.append(nonce)
    keys.append(key)

nptraces = np.asarray(traces)
np.save("Mesures_HW2/traces.npy", nptraces)

nppts = np.asarray(pts)
np.save("Mesures_HW2/pts.npy", nppts)

npcts = np.asarray(cts)
np.save("Mesures_HW2/cts.npy", npcts)

npnonces = np.asarray([nonces])
np.save("Mesures_HW2/nonces.npy", npnonces)

nptags = np.asarray(tags)
np.save("Mesures_HW2/tags.npy", nptags)

plt.plot(traces[0])
plt.show()