/* Edit only the code below */
// Load input into g[]
for (int j = 0; j < L_FFT; j++)
	g[j] = x[i][j]; // 한 set에 대한 입력을 g버퍼에 복사

// Perform DIF FFT (in-place)
int n = L_FFT; // 64
int half; // half = butterfly 반쪽 크기
int step; // step = twiddle index의 step
for (int stage = 0; stage < N_STAGE; stage++) // 한 set에 대한 동작..모든 stage에 대해 수행..64pt일때 stage = 0,1,2,3,4,5
{
	half = n >> 1; // half = 32,16,8,4,2,1
	step = L_FFT / n; // step = 1,2,4,8,16,32
	for (int j = 0; j < L_FFT; j += n) // 한 stage에 대한 동작.. 
	{
		for (int k = 0; k < half; k++) // 한 section에 대한 동작..
		{
			flt::Complex a = g[j + k];
			flt::Complex b = g[j + k + half];
			g[j + k] = a + b;
			g[j + k + half] = W[k * step] * (a - b);
		}
	}
	n = half;
}

// Bit reversal
for (int j = 0; j < L_FFT; j++)
{
	int rev = 0;
	for (int b = 0; b < N_STAGE; b++)
		rev |= ((j >> b) & 1) << (N_STAGE - 1 - b);
	X[i][rev] = g[j];
}
/* Edit only the code above */