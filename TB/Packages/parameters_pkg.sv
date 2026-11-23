package parameters_pkg;
  parameter int DATA_WIDTH = 32;
  parameter int ADDR_WIDTH = 16;
  parameter int MEMORY_DEPTH = 1024;
  parameter int MEM_ADDR_WIDTH = 10;

  typedef enum bit {
    WRITE,
    READ
  } operation_t;

endpackage
