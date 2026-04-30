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

// EACH STAGES : butterfly 계산, mux 처리, twiddle 곱, 레지스터 갱신
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