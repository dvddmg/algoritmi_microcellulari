(// ROUTINE OSC CELLULAR AUTOMATA
~automataOSC = Routine({

	var rasp = NetAddr.new(~ip, ~port);

	var pow = [1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1]; // array di partenza

	var regole = [136, 326, 456, 244, 121, 406, 460, 228,       // set di regole interessanti
		150, 146, 124, 494, 148, 126, 403, 170, 214, 200,       // tra cui scegliere
		6017, 7495, 541, 5253, 2088, 8268, 4287, 2087,
		9312, 2664, 2848, 584, 7744, 7495, 2973,7250,
		4355, 5145, 9025, 3373, 3088, 7501, 8993, 9290,
		7332, 8899, 1489, 3920];

	inf.do({

		var size, rReal;

		size = rrand(8, 16);            // n iterazioni randomiche
		rReal = regole.choose;          // scelta regola
		rReal = rReal.asBinaryDigits;   // conversione regola in bit
		pow.scramble;                   // random mix array di partenza

		~celAut = size.collect({        // creazione array bidimensionale Cellular Automata
			pow = pow.collect({
				arg val, id;
				var prev, next, step;

				prev = pow[id-1];
				next = pow[id+1];

				if(prev.isNil) {prev = 0};
				if(next.isNil) {next = 0};

				step = [prev, val, next];
				step = step.convertDigits(2);

				rReal[step]
			})
		});

		size.do({arg i;            // lettura di un livello alla volta dell'array bidimensionale

			var delta, min, max, str, msg;

			min = ~celAut[i].sum/~celAut[i].size;
			max = (~celAut[i].sum/~celAut[i].median)+0.05;
			delta = (i.linexp(i, size, min, max))/[1, 2, 3].choose;

			msg = (~celAut[i]*180);
			str = "";
			msg.size.do{arg i; if(i == 0){str = str ++ msg[i]}{str = str++", "++msg[i]}};

			rasp.sendMsg("/power", str);
			~pcVideo.sendMsg('/power', str);

			delta.wait
		});
	})
})
)
