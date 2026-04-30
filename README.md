# SDF FFT Accelerator Design

FFT 알고리즘을 streaming dataflow 기반 하드웨어 구조로 변환하여
구현한 프로젝트

<< 저작권 문제로 인해, 코드의 일부만 공개합니다. >>
---

## 개요

본 프로젝트는 64-point FFT 알고리즘을 기반으로
**Sequential algorithm을 hardware-friendly streaming 구조로 변환**하는 것을 목표로 한다.

* DIF FFT 기반 구현 
* Bit-reversal 포함

---

## 구조

### 🔹 알고리즘 → 구조 변환

기존 FFT:

* nested loop 기반
* stage별 반복 연산

→ 변환 후:

* stage pipeline 구조
* streaming 데이터 처리

---

### 🔹 핵심 구조 (SDF)

* Stage별 register chain
* Delay buffer 기반 데이터 정렬
* Butterfly + twiddle 연산 pipeline

---

### 🔹 구성 모듈

#### 1. Stage Module

* Butterfly 연산 수행
* Twiddle factor 적용
* register shift 기반 데이터 흐름

---

#### 2. Controller

* stage별 동작 제어
* `sel_bf`, `sel_w` 생성 

---

#### 3. Reordering Module

* bit-reversal 출력 정렬
* bank 기반 출력 관리

---

## 핵심 특징

### 1. Streaming FFT 구조

* 입력이 들어오면서 stage를 순차 통과
* 전체 데이터 buffering 없이 처리

---

### 2. Delay-based data alignment

* stage별 서로 다른 delay 구조
* butterfly 입력 정렬

---

### 3. Control-driven dataflow

* counter 기반 control signal 생성
* butterfly / twiddle 선택 제어

---

### 4. Fully pipelined execution

* 각 stage가 동시에 동작
* throughput 향상

---

## 특징

* Radix-2 DIF FFT
* In-place 연산 구조
* Bit-reversal output
