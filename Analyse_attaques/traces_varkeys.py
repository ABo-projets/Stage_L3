import chipwhisperer as cw
import matplotlib.pyplot as plt
import numpy as np
from tqdm import tqdm
import time

scope = cw.scope()

scope.default_setup()
scope.adc.samples = 2000

target = cw.target(scope)

ktp = cw.ktp.Basic()
key, pt = ktp.new_pair()
nonce = ktp.next_text()
ad = ktp.next_text()

target.simpleserial_write('k',key)
target.simpleserial_wait_ack()
target.simpleserial_write('a',ad)
target.simpleserial_wait_ack()
target.simpleserial_write('n',nonce)
target.simpleserial_wait_ack()

nonces = []
traces = []
pts = []
cts = []
keys =[]

for i in tqdm(range(10000)):

    pt = ktp.next_text()
    if i==5000 :
        key = ktp.next_text()
    nonce = ktp.next_text()
    ad = ktp.next_text()

    target.simpleserial_write('k',key)
    target.simpleserial_wait_ack()
    target.simpleserial_write('a',ad)
    target.simpleserial_wait_ack()
    target.simpleserial_write('n',nonce)
    target.simpleserial_wait_ack()

    trace = cw.capture_trace(scope,target,pt, key)
    traces.append(trace.wave)
    nonces.append(nonce)
    pts.append(trace.textin)
    cts.append(trace.textout)
    keys.append(trace.key)

nptraces = np.asarray(traces)
np.save("Mesures_tousHW/traces.npy", nptraces)

nppts = np.asarray(pts)
np.save("Mesures_tousHW/pts.npy", nppts)

npcts = np.asarray(cts)
np.save("Mesures_tousHW/cts.npy", npcts)

npnonces = np.asarray(nonces)
np.save("Mesures_tousHW/nonces.npy", npnonces)

npkeys = np.asarray(keys)
np.save("Mesures_tousHW/keys.npy", npkeys)

plt.plot(traces[0])
plt.show()