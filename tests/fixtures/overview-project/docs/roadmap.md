# Roadmap

## Now (next 1-3 features)
1. adaptive-dt — фиксированный шаг вдвое дороже на спокойных участках
2. mesh-refine — без измельчения не берём задачи с фронтом

## Next (1-3 features after Now)
- mpi-split — потолок одной машины 2e6 ячеек

## Later (eventually, no commitment)
- gpu-kernel — только после mpi-split

## Explicitly NOT doing (and why)
- implicit-solver — выигрыш только при Cr >> 10, см. analogs #4
