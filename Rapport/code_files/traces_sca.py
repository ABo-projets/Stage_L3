import chipwhisperer as cw
import matplotlib.pyplot as plt
import numpy as np
from tqdm import tqdm
import time

def reset_target(scope):
    scope.io.pdic = 'low'        
    time.sleep(0.05)
    scope.io.pdic = 'high'
    time.sleep(0.05)

def generate_nonce() :
    nonce = np.random.randint(0,high=1<<64-1,size=2)
    nonce[1] = 0
    for i in range(64):
        nonce[1] += ((IV[i//8]>>(i%8))%2)<<i

    nonce = bytearray(nonce)

    return nonce

IV = [0x00,0x00,0x10,0x00,0x80,0x8c,0x00,0x01]

scope = cw.scope()

scope.default_setup()
scope.adc.samples = 2000

target = cw.target(scope)

ktp = cw.ktp.Basic()
key, pt = ktp.new_pair()
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
target.simpleserial_wait_ack()

nonces = []
traces = []
pts = []
cts = []
tags = []

for i in tqdm(range(10000)):

    ct = ktp.next_text()
    tag = ktp.next_text()
    ad = ktp.next_text()

    if True :
        nonce = generate_nonce()

    target.simpleserial_write('a',ad)
    target.simpleserial_wait_ack()
    target.simpleserial_write('t',tag)
    target.simpleserial_wait_ack()
    target.simpleserial_write('n',nonce)
    target.simpleserial_wait_ack()

    trace = cw.capture_trace(scope,target,pt, key)
    traces.append(trace.wave)
    cts.append(trace.textin)
    pts.append(trace.textout)
    tags.append(tag)
    nonces.append(nonce)

nptraces = np.asarray(traces)
np.save("Mesures_hf/traces.npy", nptraces)

nppts = np.asarray(pts)
np.save("Mesures_hf/pts.npy", nppts)

npcts = np.asarray(cts)
np.save("Mesures_hf/cts.npy", npcts)

npnonces = np.asarray([nonces])
np.save("Mesures_hf/nonces.npy", npnonces)

nptags = np.asarray(tags)
np.save("Mesures_hf/tags.npy", nptags)

plt.plot(traces[0])
plt.show()