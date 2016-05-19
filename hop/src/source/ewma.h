#ifndef EWMA_H
#define EWMA_H

#define WIDTH 10    // history

typedef struct EwmaObj {
  double cur;
  double his;
  double lambda; // weight of current value (1-LAMBDA for history)
} EwmaObj;

inline void ewmaVal(EwmaObj* ewma, double cur) {
  ewma->his = ewma->cur;
  ewma->cur = ewma->lambda * cur + (1 - ewma->lambda) * ewma->his;
};

#endif