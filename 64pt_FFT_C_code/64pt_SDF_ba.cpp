/* Edit only the code below */
// Stage 0 입력 고정
reg_in[0].set(B_I + 1, B_F[0], QMODE);  // 첫 입력: 덧셈 대비 +1 비트

// Stage 0
bf[0][0].set(B_I + 2, B_F[0], QMODE);  // +1 bit MSB
bf[0][1].set(B_I + 2, B_F[0], QMODE);
mult[0].set(B_I + 2, B_F[0], QMODE);
mux_bf[0][2].set(B_I + 2, B_F[0], QMODE);

// Stage 1
reg_in[1].set(B_I + 2, B_F[1], QMODE); // 이전 출력이 곧 입력
bf[1][0].set(B_I + 3, B_F[1], QMODE);
bf[1][1].set(B_I + 3, B_F[1], QMODE);
mult[1].set(B_I + 3, B_F[1], QMODE);
mux_bf[1][2].set(B_I + 3, B_F[1], QMODE);

// Stage 2
reg_in[2].set(B_I + 3, B_F[2], QMODE);
bf[2][0].set(B_I + 4, B_F[2], QMODE);
bf[2][1].set(B_I + 4, B_F[2], QMODE);
mult[2].set(B_I + 4, B_F[2], QMODE);
mux_bf[2][2].set(B_I + 4, B_F[2], QMODE);

// Stage 3
reg_in[3].set(B_I + 4, B_F[3], QMODE);
bf[3][0].set(B_I + 5, B_F[3], QMODE);
bf[3][1].set(B_I + 5, B_F[3], QMODE);
mult[3].set(B_I + 5, B_F[3], QMODE);
mux_bf[3][2].set(B_I + 5, B_F[3], QMODE);

// Stage 4
reg_in[4].set(B_I + 5, B_F[4], QMODE);
bf[4][0].set(B_I + 6, B_F[4], QMODE);
bf[4][1].set(B_I + 6, B_F[4], QMODE);
mult[4].set(B_I + 6, B_F[4], QMODE);
mux_bf[4][2].set(B_I + 6, B_F[4], QMODE);

// Stage 5
reg_in[5].set(B_I + 6, B_F[5], QMODE);
bf[5][0].set(B_I + 7, B_F[5], QMODE);
bf[5][1].set(B_I + 7, B_F[5], QMODE);
mult[5].set(B_I + 7, B_F[5], QMODE);
mux_bf[5][2].set(B_I + 7, B_F[5], QMODE);

// Output registers
for (int i = 0; i < L_FFT; i++) {
	reg_out[0][i].set(B_I + 7, B_F[5], QMODE);  // 최종 출력: 마지막 stage 기준
	reg_out[1][i].set(B_I + 7, B_F[5], QMODE);
}
/* Edit only the code above */
for (int i = 0; i < L_FFT / 2; ++i)
	W[i].set(2, B_F_W, QMODE);

// Reads inputs from file
char str[70];
ifstream file_in_r("FileIO\\in_FFT_r.txt");
ifstream file_in_i("FileIO\\in_FFT_i.txt");
for (int i = 0; i < N_SET; i++)
	for (int j = 0; j < L_FFT; j++)
	{
		file_in_r.getline(str, sizeof(str));
		x[i][j].real = atof(str);
		file_in_i.getline(str, sizeof(str));
		x[i][j].imag = atof(str);
	}
file_in_r.close();
file_in_i.close();
// Reads twiddle factors from file
file_in_r.open("FileIO\\in_W_r.txt");
file_in_i.open("FileIO\\in_W_i.txt");
for (int i = 0; i < L_FFT / 2; i++)
{
	file_in_r.getline(str, sizeof(str));
	W[i].real = atof(str);
	file_in_i.getline(str, sizeof(str));
	W[i].imag = atof(str);
}
file_in_r.close();
file_in_i.close();

// Performs Fast Fourier Transform operations
for (int clk = 0; clk < N_SET * L_FFT + OFFSET; clk++)
{
	//Counter signal assignment
	for (int stage = 0; stage < N_STAGE; stage++)
		cnt[stage] = (reg_cnt + L_FFT - stage) % L_FFT;
	//Output assignment
	sel_out = cnt[N_STAGE - 2];
	if (clk >= OFFSET)
		X[(clk - OFFSET) / L_FFT][(clk - OFFSET) % L_FFT] = reg_out[reg_sel_bank_out][sel_out];

	/* Edit only the code below */
	/***************************************************************/
	// STAGE CONTROLLER (sel_bf / sel_w)
	for (int stage = 0; stage < N_STAGE; stage++) {
		int stage_len = L_FFT >> stage;
		sel_bf[stage] = (cnt[stage] >> (int)log2(stage_len >> 1)) & 1; // 중요 알고리즘
		sel_w[stage] = (cnt[stage] % (L_FFT >> (stage + 1))) << stage;
	}

	// REORDERING CONTROLLER 초기화
	for (int bank = 0; bank < 2; bank++) {
		for (int i = 0; i < L_FFT; i++) {
			en_reg_out[bank][i] = 0;
		}
	}

	// REORDERING CONTROLLER 활성화 인덱스 설정 (마지막 stage 기준)
	int write_bank = !reg_sel_bank_out;
	int sel_idx = 0;
	for (int b = 0; b < N_STAGE; b++) {
		sel_idx |= ((cnt[N_STAGE - 2] >> b) & 1) << (N_STAGE - 1 - b);
	}
	en_reg_out[write_bank][sel_idx] = 1;

	// 각 stage: butterfly 계산, mux 처리, twiddle 곱, 레지스터 갱신
	for (int stage = 0; stage < N_STAGE; stage++) { // 각 stage에 대해 실행
		int reg_depth = L_FFT >> (stage + 1); // 각 stage의 reg 길이

		// Butterfly
		bf[stage][0] = reg_in[stage] + reg[stage][reg_depth - 1];
		bf[stage][1] = reg[stage][reg_depth - 1] - reg_in[stage];

		// mux_bf: butterfly 수행 or bypass
		mux_bf[stage][0] = sel_bf[stage] ? bf[stage][0] : reg[stage][reg_depth - 1];
		mux_bf[stage][1] = sel_bf[stage] ? bf[stage][1] : reg_in[stage];

		// twiddle
		mux_w[stage] = W[sel_w[stage]];
		mult[stage] = mux_bf[stage][0] * mux_w[stage];

		// twiddle 결과 선택 mux
		mux_bf[stage][2] = sel_bf[stage] ? mux_bf[stage][0] : mult[stage];
	}

	// 출력 mux
	mux_out[0] = reg_out[0][sel_out];
	mux_out[1] = reg_out[1][sel_out];
	mux_bank_out = mux_out[reg_sel_bank_out];

	// reg_out 업데이트
	for (int bank = 0; bank < 2; bank++) {
		for (int i = 0; i < L_FFT; i++) {
			if (en_reg_out[bank][i] == 1)
				reg_out[bank][i] = mux_bf[N_STAGE - 1][2]; // 마지막 stage 결과 저장
		}
	}

	// reg[] 및 reg_in[] 순차 이동
	for (int stage = 0; stage < N_STAGE; stage++) {
		int reg_depth = L_FFT >> (stage + 1);
		for (int r = reg_depth - 1; r > 0; r--)
			reg[stage][r] = reg[stage][r - 1];
		reg[stage][0] = mux_bf[stage][1];

		if (stage + 1 < N_STAGE)
			reg_in[stage + 1] = mux_bf[stage][2];
	}
	/* Edit only the code above */
}
