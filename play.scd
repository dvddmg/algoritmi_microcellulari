(
"\n——————————————————————————————————————————————————————————
|                                                        |
| AlgoritmiMicroCellulari - 2023                         |
|                                                        |
| per servo motori risonanti e live electronics          |
|                                                        |
|————————————————————————————————————————————————————————|
|                                                        |
|  • 16 servo motori con vasetti di vetro e materiali    |
|  • 1 Raspberry PI4                                     |
|  • 5 altoparlanti (1 in box con ampli)                 |
|  • 1 router                                            |
|  • 6 microfoni a contatto (piezo)                      |
|  • 1 scheda audio (6in - 5out)                         |
|                                                        |
——————————————————————————————————————————————————————————\n".postln;

/*———————————————————————————————————————————————————*\
|SERVER SETTINGS                                      |
\*———————————————————————————————————————————————————*/
Server.killAll;
s.options.device_("Supercollider");
s.options.memSize_(2.pow(21));
s.options.numInputBusChannels_(6);
s.options.numOutputBusChannels_(5);
s.options.sampleRate_("48000");
s.plotTree;
s.meter;

s.waitForBoot{

	"\nSERVER PRONTO\n".postln;

	/*———————————————————————————————————————————————————*\
	|VARIABLI INTERFACCIE                                 |
	\*———————————————————————————————————————————————————*/
	~ip = "127.0.0.2";         // ip pc Python
	~port = 5005;              // porta OSC SC -> PY & Video
	~portPOWER = 9898;         // porta OSC iPhone -> SC
	~nPiezo = 6;               // n piezo
	~numChan = 4;              // n casse
	~outBox = 4;               // uscita mini spiaker
	~pcVideo = NetAddr("127.0.0.1", ~port);
	/*———————————————————————————————————————————————————*\
	|VARIABLI SYNTH                                       |
	\*———————————————————————————————————————————————————*/
	~bufSize = 7;         // grandezza buffers (sec)
	~sogliaEnv = 0.11;    // soglia trig inviluppo grani
	~sogliaFre = 0.07;    // soglia trig gate freeze
	~offsetAmpG = 0.04;   // offset ampiezza minima inviluppo grani
	~trasposizioni = [-12, -9, -5, 4, 8, 12]; // trasposizione grani
	~ampSub = 0.045;       // ampiezza sub synth
	~ampGrn = 0.12;        // ampiezza grani
	~ampFrz = [0.4, 0.8]; // ampiezza minima e massima freeze
	/*———————————————————————————————————————————————————*\
	|GRUPPI, BUS E BUFFER                                 |
	\*———————————————————————————————————————————————————*/
	~sources = Group.new;
	~controller = Group.after(~sources);
	~fx = Group.after(~controller);
	~piezoBus = ~nPiezo.collect{Bus.audio(s, 1)};
	~pointer = Bus.audio(s, 1);
	~revBus = Bus.audio(s, 1);
	Buffer.freeAll;
	~bufs = ~nPiezo.collect{Buffer.alloc(s, s.sampleRate*~bufSize, 1)};

	"SETTINGS FATTI\n".postln;

	/*———————————————————————————————————————————————————*\
	|SYNTHDEFS                                            |
	\*———————————————————————————————————————————————————*/
	"synthDef_algoritmi_micro_cellulari.scd".loadRelative;
	"SYNTHDEF DICHIARATE\n".postln;

	/*———————————————————————————————————————————————————*\
	|CELLULAR AUTOMATA GENERATION ROUTINE (0SC)           |
	\*———————————————————————————————————————————————————*/
	"routine_osc_automata.scd".loadRelative;
	"AUTOMATATA OSC PRONTA\n".postln;

	/*———————————————————————————————————————————————————*\
	|SYNTH PERMANENTI                                     |
	\*———————————————————————————————————————————————————*/
	{
		~input = ~nPiezo.collect({arg i;
			Synth(\piezo,[
				\amp, 1,
				\in, i,
				\outBus, ~piezoBus[i]], ~sources)});

		~ptr = Synth(\point, [\rate, 1,\outBus, ~pointer], ~controller);

		~rec = ~nPiezo.collect({arg i;
			Synth(\recBuf,[
				\inBus, ~piezoBus[i],
				\ptrBus, ~pointer,
				\mix, 0,
				\buf, ~bufs[i]], ~controller, \addToTail)});

		~trigs = ~nPiezo.collect({arg i;
			Synth(\sendTrig,[
				\id, i,
				\inBus, ~piezoBus[i],
				\soglia1, ~sogliaFre,
				\soglia2, ~sogliaEnv], ~controller, \addToTail)});

/*		~rev = Synth(\rev, [
			\inBus, ~revBus,
			\size, 20,
			\time, 3,
			\damp, 0.6,
			\inDamp, 0.3,
			\dry, -90,
			\ear, -12,
			\tail, -6,
			\spread, 50], ~fx, \addToTail);
*/
		"SYNTH CREATI\n".postln;

	}.defer(2);


	/*———————————————————————————————————————————————————*\
	|SYNTH DINAMICI OSC MASTER FUNC                       |
	\*———————————————————————————————————————————————————*/
	{
		OSCFunc({arg i;
			if(i[1] == 1)
			{
				~grani = ~nPiezo.collect({arg i;
					Synth(\grain, [
						\out, 0,
						\buf, ~bufs[i],
						\outBus,0,
						\gdur, rrand(0.05, 0.4),
						\gden, rrand(50, 150),
						\amp, ~ampGrn,
						\trsp, ~trasposizioni[i],
						\envbuf, -1,
						\devR, 1,
						\ptrBus, ~pointer,
						\maxDel, 2,
						\minDel, 0.2,
						\gate, 1,
						\revBus, ~revBus,
						\send, -90.dbamp,
						\tScale, 1,
						\t_gate, 1,], ~fx)});

				~sfondo = Synth(\sub, [
					\freq, 24.midicps,
					\amp, ~ampSub,
					\outBus, 0,
					\gate, 1,
					\fade, 5], ~fx, \addToHead);

				~trigFreeze = OSCdef(\trigIn, {
					arg msg;
					Synth(\freez, [
						\inBus, ~piezoBus[msg[3]],
						\outBus, ~outBox,
						\amp, rrand(~ampFrz[0], ~ampFrz[1]),
						\freeze, 1,], ~fx, \addToHead)}, '/trigF');

				~trigEnvg = OSCdef(\trigIn2, {arg msg;
					var i = msg[3];
					~grani[i].set(\tScale, rrand(0.5, 4), \t_gate, 1)}, '/trigG');

				~automataOSC.reset.play;

				~pcVideo.sendMsg('/master', 1);

				"\nSTART\n".postln

			}{

				~grani.do({arg i; i.set(\gate, 0)});
				~sfondo.set(\gate, 0);
				~trigFreeze.free;
				~trigenvg.free;
				~automataOSC.stop;
				~pcVideo.sendMsg('/master', 0);

				"\nSTOP\n".postln

		}}, "power" , recvPort: ~portPOWER);

		"MASTER OSC ATTIVO\n".postln

	}.defer(3);
};
"========= AVVIO PATCH =========\n"
)
