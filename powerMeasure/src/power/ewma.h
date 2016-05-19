#ifndef EWMA_H
#define EWMA_H

#define LAMBDA 0.3  // weight of current value (1-LAMBDA for history)
#define WIDTH 10    // history

typedef struct EwmaObj {
  double cur;
  double his;
} EwmaObj;

inline void ewmaVal(EwmaObj* ewma, double cur) {
  ewma->his = ewma->cur;
  ewma->cur = LAMBDA * cur + (1 - LAMBDA) * ewma->his;
};

#endif