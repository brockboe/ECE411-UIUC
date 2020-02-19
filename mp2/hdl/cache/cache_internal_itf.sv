package cache_internal_itf;

typedef struct packed
{
      logic ld_tag_1;
      logic ld_tag_2;
      logic ld_dirty_1;
      logic dirty_in_1;
      logic ld_dirty_2;
      logic dirty_in_2;
      logic ld_lru;
      logic lru_in;
      logic ld_valid;
      logic [1:0] valid_in;

      logic [1:0] write_en_sel1;
      logic write_sel_1;
      logic [1:0] write_en_sel2;
      logic write_sel_2;

      logic output_sel;
} ctrl_sig;

typedef struct packed
{
      logic [23:0] tag1;
      logic [23:0] tag2;
      logic dirty1;
      logic dirty2;
      logic lru;
      logic [1:0] valid;
      logic [255:0] cacheline_out;
} dpath_out;

typedef enum logic {
      cacheline = 1'b0,
      bus_adaptor = 1'b1
} datain_sel_t;

typedef enum logic [1:0] {
      nowrite = 2'b00,
      writeall = 2'b01,
      cpuwrite = 2'b10
} write_en_sel_t;

typedef enum logic {
      data_way1 = 1'b0,
      data_way2 = 1'b1
} output_sel_t;

endpackage
