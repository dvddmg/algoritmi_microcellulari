(// MIC INPUT
SynthDef(\piezo, {arg in = 0, outBus = 0, amp = 1, freq = 13000, freq2 = 7500;
	var sig, out;
	sig = SoundIn.ar(in, amp.lag(0.02));
	sig = LeakDC.ar(sig, 0.999);
	sig = BRF.ar(sig, freq, 500/freq);
	sig = BRF.ar(sig, freq2, 250/freq2);
	Out.ar(outBus, sig);
}).add;

// PUNTATORE
SynthDef(\point, {arg outBus = 0, rate = 1;
	var sig;
	sig = Phasor.ar(0, rate, 0, SampleRate.ir * ~bufSize);
	Out.ar(outBus, sig);
}).add;

// REGISTRATORE
SynthDef(\recBuf, {arg inBus = 0, ptrBus = 0, buf = 0, mix = 0, delSamp = 48;
	var sigR, sigW, ptrR, ptrW, in;
	ptrR = In.ar(ptrBus);
	ptrW = DelayN.ar(ptrR, delaytime: delSamp/SampleRate.ir);
	sigR = BufRd.ar(1, buf, ptrR);
	in = In.ar(inBus);
	sigW = XFade2.ar(in, sigR, mix);
	BufWr.ar(sigW.lag(0.0001), buf, ptrW)
}).add;

// TRIG OSC
SynthDef(\sendTrig, {arg id = 0, inBus = 0, soglia1 = 0.3, soglia2 = 0.3;
	var trig1, trig2;
	trig1 = Trig1.ar(Changed.ar(In.ar(inBus), soglia1), 0.2);
	trig2 = Trig1.ar(Changed.ar(In.ar(inBus), soglia2), 0.2);
	SendReply.ar(trig1, '/trigF', id);
	SendReply.ar(trig2, '/trigG', id)
}).add;

// GRANULATORE
SynthDef(\grain,{arg outBus = 0, buf = 0,
	gden = 2, gdur = 0.2, trsp = 0,
	amp = 0, envbuf = -1, ptrBus = 0,
	maxDel = 1, devR   = 0.2, minDel = 0.02,
	fadein = 5, fadeout = 5, gate = 0, revBus = 0, send = 0, tScale = 1, t_gate = 0;

	var gfreq, trig, sig, env, pos, dev, dly, maxgdur, inAmpp, envCtl, bpf;

	bpf = Env([~offsetAmpG, 1, 0.5, 0.5, ~offsetAmpG], [0.1, 0.2, 0.6, 0.4], \cub);
	envCtl = EnvGen.kr(bpf, t_gate.lag(Rand(0.01, 1.5)), timeScale: tScale, doneAction: 0);

	devR   = devR   * SampleRate.ir;
	maxDel = maxDel * SampleRate.ir;
	minDel = minDel * SampleRate.ir;

	trig = Dust.ar(gden);

	dev  = LFNoise1.ar(gden).bipolar(devR);
	dly  = max(maxDel - dev, minDel);

	pos = In.ar(ptrBus, 1);
	pos = pos - dly;
	pos = pos / BufFrames.kr(buf);

	maxgdur = dly / trsp.midiratio;
	maxgdur = maxgdur / SampleRate.ir;
	gdur    = min(gdur, maxgdur);

	sig  = GrainBuf.ar(1,
		trig,
		gdur,
		buf,
		LFNoise0.ar(Rand(2.0, 15.0) + envCtl, envCtl + 0.1, trsp.midiratio).abs,
		pos,
		2,
		0,
		envbuf,
		512,
		amp
	);
	env = Linen.kr(gate, fadein, 1, fadeout, doneAction:2);

	sig = sig * env * envCtl;
	Out.ar(revBus, sig * send);

	sig = PanAz.ar(~numChan, sig, LFNoise2.ar(Rand(0.05, 0.4) + envCtl * 2), width: 2);
	Out.ar(outBus, sig)

}).add;

// RIVERBERO
SynthDef(\rev, {arg inBus = 0, outBus = 0,
	size = 50, time = 3, damp = 0, inDamp = 0,
	spread = 15, dry = -90, ear = -90, tail = -90;
	var sig, rev;
	sig = In.ar(inBus, 1);
	rev = GVerb.ar(sig, size, time, damp, inDamp, spread,
		dry.dbamp, ear.dbamp, tail.dbamp, 100);
	Out.ar([0, 1, 2, 3], rev)
}).add;

// SINUSOIDE
SynthDef(\sub, {
	arg freq = 10, amp = 0.1, outBus = 0, gate = 0, send = 0, revBus = 0, fade = 5;
	var sig, env, circ;
	sig = SinOsc.ar(LFNoise2.kr(0.05, 1, freq.lag(2)), LFNoise2.ar(Rand(-1, 1)), mul: amp.lag(2));
	env = Linen.kr(gate, fade, 1, fade, 2);
	sig = sig * env;
	circ = PanAz.ar(~numChan, sig, LFNoise1.kr(Rand(0.01, 0.2)), 1, 3, 0.5);
	Out.ar(outBus, circ);
}).add;

// FREEZE FFT
SynthDef(\freez, {arg inBus = 0, outBus = 0, amp = 0.5, freeze = 0, outRev = 0, send = 0;
	var in, size, chain, env, sig, bpf, freq;
	in = In.ar(inBus);
	chain = FFT(LocalBuf(2048), in, 0.5, 1, 1, 2048);
	chain = PV_MagFreeze(chain, 1);
	bpf = Env([0, 1, 1, 0], [0.01, Rand(0.05, 0.5), 0.1], \cub);
	env   = EnvGen.kr(bpf, Impulse.kr(0), doneAction: 2);
	sig   = IFFT(chain, 1, 2048);
	freq = Rand(500, 5000);
	sig = HPF.ar(sig, freq);
	sig = sig * env * amp;
	Out.ar(outBus, sig);
	Out.ar(outRev, sig * send)
}).add;
)
