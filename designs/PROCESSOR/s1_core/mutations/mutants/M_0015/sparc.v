

module sparc
(
  spc_pcx_req_pq,
  spc_pcx_atom_pq,
  spc_pcx_data_pa,
  spc_sscan_so,
  spc_scanout0,
  spc_scanout1,
  tst_ctu_mbist_done,
  tst_ctu_mbist_fail,
  spc_efc_ifuse_data,
  spc_efc_dfuse_data,
  pcx_spc_grant_px,
  wbm_spc_stall,
  wbm_spc_resume,
  cpx_spc_data_rdy_cx2,
  cpx_spc_data_cx2,
  const_cpuid,
  const_maskid,
  ctu_tck,
  ctu_sscan_se,
  ctu_sscan_snap,
  ctu_sscan_tid,
  ctu_tst_mbist_enable,
  efc_spc_fuse_clk1,
  efc_spc_fuse_clk2,
  efc_spc_ifuse_ashift,
  efc_spc_ifuse_dshift,
  efc_spc_ifuse_data,
  efc_spc_dfuse_ashift,
  efc_spc_dfuse_dshift,
  efc_spc_dfuse_data,
  ctu_tst_macrotest,
  ctu_tst_scan_disable,
  ctu_tst_short_chain,
  global_shift_enable,
  ctu_tst_scanmode,
  spc_scanin0,
  spc_scanin1,
  cluster_cken,
  gclk,
  cmp_grst_l,
  cmp_arst_l,
  ctu_tst_pre_grst_l,
  adbginit_l,
  gdbginit_l
);

  output [4:0] spc_pcx_req_pq;
  output spc_pcx_atom_pq;
  output [124-1:0] spc_pcx_data_pa;
  output spc_sscan_so;
  output spc_scanout0;
  output spc_scanout1;
  output tst_ctu_mbist_done;
  output tst_ctu_mbist_fail;
  output spc_efc_ifuse_data;
  output spc_efc_dfuse_data;
  input [4:0] pcx_spc_grant_px;
  input wbm_spc_stall;
  input wbm_spc_resume;
  input cpx_spc_data_rdy_cx2;
  input [145-1:0] cpx_spc_data_cx2;
  input [3:0] const_cpuid;
  input [7:0] const_maskid;
  input ctu_tck;
  input ctu_sscan_se;
  input ctu_sscan_snap;
  input [3:0] ctu_sscan_tid;
  input ctu_tst_mbist_enable;
  input efc_spc_fuse_clk1;
  input efc_spc_fuse_clk2;
  input efc_spc_ifuse_ashift;
  input efc_spc_ifuse_dshift;
  input efc_spc_ifuse_data;
  input efc_spc_dfuse_ashift;
  input efc_spc_dfuse_dshift;
  input efc_spc_dfuse_data;
  input ctu_tst_macrotest;
  input ctu_tst_scan_disable;
  input ctu_tst_short_chain;
  input global_shift_enable;
  input ctu_tst_scanmode;
  input spc_scanin0;
  input spc_scanin1;
  input cluster_cken;
  input gclk;
  input cmp_grst_l;
  input cmp_arst_l;
  input ctu_tst_pre_grst_l;
  input adbginit_l;
  input gdbginit_l;
  wire [3:0] tlu_dsfsr_flt_vld;
  wire tlu_lsu_int_ld_ill_va_w2;
  wire [9:0] lsu_tlu_ldst_va_m;
  wire [47:0] lsu_ifu_stxa_data;
  wire lsu_tlu_misalign_addr_ldst_atm_m;
  wire [3:0] tlu_ifu_sftint_vld;
  wire [3:0] tlu_hintp_vld;
  wire [3:0] tlu_rerr_vld;
  wire lsu_exu_ldst_miss_g2;
  wire lsu_ifu_ldst_miss_w;
  wire lsu_exu_dfill_vld_g;
  wire [63:0] lsu_exu_dfill_data_g;
  wire [62:0] tlu_sscan_test_data;
  wire lsu_ifu_tlb_data_ue;
  wire lsu_ifu_tlb_tag_ue;
  wire [8:0] ifu_tlu_imm_asi_d;
  wire ifu_lsu_wsr_inst_d;
  wire ifu_exu_wsr_inst_d;
  wire [3:0] tlu_hpstate_enb;wire [3:0] tlu_hpstate_priv;wire [3:0] tlu_hpstate_ibe;
  wire short_scan0_1;
  wire short_scan0_2;
  wire short_scan0_3;
  wire short_scan0_4;
  wire short_scan0_5;
  wire short_scan0_6;
  wire scan0_1;
  wire scan0_2;
  wire scan0_3;
  wire scan0_4;
  wire scan0_5;
  wire scan0_6;
  wire scan0_7;
  wire short_scan1_1;
  wire short_scan1_2;
  wire short_scan1_3;
  wire short_scan1_4;
  wire short_scan1_5;
  wire scan1_1;
  wire scan1_2;
  wire scan1_3;
  wire scan1_4;
  wire scan1_5;
  wire [12:0] lsu_t0_pctxt_state;
  wire [12:0] lsu_t1_pctxt_state;
  wire [12:0] lsu_t2_pctxt_state;
  wire [12:0] lsu_t3_pctxt_state;
  wire [6:0] bist_ctl_reg_in;
  wire [10:0] bist_ctl_reg_out;
  wire bist_ctl_reg_wr_en;
  wire [145-1:0] cpx_spc_data_cx2_buf;
  wire [145-1:0] cpx_spc_data_cx3;
  wire cpx_spc_data_rdy_cx2_buf;
  wire cpx_spc_data_rdy_cx3;
  wire exu_ffu_wsr_inst_e;
  wire [47:0] exu_ifu_brpc_e;
  wire [7:0] exu_ifu_cc_d;
  wire exu_ifu_ecc_ce_m;
  wire exu_ifu_ecc_ue_m;
  wire [7:0] exu_ifu_err_reg_m;
  wire [7:0] exu_ifu_err_synd_m;
  wire exu_ifu_inj_ack;
  wire [3:0] exu_ifu_longop_done_g;
  wire [3:0] exu_ifu_oddwin_s;
  wire exu_ifu_regn_e;
  wire exu_ifu_regz_e;
  wire exu_ifu_spill_e;
  wire exu_ifu_va_oor_m;
  wire [10:3] exu_lsu_early_va_e;
  wire [47:0] exu_lsu_ldst_va_e;
  wire exu_lsu_priority_trap_m;
  wire [63:0] exu_lsu_rs2_data_e;
  wire [63:0] exu_lsu_rs3_data_e;
  wire [7:0] exu_mmu_early_va_e;
  wire exu_mul_input_vld;
  wire [63:0] exu_mul_rs1_data;
  wire [63:0] exu_mul_rs2_data;
  wire [63:0] exu_spu_rs3_data_e;
  wire [7:0] exu_tlu_ccr0_w;
  wire [7:0] exu_tlu_ccr1_w;
  wire [7:0] exu_tlu_ccr2_w;
  wire [7:0] exu_tlu_ccr3_w;
  wire [2:0] exu_tlu_cwp0_w;
  wire [2:0] exu_tlu_cwp1_w;
  wire [2:0] exu_tlu_cwp2_w;
  wire [2:0] exu_tlu_cwp3_w;
  wire exu_tlu_cwp_cmplt;
  wire [1:0] exu_tlu_cwp_cmplt_tid;
  wire exu_tlu_cwp_retry;
  wire exu_tlu_misalign_addr_jmpl_rtn_m;
  wire exu_tlu_spill;
  wire exu_tlu_spill_other;
  wire [1:0] exu_tlu_spill_tid;
  wire [2:0] exu_tlu_spill_wtype;
  wire [8:0] exu_tlu_ttype_m;
  wire exu_tlu_ttype_vld_m;
  wire exu_tlu_va_oor_jl_ret_m;
  wire exu_tlu_va_oor_m;
  wire [63:0] exu_tlu_wsr_data_m;
  wire [63:0] ffu_exu_rsr_data_m;
  wire [3:0] ffu_ifu_cc_vld_w2;
  wire [7:0] ffu_ifu_cc_w2;
  wire ffu_ifu_ecc_ce_w2;
  wire ffu_ifu_ecc_ue_w2;
  wire [5:0] ffu_ifu_err_reg_w2;
  wire [13:0] ffu_ifu_err_synd_w2;
  wire ffu_ifu_fpop_done_w2;
  wire ffu_ifu_fst_ce_w;
  wire ffu_ifu_inj_ack;
  wire ffu_ifu_stallreq;
  wire [1:0] ffu_ifu_tid_w2;
  wire ffu_lsu_blk_st_e;
  wire [5:3] ffu_lsu_blk_st_va_e;
  wire [80:0] ffu_lsu_data;
  wire ffu_lsu_fpop_rq_vld;
  wire ffu_lsu_kill_fst_w;
  wire ffu_tlu_fpu_cmplt;
  wire [1:0] ffu_tlu_fpu_tid;
  wire ffu_tlu_ill_inst_m;
  wire ffu_tlu_trap_ieee754;
  wire ffu_tlu_trap_other;
  wire ffu_tlu_trap_ue;
  wire ifu_exu_addr_mask_d;
  wire [2:0] ifu_exu_aluop_d;
  wire ifu_exu_casa_d;
  wire ifu_exu_dbrinst_d;
  wire ifu_exu_disable_ce_e;
  wire ifu_exu_dontmv_regz0_e;
  wire ifu_exu_dontmv_regz1_e;
  wire [7:0] ifu_exu_ecc_mask;
  wire ifu_exu_enshift_d;
  wire ifu_exu_flushw_e;
  wire ifu_exu_ialign_d;
  wire [31:0] ifu_exu_imm_data_d;
  wire ifu_exu_inj_irferr;
  wire ifu_exu_inst_vld_e;
  wire ifu_exu_inst_vld_w;
  wire ifu_exu_invert_d;
  wire ifu_exu_kill_e;
  wire [4:0] ifu_exu_muldivop_d;
  wire ifu_exu_muls_d;
  wire ifu_exu_nceen_e;
  wire [47:0] ifu_exu_pc_d;
  wire [63:0] ifu_exu_pcver_e;
  wire ifu_exu_range_check_jlret_d;
  wire ifu_exu_range_check_other_d;
  wire [4:0] ifu_exu_rd_d;
  wire ifu_exu_rd_exusr_e;
  wire ifu_exu_rd_ffusr_e;
  wire ifu_exu_rd_ifusr_e;
  wire ifu_exu_ren1_s;
  wire ifu_exu_ren2_s;
  wire ifu_exu_ren3_s;
  wire ifu_exu_restore_d;
  wire ifu_exu_restored_e;
  wire ifu_exu_return_d;
  wire [4:0] ifu_exu_rs1_s;
  wire ifu_exu_rs1_vld_d;
  wire [4:0] ifu_exu_rs2_s;
  wire ifu_exu_rs2_vld_d;
  wire [4:0] ifu_exu_rs3_s;
  wire ifu_exu_rs3e_vld_d;
  wire ifu_exu_rs3o_vld_d;
  wire ifu_exu_save_d;
  wire ifu_exu_saved_e;
  wire ifu_exu_setcc_d;
  wire ifu_exu_sethi_inst_d;
  wire [2:0] ifu_exu_shiftop_d;
  wire ifu_exu_tagop_d;
  wire ifu_exu_tcc_e;
  wire [1:0] ifu_exu_tid_s2;
  wire ifu_exu_ttype_vld_m;
  wire ifu_exu_tv_d;
  wire ifu_exu_use_rsr_e_l;
  wire ifu_exu_usecin_d;
  wire ifu_exu_useimm_d;
  wire ifu_exu_wen_d;
  wire [1:0] ifu_ffu_fcc_num_d;
  wire ifu_ffu_fld_d;
  wire ifu_ffu_fpop1_d;
  wire ifu_ffu_fpop2_d;
  wire [8:0] ifu_ffu_fpopcode_d;
  wire [4:0] ifu_ffu_frd_d;
  wire [4:0] ifu_ffu_frs1_d;
  wire [4:0] ifu_ffu_frs2_d;
  wire ifu_ffu_fst_d;
  wire ifu_ffu_inj_frferr;
  wire ifu_ffu_ldfsr_d;
  wire ifu_ffu_ldst_size_d;
  wire ifu_ffu_ldxfsr_d;
  wire ifu_ffu_mvcnd_m;
  wire ifu_ffu_quad_op_e;
  wire ifu_ffu_stfsr_d;
  wire ifu_ffu_visop_d;
  wire ifu_lsu_alt_space_d;
  wire ifu_lsu_alt_space_e;
  wire ifu_lsu_asi_ack;
  wire ifu_lsu_asi_rd_unc;
  wire ifu_lsu_casa_e;
  wire [2:0] ifu_lsu_destid_s;
  wire [3:0] ifu_lsu_error_inj;
  wire ifu_lsu_fwd_data_vld;
  wire ifu_lsu_fwd_wr_ack;
  wire ifu_lsu_ibuf_busy;
  wire [7:0] ifu_lsu_imm_asi_d;
  wire ifu_lsu_imm_asi_vld_d;
  wire ifu_lsu_inv_clear;
  wire ifu_lsu_ld_inst_e;
  wire ifu_lsu_ldst_dbl_e;
  wire ifu_lsu_ldst_fp_e;
  wire [1:0] ifu_lsu_ldst_size_e;
  wire ifu_lsu_ldstub_e;
  wire ifu_lsu_ldxa_data_vld_w2;
  wire [63:0] ifu_lsu_ldxa_data_w2;
  wire ifu_lsu_ldxa_illgl_va_w2;
  wire [1:0] ifu_lsu_ldxa_tid_w2;
  wire ifu_lsu_memref_d;
  wire [3:0] ifu_lsu_nceen;
  wire [51:0] ifu_lsu_pcxpkt_e;
  wire ifu_lsu_pcxreq_d;
  wire ifu_lsu_pref_inst_e;
  wire [4:0] ifu_lsu_rd_e;
  wire ifu_lsu_sign_ext_e;
  wire ifu_lsu_st_inst_e;
  wire ifu_lsu_swap_e;
  wire [1:0] ifu_lsu_thrid_s;
  wire ifu_mmu_trap_m;
  wire ifu_spu_inst_vld_w;
  wire [3:0] ifu_spu_nceen;
  wire ifu_spu_trap_ack;
  wire ifu_tlu_alt_space_d;
  wire ifu_tlu_done_inst_d;
  wire ifu_tlu_flsh_inst_e;
  wire ifu_tlu_flush_fd2_w;
  wire ifu_tlu_flush_fd3_w;
  wire ifu_tlu_flush_fd_w;
  wire ifu_tlu_flush_m;
  wire ifu_tlu_flush_w;
  wire ifu_tlu_hwint_m;
  wire ifu_tlu_icmiss_e;
  wire ifu_tlu_immu_miss_m;
  wire ifu_tlu_inst_vld_m;
  wire ifu_tlu_inst_vld_m_bf1;
  wire ifu_tlu_inst_vld_w;
  wire ifu_tlu_itlb_done;
  wire [3:0] ifu_tlu_l2imiss;
  wire ifu_tlu_mb_inst_e;
  wire [48:0] ifu_tlu_npc_m;
  wire [48:0] ifu_tlu_pc_m;
  wire ifu_tlu_pc_oor_e;
  wire ifu_tlu_priv_violtn_m;
  wire ifu_tlu_retry_inst_d;
  wire ifu_tlu_rsr_inst_d;
  wire ifu_tlu_rstint_m;
  wire ifu_tlu_sftint_m;
  wire ifu_tlu_sir_inst_m;
  wire [6:0] ifu_tlu_sraddr_d;
  wire [6:0] ifu_tlu_sraddr_d_v2;
  wire [1:0] ifu_tlu_thrid_d;
  wire [1:0] ifu_tlu_thrid_e;
  wire ifu_tlu_trap_m;
  wire [8:0] ifu_tlu_ttype_m;
  wire ifu_tlu_ttype_vld_m;
  wire [7:0] lsu_asi_reg0;
  wire [7:0] lsu_asi_reg1;
  wire [7:0] lsu_asi_reg2;
  wire [7:0] lsu_asi_reg3;
  wire [7:0] lsu_asi_state;
  wire [3:0] lsu_dmmu_sfsr_trp_wr;
  wire [23:0] lsu_dsfsr_din_g;
  wire lsu_exu_flush_pipe_w;
  wire [63:0] lsu_exu_ldxa_data_g;
  wire lsu_exu_ldxa_m;
  wire [4:0] lsu_exu_rd_m;
  wire lsu_exu_st_dtlb_perr_g;
  wire [1:0] lsu_exu_thr_m;
  wire lsu_ffu_ack;
  wire [2:0] lsu_ffu_bld_cnt_w;
  wire lsu_ffu_blk_asi_e;
  wire lsu_ffu_flush_pipe_w;
  wire [63:0] lsu_ffu_ld_data;
  wire lsu_ffu_ld_vld;
  wire lsu_ffu_stb_full0;
  wire lsu_ffu_stb_full1;
  wire lsu_ffu_stb_full2;
  wire lsu_ffu_stb_full3;
  wire [3:0] lsu_ictag_mrgn;
  wire [17:0] lsu_ifu_asi_addr;
  wire lsu_ifu_asi_load;
  wire [7:0] lsu_ifu_asi_state;
  wire [1:0] lsu_ifu_asi_thrid;
  wire lsu_ifu_asi_vld;
  wire [144-1:0] lsu_ifu_cpxpkt_i1;
  wire lsu_ifu_cpxpkt_vld_i1;
  wire lsu_ifu_dc_parity_error_w2;
  wire lsu_ifu_dcache_data_perror;
  wire lsu_ifu_dcache_tag_perror;
  wire lsu_ifu_direct_map_l1;
  wire [47:4] lsu_ifu_err_addr;
  wire [1:0] lsu_ifu_error_tid;
  wire lsu_ifu_flush_pipe_w;
  wire [3:0] lsu_ifu_icache_en;
  wire [3:0] lsu_ifu_inj_ack;
  wire lsu_ifu_io_error;
  wire [3:0] lsu_ifu_itlb_en;
  wire lsu_ifu_l2_corr_error;
  wire lsu_ifu_l2_unc_error;
  wire [11:5] lsu_ifu_ld_icache_index;
  wire [1:0] lsu_ifu_ld_pcxpkt_tid;
  wire lsu_ifu_ld_pcxpkt_vld;
  wire [3:0] lsu_ifu_ldst_cmplt;
  wire lsu_ifu_ldsta_internal_e;
  wire lsu_ifu_pcxpkt_ack_d;
  wire lsu_ifu_stallreq;
  wire [3:0] lsu_ifu_stbcnt0;
  wire [3:0] lsu_ifu_stbcnt1;
  wire [3:0] lsu_ifu_stbcnt2;
  wire [3:0] lsu_ifu_stbcnt3;
  wire lsu_ifu_tlb_data_su;
  wire [7:0] lsu_itlb_mrgn;
  wire [3:0] lsu_mamem_mrgn;
  wire lsu_mmu_defr_trp_taken_g;
  wire lsu_mmu_flush_pipe_w;
  wire [63:0] lsu_mmu_rs3_data_g;
  wire [2:0] lsu_pid_state0;
  wire [2:0] lsu_pid_state1;
  wire [2:0] lsu_pid_state2;
  wire [2:0] lsu_pid_state3;
  wire [7:0] lsu_spu_asi_state_e;
  wire lsu_spu_early_flush_g;
  wire lsu_spu_ldst_ack;
  wire [3:0] lsu_spu_stb_empty;
  wire [1:0] lsu_spu_strm_ack_cmplt;
  wire [15:0] lsu_sscan_data;
  wire [1:0] lsu_tlu_async_tid_w2;
  wire lsu_tlu_async_ttype_vld_w2;
  wire [6:0] lsu_tlu_async_ttype_w2;
  wire [3:0] lsu_tlu_cpx_req;
  wire lsu_tlu_cpx_vld;
  wire lsu_tlu_daccess_excptn_g;
  wire lsu_tlu_daccess_prot_g;
  wire [3:0] lsu_tlu_dcache_miss_w2;
  wire lsu_tlu_defr_trp_taken_g;
  wire lsu_tlu_dmmu_miss_g;
  wire [12:0] lsu_tlu_dside_ctxt_m;
  wire lsu_tlu_dtlb_done;
  wire lsu_tlu_early_flush2_w;
  wire lsu_tlu_early_flush_w;
  wire [17:0] lsu_tlu_intpkt;
  wire [3:0] lsu_tlu_l2_dmiss;
  wire lsu_tlu_nucleus_ctxt_m;
  wire [12:0] lsu_tlu_pctxt_m;
  wire lsu_tlu_pcxpkt_ack;
  wire lsu_tlu_priv_action_g;
  wire [63:0] lsu_tlu_rs3_data_g;
  wire [7:0] lsu_tlu_rsr_data_e;
  wire lsu_tlu_squash_va_oor_m;
  wire [3:0] lsu_tlu_stb_full_w2;
  wire [1:0] lsu_tlu_thrid_d;
  wire [1:0] lsu_tlu_tlb_access_tid_m;
  wire [7:0] lsu_tlu_tlb_asi_state_m;
  wire [47:13] lsu_tlu_tlb_dmp_va_m;
  wire lsu_tlu_tlb_ld_inst_m;
  wire [10:0] lsu_tlu_tlb_ldst_va_m;
  wire lsu_tlu_tlb_st_inst_m;
  wire [2:0] lsu_tlu_tte_pg_sz_g;
  wire [8:0] lsu_tlu_ttype_m2;
  wire lsu_tlu_ttype_vld_m2;
  wire lsu_tlu_wsr_inst_e;
  wire lsu_tlu_wtchpt_trp_g;
  wire mbist_bisi_mode;
  wire [71:0] mbist_dcache_data_in;
  wire mbist_dcache_fail;
  wire [6:0] mbist_dcache_index;
  wire mbist_dcache_read;
  wire [1:0] mbist_dcache_way;
  wire mbist_dcache_word;
  wire mbist_dcache_write;
  wire mbist_done;
  wire mbist_icache_fail;
  wire mbist_loop_mode;
  wire mbist_loop_on_addr;
  wire mbist_start;
  wire mbist_stop_on_fail;
  wire mbist_stop_on_next_fail;
  wire mbist_userdata_mode;
  wire [7:0] mbist_write_data;
  wire mem_bypass;
  wire mem_write_disable;
  wire [63:0] mul_data_out;
  wire mul_exu_ack;
  wire mul_spu_ack;
  wire mul_spu_shf_ack;
  wire mux_drive_disable;
  wire rclk;
  wire se;
  wire sehold;
  wire spc_dbginit_l;
  wire spc_grst_l;
  wire spu_ifu_corr_err_w2;
  wire [39:4] spu_ifu_err_addr_w2;
  wire spu_ifu_int_w2;
  wire spu_ifu_mamem_err_w1;
  wire [1:0] spu_ifu_ttype_tid_w2;
  wire spu_ifu_ttype_vld_w2;
  wire spu_ifu_ttype_w2;
  wire spu_ifu_unc_err_w1;
  wire [123:0] spu_lsu_ldst_pckt;
  wire spu_lsu_ldxa_data_vld_w2;
  wire [63:0] spu_lsu_ldxa_data_w2;
  wire spu_lsu_ldxa_illgl_va_w2;
  wire [1:0] spu_lsu_ldxa_tid_w2;
  wire spu_lsu_stxa_ack;
  wire [1:0] spu_lsu_stxa_ack_tid;
  wire spu_lsu_unc_error_w2;
  wire spu_mul_acc;
  wire spu_mul_areg_rst;
  wire spu_mul_areg_shf;
  wire spu_mul_mulres_lshft;
  wire [63:0] spu_mul_op1_data;
  wire [63:0] spu_mul_op2_data;
  wire spu_mul_req_vld;
  wire testmode_l;
  wire tlu_dtlb_data_rd_g;
  wire tlu_dtlb_dmp_actxt_g;
  wire tlu_dtlb_dmp_all_g;
  wire tlu_dtlb_dmp_nctxt_g;
  wire tlu_dtlb_dmp_pctxt_g;
  wire tlu_dtlb_dmp_sctxt_g;
  wire tlu_dtlb_dmp_vld_g;
  wire tlu_dtlb_invalidate_all_g;
  wire [5:0] tlu_dtlb_rw_index_g;
  wire tlu_dtlb_rw_index_vld_g;
  wire tlu_dtlb_tag_rd_g;
  wire [42:0] tlu_dtlb_tte_data_w2;
  wire [58:0] tlu_dtlb_tte_tag_w2;
  wire tlu_early_flush_pipe2_w;
  wire tlu_early_flush_pipe_w;
  wire [2-1:0] tlu_exu_agp;
  wire tlu_exu_agp_swap;
  wire [1:0] tlu_exu_agp_tid;
  wire [7:0] tlu_exu_ccr_m;
  wire [2:0] tlu_exu_cwp_m;
  wire tlu_exu_cwp_retry_m;
  wire tlu_exu_cwpccr_update_m;
  wire tlu_exu_early_flush_pipe_w;
  wire tlu_exu_pic_onebelow_m;
  wire tlu_exu_pic_twobelow_m;
  wire tlu_exu_priv_trap_m;
  wire [64-1:0] tlu_exu_rsr_data_m;
  wire [40:0] tlu_idtlb_dmp_key_g;
  wire [1:0] tlu_idtlb_dmp_thrid_g;
  wire [3:0] tlu_ifu_hwint_i3;
  wire tlu_ifu_nukeint_i2;
  wire [3:0] tlu_ifu_pstate_ie;
  wire [3:0] tlu_ifu_pstate_pef;
  wire tlu_ifu_resumint_i2;
  wire tlu_ifu_rstint_i2;
  wire [3:0] tlu_ifu_rstthr_i2;
  wire [1:0] tlu_ifu_trap_tid_w1;
  wire tlu_ifu_trapnpc_vld_w1;
  wire [48:0] tlu_ifu_trapnpc_w2;
  wire tlu_ifu_trappc_vld_w1;
  wire [48:0] tlu_ifu_trappc_w2;
  wire tlu_itlb_data_rd_g;
  wire tlu_itlb_dmp_actxt_g;
  wire tlu_itlb_dmp_all_g;
  wire tlu_itlb_dmp_nctxt_g;
  wire tlu_itlb_dmp_vld_g;
  wire tlu_itlb_invalidate_all_g;
  wire [5:0] tlu_itlb_rw_index_g;
  wire tlu_itlb_rw_index_vld_g;
  wire tlu_itlb_tag_rd_g;
  wire [42:0] tlu_itlb_tte_data_w2;
  wire [58:0] tlu_itlb_tte_tag_w2;
  wire tlu_itlb_wr_vld_g;
  wire [7:0] tlu_lsu_asi_m;
  wire tlu_lsu_asi_update_m;
  wire [63:0] tlu_lsu_int_ldxa_data_w2;
  wire tlu_lsu_int_ldxa_vld_w2;
  wire tlu_lsu_ldxa_async_data_vld;
  wire [1:0] tlu_lsu_ldxa_tid_w2;
  wire [25:0] tlu_lsu_pcxpkt;
  wire tlu_lsu_priv_trap_m;
  wire [3:0] tlu_lsu_pstate_am;
  wire [3:0] tlu_lsu_pstate_cle;
  wire [3:0] tlu_lsu_pstate_priv;
  wire [3:0] tlu_lsu_redmode;
  wire [3:0] tlu_lsu_redmode_rst_d1;
  wire tlu_lsu_stxa_ack;
  wire [1:0] tlu_lsu_stxa_ack_tid;
  wire [1:0] tlu_lsu_tid_m;
  wire [4-1:0] tlu_lsu_tl_zero;
  wire cpx_spc_data_cx3_b0;
  wire cpx_spc_data_cx3_b100;
  wire cpx_spc_data_cx3_b103;
  wire cpx_spc_data_cx3_b106;
  wire cpx_spc_data_cx3_b109;
  wire cpx_spc_data_cx3_b12;
  wire [120:118] cpx_spc_data_cx3_b120to118;
  wire [145-1:140] cpx_spc_data_cx3_b144to140;
  wire cpx_spc_data_cx3_b16;
  wire cpx_spc_data_cx3_b20;
  wire cpx_spc_data_cx3_b24;
  wire cpx_spc_data_cx3_b28;
  wire cpx_spc_data_cx3_b32;
  wire cpx_spc_data_cx3_b35;
  wire cpx_spc_data_cx3_b38;
  wire cpx_spc_data_cx3_b4;
  wire cpx_spc_data_cx3_b41;
  wire cpx_spc_data_cx3_b44;
  wire cpx_spc_data_cx3_b47;
  wire cpx_spc_data_cx3_b50;
  wire cpx_spc_data_cx3_b53;
  wire cpx_spc_data_cx3_b56;
  wire cpx_spc_data_cx3_b60;
  wire cpx_spc_data_cx3_b64;
  wire cpx_spc_data_cx3_b68;
  wire cpx_spc_data_cx3_b72;
  wire cpx_spc_data_cx3_b76;
  wire cpx_spc_data_cx3_b8;
  wire cpx_spc_data_cx3_b80;
  wire cpx_spc_data_cx3_b84;
  wire cpx_spc_data_cx3_b88;
  wire cpx_spc_data_cx3_b91;
  wire cpx_spc_data_cx3_b94;
  wire cpx_spc_data_cx3_b97;
  wire lsu_ffu_st_dtlb_perr_g;
  wire spu_tlu_rsrv_illgl_m;

  cpx_spc_buf
  buf_cpx
  (
    .cpx_spc_data_cx2_buf(cpx_spc_data_cx2_buf[145-1:0]),
    .cpx_spc_data_rdy_cx2_buf(cpx_spc_data_rdy_cx2_buf),
    .cpx_spc_data_cx2(cpx_spc_data_cx2[145-1:0]),
    .cpx_spc_data_rdy_cx2(cpx_spc_data_rdy_cx2)
  );


  cpx_spc_rpt
  ff_cpx
  (
    .cpx_spc_data_cx3_b144to140(cpx_spc_data_cx3_b144to140[145-1:140]),
    .cpx_spc_data_cx3_b120to118(cpx_spc_data_cx3_b120to118[120:118]),
    .cpx_spc_data_cx3_b0(cpx_spc_data_cx3_b0),
    .cpx_spc_data_cx3_b4(cpx_spc_data_cx3_b4),
    .cpx_spc_data_cx3_b8(cpx_spc_data_cx3_b8),
    .cpx_spc_data_cx3_b12(cpx_spc_data_cx3_b12),
    .cpx_spc_data_cx3_b16(cpx_spc_data_cx3_b16),
    .cpx_spc_data_cx3_b20(cpx_spc_data_cx3_b20),
    .cpx_spc_data_cx3_b24(cpx_spc_data_cx3_b24),
    .cpx_spc_data_cx3_b28(cpx_spc_data_cx3_b28),
    .cpx_spc_data_cx3_b32(cpx_spc_data_cx3_b32),
    .cpx_spc_data_cx3_b35(cpx_spc_data_cx3_b35),
    .cpx_spc_data_cx3_b38(cpx_spc_data_cx3_b38),
    .cpx_spc_data_cx3_b41(cpx_spc_data_cx3_b41),
    .cpx_spc_data_cx3_b44(cpx_spc_data_cx3_b44),
    .cpx_spc_data_cx3_b47(cpx_spc_data_cx3_b47),
    .cpx_spc_data_cx3_b50(cpx_spc_data_cx3_b50),
    .cpx_spc_data_cx3_b53(cpx_spc_data_cx3_b53),
    .cpx_spc_data_cx3_b56(cpx_spc_data_cx3_b56),
    .cpx_spc_data_cx3_b60(cpx_spc_data_cx3_b60),
    .cpx_spc_data_cx3_b64(cpx_spc_data_cx3_b64),
    .cpx_spc_data_cx3_b68(cpx_spc_data_cx3_b68),
    .cpx_spc_data_cx3_b72(cpx_spc_data_cx3_b72),
    .cpx_spc_data_cx3_b76(cpx_spc_data_cx3_b76),
    .cpx_spc_data_cx3_b80(cpx_spc_data_cx3_b80),
    .cpx_spc_data_cx3_b84(cpx_spc_data_cx3_b84),
    .cpx_spc_data_cx3_b88(cpx_spc_data_cx3_b88),
    .cpx_spc_data_cx3_b91(cpx_spc_data_cx3_b91),
    .cpx_spc_data_cx3_b94(cpx_spc_data_cx3_b94),
    .cpx_spc_data_cx3_b97(cpx_spc_data_cx3_b97),
    .cpx_spc_data_cx3_b100(cpx_spc_data_cx3_b100),
    .cpx_spc_data_cx3_b103(cpx_spc_data_cx3_b103),
    .cpx_spc_data_cx3_b106(cpx_spc_data_cx3_b106),
    .cpx_spc_data_cx3_b109(cpx_spc_data_cx3_b109),
    .so(scan0_1),
    .cpx_spc_data_cx3(cpx_spc_data_cx3[145-1:0]),
    .cpx_spc_data_rdy_cx3(cpx_spc_data_rdy_cx3),
    .rclk(rclk),
    .si(short_scan0_6),
    .se(se),
    .cpx_spc_data_cx2(cpx_spc_data_cx2_buf[145-1:0]),
    .cpx_spc_data_rdy_cx2(cpx_spc_data_rdy_cx2_buf)
  );


  sparc_ifu
  ifu
  (
    .wbm_spc_stall(wbm_spc_stall),
    .wbm_spc_resume(wbm_spc_resume),
    .short_si0(spc_scanin0),
    .short_si1(spc_scanin1),
    .short_so0(short_scan0_1),
    .short_so1(short_scan1_1),
    .si0(scan0_1),
    .so0(scan0_2),
    .grst_l(spc_grst_l),
    .arst_l(cmp_arst_l),
    .gdbginit_l(spc_dbginit_l),
    .lsu_ifu_quad_asi_e(1'b0),
    .lsu_ifu_addr_real_l(lsu_ifu_itlb_en[3:0]),
    .lsu_ifu_dtlb_data_ue(lsu_ifu_tlb_data_ue),
    .lsu_ifu_dtlb_tag_ue(lsu_ifu_tlb_tag_ue),
    .lsu_ifu_dtlb_data_su(lsu_ifu_tlb_data_su),
    .tlu_ifu_hintp_vld(tlu_hintp_vld[3:0]),
    .tlu_ifu_rerr_vld(tlu_rerr_vld[3:0]),
    .lsu_ifu_t0_tlz(tlu_lsu_tl_zero[0]),
    .lsu_ifu_t1_tlz(tlu_lsu_tl_zero[1]),
    .lsu_ifu_t2_tlz(tlu_lsu_tl_zero[2]),
    .lsu_ifu_t3_tlz(tlu_lsu_tl_zero[3]),
    .lsu_ifu_ldst_miss_g(lsu_ifu_ldst_miss_w),
    .tlu_ifu_flush_pipe_w(lsu_ifu_flush_pipe_w),
    .lsu_idtlb_mrgn(lsu_itlb_mrgn[7:0]),
    .mbist_loop_on_address(mbist_loop_on_addr),
    .tlu_sscan_data(tlu_sscan_test_data[62:0]),
    .sparc_sscan_so(spc_sscan_so),
    .ifu_tlu_imm_asi_d(ifu_tlu_imm_asi_d[8:0]),
    .lsu_ifu_cpxpkt_i1({ lsu_ifu_cpxpkt_vld_i1, lsu_ifu_cpxpkt_i1[144-1:0] }),
    .ifu_exu_addr_mask_d(ifu_exu_addr_mask_d),
    .ifu_tlu_inst_vld_w(ifu_tlu_inst_vld_w),
    .ifu_tlu_flush_w(ifu_tlu_flush_w),
    .ifu_lsu_alt_space_e(ifu_lsu_alt_space_e),
    .ifu_tlu_ttype_vld_m(ifu_tlu_ttype_vld_m),
    .ifu_exu_muldivop_d(ifu_exu_muldivop_d[4:0]),
    .ifu_lsu_thrid_s(ifu_lsu_thrid_s[1:0]),
    .mbist_write_data(mbist_write_data[7:0]),
    .ifu_exu_aluop_d(ifu_exu_aluop_d[2:0]),
    .ifu_exu_casa_d(ifu_exu_casa_d),
    .ifu_exu_dbrinst_d(ifu_exu_dbrinst_d),
    .ifu_exu_disable_ce_e(ifu_exu_disable_ce_e),
    .ifu_exu_dontmv_regz0_e(ifu_exu_dontmv_regz0_e),
    .ifu_exu_dontmv_regz1_e(ifu_exu_dontmv_regz1_e),
    .ifu_exu_ecc_mask(ifu_exu_ecc_mask[7:0]),
    .ifu_exu_enshift_d(ifu_exu_enshift_d),
    .ifu_exu_flushw_e(ifu_exu_flushw_e),
    .ifu_exu_ialign_d(ifu_exu_ialign_d),
    .ifu_exu_imm_data_d(ifu_exu_imm_data_d[31:0]),
    .ifu_exu_inj_irferr(ifu_exu_inj_irferr),
    .ifu_exu_inst_vld_e(ifu_exu_inst_vld_e),
    .ifu_exu_inst_vld_w(ifu_exu_inst_vld_w),
    .ifu_exu_invert_d(ifu_exu_invert_d),
    .ifu_exu_kill_e(ifu_exu_kill_e),
    .ifu_exu_muls_d(ifu_exu_muls_d),
    .ifu_exu_nceen_e(ifu_exu_nceen_e),
    .ifu_exu_pc_d(ifu_exu_pc_d[47:0]),
    .ifu_exu_pcver_e(ifu_exu_pcver_e[63:0]),
    .ifu_exu_range_check_jlret_d(ifu_exu_range_check_jlret_d),
    .ifu_exu_range_check_other_d(ifu_exu_range_check_other_d),
    .ifu_exu_rd_d(ifu_exu_rd_d[4:0]),
    .ifu_exu_rd_exusr_e(ifu_exu_rd_exusr_e),
    .ifu_exu_rd_ffusr_e(ifu_exu_rd_ffusr_e),
    .ifu_exu_rd_ifusr_e(ifu_exu_rd_ifusr_e),
    .ifu_exu_ren1_s(ifu_exu_ren1_s),
    .ifu_exu_ren2_s(ifu_exu_ren2_s),
    .ifu_exu_ren3_s(ifu_exu_ren3_s),
    .ifu_exu_restore_d(ifu_exu_restore_d),
    .ifu_exu_restored_e(ifu_exu_restored_e),
    .ifu_exu_return_d(ifu_exu_return_d),
    .ifu_exu_rs1_s(ifu_exu_rs1_s[4:0]),
    .ifu_exu_rs1_vld_d(ifu_exu_rs1_vld_d),
    .ifu_exu_rs2_s(ifu_exu_rs2_s[4:0]),
    .ifu_exu_rs2_vld_d(ifu_exu_rs2_vld_d),
    .ifu_exu_rs3_s(ifu_exu_rs3_s[4:0]),
    .ifu_exu_rs3e_vld_d(ifu_exu_rs3e_vld_d),
    .ifu_exu_rs3o_vld_d(ifu_exu_rs3o_vld_d),
    .ifu_exu_save_d(ifu_exu_save_d),
    .ifu_exu_saved_e(ifu_exu_saved_e),
    .ifu_exu_setcc_d(ifu_exu_setcc_d),
    .ifu_exu_sethi_inst_d(ifu_exu_sethi_inst_d),
    .ifu_exu_shiftop_d(ifu_exu_shiftop_d[2:0]),
    .ifu_exu_tagop_d(ifu_exu_tagop_d),
    .ifu_exu_tcc_e(ifu_exu_tcc_e),
    .ifu_exu_tid_s2(ifu_exu_tid_s2[1:0]),
    .ifu_exu_ttype_vld_m(ifu_exu_ttype_vld_m),
    .ifu_exu_tv_d(ifu_exu_tv_d),
    .ifu_exu_use_rsr_e_l(ifu_exu_use_rsr_e_l),
    .ifu_exu_usecin_d(ifu_exu_usecin_d),
    .ifu_exu_useimm_d(ifu_exu_useimm_d),
    .ifu_exu_wen_d(ifu_exu_wen_d),
    .ifu_exu_wsr_inst_d(ifu_exu_wsr_inst_d),
    .ifu_ffu_fcc_num_d(ifu_ffu_fcc_num_d[1:0]),
    .ifu_ffu_fld_d(ifu_ffu_fld_d),
    .ifu_ffu_fpop1_d(ifu_ffu_fpop1_d),
    .ifu_ffu_fpop2_d(ifu_ffu_fpop2_d),
    .ifu_ffu_fpopcode_d(ifu_ffu_fpopcode_d[8:0]),
    .ifu_ffu_frd_d(ifu_ffu_frd_d[4:0]),
    .ifu_ffu_frs1_d(ifu_ffu_frs1_d[4:0]),
    .ifu_ffu_frs2_d(ifu_ffu_frs2_d[4:0]),
    .ifu_ffu_fst_d(ifu_ffu_fst_d),
    .ifu_ffu_inj_frferr(ifu_ffu_inj_frferr),
    .ifu_ffu_ldfsr_d(ifu_ffu_ldfsr_d),
    .ifu_ffu_ldst_size_d(ifu_ffu_ldst_size_d),
    .ifu_ffu_ldxfsr_d(ifu_ffu_ldxfsr_d),
    .ifu_ffu_mvcnd_m(ifu_ffu_mvcnd_m),
    .ifu_ffu_quad_op_e(ifu_ffu_quad_op_e),
    .ifu_ffu_stfsr_d(ifu_ffu_stfsr_d),
    .ifu_ffu_visop_d(ifu_ffu_visop_d),
    .ifu_lsu_alt_space_d(ifu_lsu_alt_space_d),
    .ifu_lsu_asi_ack(ifu_lsu_asi_ack),
    .ifu_lsu_asi_rd_unc(ifu_lsu_asi_rd_unc),
    .ifu_lsu_casa_e(ifu_lsu_casa_e),
    .ifu_lsu_destid_s(ifu_lsu_destid_s[2:0]),
    .ifu_lsu_error_inj(ifu_lsu_error_inj[3:0]),
    .ifu_lsu_fwd_data_vld(ifu_lsu_fwd_data_vld),
    .ifu_lsu_fwd_wr_ack(ifu_lsu_fwd_wr_ack),
    .ifu_lsu_ibuf_busy(ifu_lsu_ibuf_busy),
    .ifu_lsu_imm_asi_d(ifu_lsu_imm_asi_d[7:0]),
    .ifu_lsu_imm_asi_vld_d(ifu_lsu_imm_asi_vld_d),
    .ifu_lsu_inv_clear(ifu_lsu_inv_clear),
    .ifu_lsu_ld_inst_e(ifu_lsu_ld_inst_e),
    .ifu_lsu_ldst_dbl_e(ifu_lsu_ldst_dbl_e),
    .ifu_lsu_ldst_fp_e(ifu_lsu_ldst_fp_e),
    .ifu_lsu_ldst_size_e(ifu_lsu_ldst_size_e[1:0]),
    .ifu_lsu_ldstub_e(ifu_lsu_ldstub_e),
    .ifu_lsu_ldxa_data_vld_w2(ifu_lsu_ldxa_data_vld_w2),
    .ifu_lsu_ldxa_data_w2(ifu_lsu_ldxa_data_w2[63:0]),
    .ifu_lsu_ldxa_illgl_va_w2(ifu_lsu_ldxa_illgl_va_w2),
    .ifu_lsu_ldxa_tid_w2(ifu_lsu_ldxa_tid_w2[1:0]),
    .ifu_lsu_memref_d(ifu_lsu_memref_d),
    .ifu_lsu_nceen(ifu_lsu_nceen[3:0]),
    .ifu_lsu_pcxpkt_e(ifu_lsu_pcxpkt_e[51:0]),
    .ifu_lsu_pcxreq_d(ifu_lsu_pcxreq_d),
    .ifu_lsu_pref_inst_e(ifu_lsu_pref_inst_e),
    .ifu_lsu_rd_e(ifu_lsu_rd_e[4:0]),
    .ifu_lsu_sign_ext_e(ifu_lsu_sign_ext_e),
    .ifu_lsu_st_inst_e(ifu_lsu_st_inst_e),
    .ifu_lsu_swap_e(ifu_lsu_swap_e),
    .ifu_lsu_wsr_inst_d(ifu_lsu_wsr_inst_d),
    .ifu_mmu_trap_m(ifu_mmu_trap_m),
    .ifu_spu_inst_vld_w(),
    .ifu_spu_nceen(),
    .ifu_spu_trap_ack(),
    .ifu_tlu_alt_space_d(ifu_tlu_alt_space_d),
    .ifu_tlu_done_inst_d(ifu_tlu_done_inst_d),
    .ifu_tlu_flsh_inst_e(ifu_tlu_flsh_inst_e),
    .ifu_tlu_flush_m(ifu_tlu_flush_m),
    .ifu_tlu_hwint_m(ifu_tlu_hwint_m),
    .ifu_tlu_icmiss_e(ifu_tlu_icmiss_e),
    .ifu_tlu_immu_miss_m(ifu_tlu_immu_miss_m),
    .ifu_tlu_inst_vld_m(ifu_tlu_inst_vld_m),
    .ifu_tlu_itlb_done(ifu_tlu_itlb_done),
    .ifu_tlu_l2imiss(ifu_tlu_l2imiss[3:0]),
    .ifu_tlu_mb_inst_e(ifu_tlu_mb_inst_e),
    .ifu_tlu_npc_m(ifu_tlu_npc_m[48:0]),
    .ifu_tlu_pc_m(ifu_tlu_pc_m[48:0]),
    .ifu_tlu_pc_oor_e(ifu_tlu_pc_oor_e),
    .ifu_tlu_priv_violtn_m(ifu_tlu_priv_violtn_m),
    .ifu_tlu_retry_inst_d(ifu_tlu_retry_inst_d),
    .ifu_tlu_rsr_inst_d(ifu_tlu_rsr_inst_d),
    .ifu_tlu_rstint_m(ifu_tlu_rstint_m),
    .ifu_tlu_sftint_m(ifu_tlu_sftint_m),
    .ifu_tlu_sir_inst_m(ifu_tlu_sir_inst_m),
    .ifu_tlu_sraddr_d(ifu_tlu_sraddr_d[6:0]),
    .ifu_tlu_sraddr_d_v2(ifu_tlu_sraddr_d_v2[6:0]),
    .ifu_tlu_thrid_d(ifu_tlu_thrid_d[1:0]),
    .ifu_tlu_thrid_e(ifu_tlu_thrid_e[1:0]),
    .ifu_tlu_trap_m(ifu_tlu_trap_m),
    .ifu_tlu_ttype_m(ifu_tlu_ttype_m[8:0]),
    .mbist_dcache_fail(mbist_dcache_fail),
    .mbist_dcache_index(mbist_dcache_index[6:0]),
    .mbist_dcache_read(mbist_dcache_read),
    .mbist_dcache_way(mbist_dcache_way[1:0]),
    .mbist_dcache_word(mbist_dcache_word),
    .mbist_dcache_write(mbist_dcache_write),
    .mbist_done(mbist_done),
    .mbist_icache_fail(mbist_icache_fail),
    .spc_efc_ifuse_data(spc_efc_ifuse_data),
    .mem_write_disable(mem_write_disable),
    .mux_drive_disable(mux_drive_disable),
    .exu_tlu_wsr_data_m(exu_tlu_wsr_data_m[2:0]),
    .lsu_ictag_mrgn(lsu_ictag_mrgn[3:0]),
    .tlu_itlb_tte_tag_w2(tlu_itlb_tte_tag_w2[58:0]),
    .tlu_itlb_tte_data_w2(tlu_itlb_tte_data_w2[42:0]),
    .tlu_itlb_rw_index_vld_g(tlu_itlb_rw_index_vld_g),
    .tlu_itlb_rw_index_g(tlu_itlb_rw_index_g[5:0]),
    .tlu_idtlb_dmp_key_g(tlu_idtlb_dmp_key_g[40:0]),
    .tlu_itlb_dmp_all_g(tlu_itlb_dmp_all_g),
    .lsu_sscan_data(lsu_sscan_data[15:0]),
    .const_cpuid(const_cpuid[3:0]),
    .const_maskid(const_maskid[7:0]),
    .ctu_sscan_se(ctu_sscan_se),
    .ctu_sscan_snap(ctu_sscan_snap),
    .ctu_sscan_tid(ctu_sscan_tid[3:0]),
    .ctu_tck(ctu_tck),
    .efc_spc_fuse_clk1(efc_spc_fuse_clk1),
    .efc_spc_fuse_clk2(efc_spc_fuse_clk2),
    .efc_spc_ifuse_ashift(efc_spc_ifuse_ashift),
    .efc_spc_ifuse_data(efc_spc_ifuse_data),
    .efc_spc_ifuse_dshift(efc_spc_ifuse_dshift),
    .exu_ifu_brpc_e(exu_ifu_brpc_e[47:0]),
    .exu_ifu_cc_d(exu_ifu_cc_d[7:0]),
    .exu_ifu_ecc_ce_m(exu_ifu_ecc_ce_m),
    .exu_ifu_ecc_ue_m(exu_ifu_ecc_ue_m),
    .exu_ifu_err_reg_m(exu_ifu_err_reg_m[7:0]),
    .exu_ifu_err_synd_m(exu_ifu_err_synd_m[7:0]),
    .exu_ifu_inj_ack(exu_ifu_inj_ack),
    .exu_ifu_longop_done_g(exu_ifu_longop_done_g[3:0]),
    .exu_ifu_oddwin_s(exu_ifu_oddwin_s[3:0]),
    .exu_ifu_regn_e(exu_ifu_regn_e),
    .exu_ifu_regz_e(exu_ifu_regz_e),
    .exu_ifu_spill_e(exu_ifu_spill_e),
    .exu_ifu_va_oor_m(exu_ifu_va_oor_m),
    .ffu_ifu_cc_vld_w2(ffu_ifu_cc_vld_w2[3:0]),
    .ffu_ifu_cc_w2(ffu_ifu_cc_w2[7:0]),
    .ffu_ifu_ecc_ce_w2(ffu_ifu_ecc_ce_w2),
    .ffu_ifu_ecc_ue_w2(ffu_ifu_ecc_ue_w2),
    .ffu_ifu_err_reg_w2(ffu_ifu_err_reg_w2[5:0]),
    .ffu_ifu_err_synd_w2(ffu_ifu_err_synd_w2[13:0]),
    .ffu_ifu_fpop_done_w2(ffu_ifu_fpop_done_w2),
    .ffu_ifu_fst_ce_w(ffu_ifu_fst_ce_w),
    .ffu_ifu_inj_ack(ffu_ifu_inj_ack),
    .ffu_ifu_stallreq(ffu_ifu_stallreq),
    .ffu_ifu_tid_w2(ffu_ifu_tid_w2[1:0]),
    .lsu_ifu_asi_addr(lsu_ifu_asi_addr[17:0]),
    .lsu_ifu_asi_load(lsu_ifu_asi_load),
    .lsu_ifu_asi_state(lsu_ifu_asi_state[7:0]),
    .lsu_ifu_asi_thrid(lsu_ifu_asi_thrid[1:0]),
    .lsu_ifu_asi_vld(lsu_ifu_asi_vld),
    .lsu_ifu_dc_parity_error_w2(lsu_ifu_dc_parity_error_w2),
    .lsu_ifu_dcache_data_perror(lsu_ifu_dcache_data_perror),
    .lsu_ifu_dcache_tag_perror(lsu_ifu_dcache_tag_perror),
    .lsu_ifu_direct_map_l1(lsu_ifu_direct_map_l1),
    .lsu_ifu_err_addr(lsu_ifu_err_addr[47:4]),
    .lsu_ifu_error_tid(lsu_ifu_error_tid[1:0]),
    .lsu_ifu_icache_en(lsu_ifu_icache_en[3:0]),
    .lsu_ifu_inj_ack(lsu_ifu_inj_ack[3:0]),
    .lsu_ifu_io_error(lsu_ifu_io_error),
    .lsu_ifu_l2_corr_error(lsu_ifu_l2_corr_error),
    .lsu_ifu_l2_unc_error(lsu_ifu_l2_unc_error),
    .lsu_ifu_ld_icache_index(lsu_ifu_ld_icache_index[11:5]),
    .lsu_ifu_ld_pcxpkt_tid(lsu_ifu_ld_pcxpkt_tid[1:0]),
    .lsu_ifu_ld_pcxpkt_vld(lsu_ifu_ld_pcxpkt_vld),
    .lsu_ifu_ldst_cmplt(lsu_ifu_ldst_cmplt[3:0]),
    .lsu_ifu_ldsta_internal_e(lsu_ifu_ldsta_internal_e),
    .lsu_ifu_pcxpkt_ack_d(lsu_ifu_pcxpkt_ack_d),
    .lsu_ifu_stallreq(lsu_ifu_stallreq),
    .lsu_ifu_stbcnt0(lsu_ifu_stbcnt0[3:0]),
    .lsu_ifu_stbcnt1(lsu_ifu_stbcnt1[3:0]),
    .lsu_ifu_stbcnt2(lsu_ifu_stbcnt2[3:0]),
    .lsu_ifu_stbcnt3(lsu_ifu_stbcnt3[3:0]),
    .lsu_ifu_stxa_data(lsu_ifu_stxa_data[47:0]),
    .lsu_pid_state0(lsu_pid_state0[2:0]),
    .lsu_pid_state1(lsu_pid_state1[2:0]),
    .lsu_pid_state2(lsu_pid_state2[2:0]),
    .lsu_pid_state3(lsu_pid_state3[2:0]),
    .lsu_t0_pctxt_state(lsu_t0_pctxt_state[12:0]),
    .lsu_t1_pctxt_state(lsu_t1_pctxt_state[12:0]),
    .lsu_t2_pctxt_state(lsu_t2_pctxt_state[12:0]),
    .lsu_t3_pctxt_state(lsu_t3_pctxt_state[12:0]),
    .mbist_bisi_mode(mbist_bisi_mode),
    .mbist_dcache_data_in(mbist_dcache_data_in[71:0]),
    .mbist_loop_mode(mbist_loop_mode),
    .mbist_start(mbist_start),
    .mbist_stop_on_fail(mbist_stop_on_fail),
    .mbist_stop_on_next_fail(mbist_stop_on_next_fail),
    .mbist_userdata_mode(mbist_userdata_mode),
    .rclk(rclk),
    .se(se),
    .sehold(sehold),
    .spu_ifu_corr_err_w2(1'b0),
    .spu_ifu_err_addr_w2(36'h000000000),
    .spu_ifu_int_w2(1'b0),
    .spu_ifu_mamem_err_w1(1'b0),
    .spu_ifu_ttype_tid_w2(2'b00),
    .spu_ifu_ttype_vld_w2(1'b0),
    .spu_ifu_ttype_w2(1'b0),
    .spu_ifu_unc_err_w1(1'b0),
    .testmode_l(testmode_l),
    .tlu_hpstate_enb(tlu_hpstate_enb[3:0]),
    .tlu_hpstate_ibe(tlu_hpstate_ibe[3:0]),
    .tlu_hpstate_priv(tlu_hpstate_priv[3:0]),
    .tlu_idtlb_dmp_thrid_g(tlu_idtlb_dmp_thrid_g[1:0]),
    .tlu_ifu_hwint_i3(tlu_ifu_hwint_i3[3:0]),
    .tlu_ifu_nukeint_i2(tlu_ifu_nukeint_i2),
    .tlu_ifu_pstate_ie(tlu_ifu_pstate_ie[3:0]),
    .tlu_ifu_pstate_pef(tlu_ifu_pstate_pef[3:0]),
    .tlu_ifu_resumint_i2(tlu_ifu_resumint_i2),
    .tlu_ifu_rstint_i2(tlu_ifu_rstint_i2),
    .tlu_ifu_rstthr_i2(tlu_ifu_rstthr_i2[3:0]),
    .tlu_ifu_sftint_vld(tlu_ifu_sftint_vld[3:0]),
    .tlu_ifu_trap_tid_w1(tlu_ifu_trap_tid_w1[1:0]),
    .tlu_ifu_trapnpc_vld_w1(tlu_ifu_trapnpc_vld_w1),
    .tlu_ifu_trapnpc_w2(tlu_ifu_trapnpc_w2[48:0]),
    .tlu_ifu_trappc_vld_w1(tlu_ifu_trappc_vld_w1),
    .tlu_ifu_trappc_w2(tlu_ifu_trappc_w2[48:0]),
    .tlu_itlb_data_rd_g(tlu_itlb_data_rd_g),
    .tlu_itlb_dmp_actxt_g(tlu_itlb_dmp_actxt_g),
    .tlu_itlb_dmp_nctxt_g(tlu_itlb_dmp_nctxt_g),
    .tlu_itlb_dmp_vld_g(tlu_itlb_dmp_vld_g),
    .tlu_itlb_invalidate_all_g(tlu_itlb_invalidate_all_g),
    .tlu_itlb_tag_rd_g(tlu_itlb_tag_rd_g),
    .tlu_itlb_wr_vld_g(tlu_itlb_wr_vld_g),
    .tlu_lsu_pstate_am(tlu_lsu_pstate_am[3:0]),
    .tlu_lsu_pstate_priv(tlu_lsu_pstate_priv[3:0]),
    .tlu_lsu_redmode(tlu_lsu_redmode[3:0])
  );


  lsu
  lsu
  (
    .ifu_tlu_wsr_inst_d(ifu_lsu_wsr_inst_d),
    .lsu_ffu_st_dtlb_perr_g(lsu_ffu_st_dtlb_perr_g),
    .tlu_lsu_priv_trap_m(tlu_lsu_priv_trap_m),
    .short_si0(short_scan0_1),
    .short_si1(short_scan1_1),
    .short_so0(short_scan0_2),
    .short_so1(short_scan1_2),
    .si0(scan0_3),
    .si1(short_scan1_4),
    .so0(scan0_4),
    .so1(scan1_1),
    .grst_l(spc_grst_l),
    .arst_l(cmp_arst_l),
    .clk(rclk),
    .lsu_exu_dfill_data_w2(lsu_exu_dfill_data_g[63:0]),
    .lsu_exu_dfill_vld_w2(lsu_exu_dfill_vld_g),
    .lsu_exu_ldst_miss_w2(lsu_exu_ldst_miss_g2),
    .cpx_spc_data_cx({ cpx_spc_data_cx3_b144to140[145-1:140], cpx_spc_data_cx3[139:121], cpx_spc_data_cx3_b120to118[120:118], cpx_spc_data_cx3[117:110], cpx_spc_data_cx3_b109, cpx_spc_data_cx3[108:107], cpx_spc_data_cx3_b106, cpx_spc_data_cx3[105:104], cpx_spc_data_cx3_b103, cpx_spc_data_cx3[102:101], cpx_spc_data_cx3_b100, cpx_spc_data_cx3[99:98], cpx_spc_data_cx3_b97, cpx_spc_data_cx3[96:95], cpx_spc_data_cx3_b94, cpx_spc_data_cx3[93:92], cpx_spc_data_cx3_b91, cpx_spc_data_cx3[90:89], cpx_spc_data_cx3_b88, cpx_spc_data_cx3[87:85], cpx_spc_data_cx3_b84, cpx_spc_data_cx3[83:81], cpx_spc_data_cx3_b80, cpx_spc_data_cx3[79:77], cpx_spc_data_cx3_b76, cpx_spc_data_cx3[75:73], cpx_spc_data_cx3_b72, cpx_spc_data_cx3[71:69], cpx_spc_data_cx3_b68, cpx_spc_data_cx3[67:65], cpx_spc_data_cx3_b64, cpx_spc_data_cx3[63:61], cpx_spc_data_cx3_b60, cpx_spc_data_cx3[59:57], cpx_spc_data_cx3_b56, cpx_spc_data_cx3[55:54], cpx_spc_data_cx3_b53, cpx_spc_data_cx3[52:51], cpx_spc_data_cx3_b50, cpx_spc_data_cx3[49:48], cpx_spc_data_cx3_b47, cpx_spc_data_cx3[46:45], cpx_spc_data_cx3_b44, cpx_spc_data_cx3[43:42], cpx_spc_data_cx3_b41, cpx_spc_data_cx3[40:39], cpx_spc_data_cx3_b38, cpx_spc_data_cx3[37:36], cpx_spc_data_cx3_b35, cpx_spc_data_cx3[34:33], cpx_spc_data_cx3_b32, cpx_spc_data_cx3[31:29], cpx_spc_data_cx3_b28, cpx_spc_data_cx3[27:25], cpx_spc_data_cx3_b24, cpx_spc_data_cx3[23:21], cpx_spc_data_cx3_b20, cpx_spc_data_cx3[19:17], cpx_spc_data_cx3_b16, cpx_spc_data_cx3[15:13], cpx_spc_data_cx3_b12, cpx_spc_data_cx3[11:9], cpx_spc_data_cx3_b8, cpx_spc_data_cx3[7:5], cpx_spc_data_cx3_b4, cpx_spc_data_cx3[3:1], cpx_spc_data_cx3_b0 }),
    .exu_tlu_wsr_data_m(exu_tlu_wsr_data_m[7:0]),
    .tlu_lsu_hpv_priv(tlu_hpstate_priv[3:0]),
    .tlu_lsu_hpstate_en(tlu_hpstate_enb[3:0]),
    .spu_lsu_int_w2(1'b0),
    .gdbginit_l(spc_dbginit_l),
    .bist_ctl_reg_in(bist_ctl_reg_in[6:0]),
    .bist_ctl_reg_wr_en(bist_ctl_reg_wr_en),
    .ifu_tlu_flush_fd2_w(ifu_tlu_flush_fd2_w),
    .ifu_tlu_flush_fd3_w(ifu_tlu_flush_fd3_w),
    .ifu_tlu_flush_fd_w(ifu_tlu_flush_fd_w),
    .lsu_asi_reg0(lsu_asi_reg0[7:0]),
    .lsu_asi_reg1(lsu_asi_reg1[7:0]),
    .lsu_asi_reg2(lsu_asi_reg2[7:0]),
    .lsu_asi_reg3(lsu_asi_reg3[7:0]),
    .lsu_dmmu_sfsr_trp_wr(lsu_dmmu_sfsr_trp_wr[3:0]),
    .lsu_dsfsr_din_g(lsu_dsfsr_din_g[23:0]),
    .lsu_exu_flush_pipe_w(lsu_exu_flush_pipe_w),
    .lsu_exu_rd_m(lsu_exu_rd_m[4:0]),
    .lsu_exu_st_dtlb_perr_g(lsu_exu_st_dtlb_perr_g),
    .lsu_exu_thr_m(lsu_exu_thr_m[1:0]),
    .lsu_ffu_ack(lsu_ffu_ack),
    .lsu_ffu_blk_asi_e(lsu_ffu_blk_asi_e),
    .lsu_ffu_flush_pipe_w(lsu_ffu_flush_pipe_w),
    .lsu_ffu_ld_data(lsu_ffu_ld_data[63:0]),
    .lsu_ffu_ld_vld(lsu_ffu_ld_vld),
    .lsu_ffu_stb_full0(lsu_ffu_stb_full0),
    .lsu_ffu_stb_full1(lsu_ffu_stb_full1),
    .lsu_ffu_stb_full2(lsu_ffu_stb_full2),
    .lsu_ffu_stb_full3(lsu_ffu_stb_full3),
    .lsu_ictag_mrgn(lsu_ictag_mrgn[3:0]),
    .lsu_ifu_asi_addr(lsu_ifu_asi_addr[17:0]),
    .lsu_ifu_asi_load(lsu_ifu_asi_load),
    .lsu_ifu_asi_state(lsu_ifu_asi_state[7:0]),
    .lsu_ifu_asi_thrid(lsu_ifu_asi_thrid[1:0]),
    .lsu_ifu_asi_vld(lsu_ifu_asi_vld),
    .lsu_ifu_cpxpkt_i1(lsu_ifu_cpxpkt_i1[144-1:0]),
    .lsu_ifu_cpxpkt_vld_i1(lsu_ifu_cpxpkt_vld_i1),
    .lsu_ifu_dc_parity_error_w2(lsu_ifu_dc_parity_error_w2),
    .lsu_ifu_dcache_data_perror(lsu_ifu_dcache_data_perror),
    .lsu_ifu_dcache_tag_perror(lsu_ifu_dcache_tag_perror),
    .lsu_ifu_direct_map_l1(lsu_ifu_direct_map_l1),
    .lsu_ifu_error_tid(lsu_ifu_error_tid[1:0]),
    .lsu_ifu_flush_pipe_w(lsu_ifu_flush_pipe_w),
    .lsu_ifu_icache_en(lsu_ifu_icache_en[3:0]),
    .lsu_ifu_io_error(lsu_ifu_io_error),
    .lsu_ifu_itlb_en(lsu_ifu_itlb_en[3:0]),
    .lsu_ifu_l2_corr_error(lsu_ifu_l2_corr_error),
    .lsu_ifu_l2_unc_error(lsu_ifu_l2_unc_error),
    .lsu_ifu_ld_icache_index(lsu_ifu_ld_icache_index[11:5]),
    .lsu_ifu_ld_pcxpkt_tid(lsu_ifu_ld_pcxpkt_tid[1:0]),
    .lsu_ifu_ld_pcxpkt_vld(lsu_ifu_ld_pcxpkt_vld),
    .lsu_ifu_ldst_cmplt(lsu_ifu_ldst_cmplt[3:0]),
    .lsu_ifu_ldst_miss_w(lsu_ifu_ldst_miss_w),
    .lsu_ifu_ldsta_internal_e(lsu_ifu_ldsta_internal_e),
    .lsu_ifu_pcxpkt_ack_d(lsu_ifu_pcxpkt_ack_d),
    .lsu_ifu_stallreq(lsu_ifu_stallreq),
    .lsu_ifu_stbcnt0(lsu_ifu_stbcnt0[3:0]),
    .lsu_ifu_stbcnt1(lsu_ifu_stbcnt1[3:0]),
    .lsu_ifu_stbcnt2(lsu_ifu_stbcnt2[3:0]),
    .lsu_ifu_stbcnt3(lsu_ifu_stbcnt3[3:0]),
    .lsu_ifu_stxa_data(lsu_ifu_stxa_data[47:0]),
    .lsu_ifu_tlb_data_su(lsu_ifu_tlb_data_su),
    .lsu_ifu_tlb_data_ue(lsu_ifu_tlb_data_ue),
    .lsu_ifu_tlb_tag_ue(lsu_ifu_tlb_tag_ue),
    .lsu_itlb_mrgn(lsu_itlb_mrgn[7:0]),
    .lsu_mamem_mrgn(),
    .lsu_mmu_defr_trp_taken_g(lsu_mmu_defr_trp_taken_g),
    .lsu_mmu_flush_pipe_w(lsu_mmu_flush_pipe_w),
    .lsu_mmu_rs3_data_g(lsu_mmu_rs3_data_g[63:0]),
    .lsu_pid_state0(lsu_pid_state0[2:0]),
    .lsu_pid_state1(lsu_pid_state1[2:0]),
    .lsu_pid_state2(lsu_pid_state2[2:0]),
    .lsu_pid_state3(lsu_pid_state3[2:0]),
    .lsu_spu_asi_state_e(),
    .lsu_spu_early_flush_g(),
    .lsu_spu_ldst_ack(),
    .lsu_spu_stb_empty(),
    .lsu_spu_strm_ack_cmplt(),
    .lsu_t0_pctxt_state(lsu_t0_pctxt_state[12:0]),
    .lsu_t1_pctxt_state(lsu_t1_pctxt_state[12:0]),
    .lsu_t2_pctxt_state(lsu_t2_pctxt_state[12:0]),
    .lsu_t3_pctxt_state(lsu_t3_pctxt_state[12:0]),
    .lsu_tlu_async_tid_w2(lsu_tlu_async_tid_w2[1:0]),
    .lsu_tlu_async_ttype_vld_w2(lsu_tlu_async_ttype_vld_w2),
    .lsu_tlu_async_ttype_w2(lsu_tlu_async_ttype_w2[6:0]),
    .lsu_tlu_cpx_req(lsu_tlu_cpx_req[3:0]),
    .lsu_tlu_cpx_vld(lsu_tlu_cpx_vld),
    .lsu_tlu_daccess_excptn_g(lsu_tlu_daccess_excptn_g),
    .lsu_tlu_dcache_miss_w2(lsu_tlu_dcache_miss_w2[3:0]),
    .lsu_tlu_defr_trp_taken_g(lsu_tlu_defr_trp_taken_g),
    .lsu_tlu_dmmu_miss_g(lsu_tlu_dmmu_miss_g),
    .lsu_tlu_dside_ctxt_m(lsu_tlu_dside_ctxt_m[12:0]),
    .lsu_tlu_dtlb_done(lsu_tlu_dtlb_done),
    .lsu_tlu_early_flush2_w(lsu_tlu_early_flush2_w),
    .lsu_tlu_early_flush_w(lsu_tlu_early_flush_w),
    .lsu_tlu_intpkt(lsu_tlu_intpkt[17:0]),
    .lsu_tlu_l2_dmiss(lsu_tlu_l2_dmiss[3:0]),
    .lsu_tlu_ldst_va_m(lsu_tlu_ldst_va_m[9:0]),
    .lsu_tlu_misalign_addr_ldst_atm_m(lsu_tlu_misalign_addr_ldst_atm_m),
    .lsu_tlu_pctxt_m(lsu_tlu_pctxt_m[12:0]),
    .lsu_tlu_pcxpkt_ack(lsu_tlu_pcxpkt_ack),
    .lsu_tlu_rs3_data_g(lsu_tlu_rs3_data_g[63:0]),
    .lsu_tlu_rsr_data_e(lsu_tlu_rsr_data_e[7:0]),
    .lsu_tlu_stb_full_w2(lsu_tlu_stb_full_w2[3:0]),
    .lsu_tlu_thrid_d(lsu_tlu_thrid_d[1:0]),
    .lsu_tlu_tlb_access_tid_m(lsu_tlu_tlb_access_tid_m[1:0]),
    .lsu_tlu_tlb_asi_state_m(lsu_tlu_tlb_asi_state_m[7:0]),
    .lsu_tlu_tlb_dmp_va_m(lsu_tlu_tlb_dmp_va_m[47:13]),
    .lsu_tlu_tlb_ld_inst_m(lsu_tlu_tlb_ld_inst_m),
    .lsu_tlu_tlb_ldst_va_m(lsu_tlu_tlb_ldst_va_m[10:0]),
    .lsu_tlu_tlb_st_inst_m(lsu_tlu_tlb_st_inst_m),
    .lsu_tlu_ttype_m2(lsu_tlu_ttype_m2[8:0]),
    .lsu_tlu_ttype_vld_m2(lsu_tlu_ttype_vld_m2),
    .lsu_tlu_wsr_inst_e(lsu_tlu_wsr_inst_e),
    .mbist_dcache_data_in(mbist_dcache_data_in[71:0]),
    .spc_efc_dfuse_data(spc_efc_dfuse_data),
    .spc_pcx_atom_pq(spc_pcx_atom_pq),
    .spc_pcx_data_pa(spc_pcx_data_pa[124-1:0]),
    .spc_pcx_req_pq(spc_pcx_req_pq[4:0]),
    .lsu_asi_state(lsu_asi_state[7:0]),
    .lsu_ifu_err_addr(lsu_ifu_err_addr[47:4]),
    .lsu_sscan_data(lsu_sscan_data[15:0]),
    .ifu_tlu_inst_vld_m_bf1(ifu_tlu_inst_vld_m_bf1),
    .lsu_ffu_bld_cnt_w(lsu_ffu_bld_cnt_w[2:0]),
    .lsu_tlu_nucleus_ctxt_m(lsu_tlu_nucleus_ctxt_m),
    .lsu_tlu_tte_pg_sz_g(lsu_tlu_tte_pg_sz_g[2:0]),
    .lsu_tlu_squash_va_oor_m(lsu_tlu_squash_va_oor_m),
    .lsu_tlu_wtchpt_trp_g(lsu_tlu_wtchpt_trp_g),
    .lsu_tlu_daccess_prot_g(lsu_tlu_daccess_prot_g),
    .lsu_tlu_priv_action_g(lsu_tlu_priv_action_g),
    .bist_ctl_reg_out(bist_ctl_reg_out[10:0]),
    .const_cpuid(const_cpuid[2:0]),
    .ctu_sscan_tid(ctu_sscan_tid[3:0]),
    .efc_spc_dfuse_ashift(efc_spc_dfuse_ashift),
    .efc_spc_dfuse_data(efc_spc_dfuse_data),
    .efc_spc_dfuse_dshift(efc_spc_dfuse_dshift),
    .efc_spc_fuse_clk1(efc_spc_fuse_clk1),
    .efc_spc_fuse_clk2(efc_spc_fuse_clk2),
    .exu_lsu_rs2_data_e(exu_lsu_rs2_data_e[63:0]),
    .exu_lsu_rs3_data_e(exu_lsu_rs3_data_e[63:0]),
    .exu_tlu_misalign_addr_jmpl_rtn_m(exu_tlu_misalign_addr_jmpl_rtn_m),
    .exu_tlu_va_oor_m(exu_tlu_va_oor_m),
    .ffu_lsu_blk_st_e(ffu_lsu_blk_st_e),
    .ffu_lsu_blk_st_va_e(ffu_lsu_blk_st_va_e[5:3]),
    .ffu_lsu_fpop_rq_vld(ffu_lsu_fpop_rq_vld),
    .ffu_lsu_kill_fst_w(ffu_lsu_kill_fst_w),
    .ifu_lsu_alt_space_d(ifu_lsu_alt_space_d),
    .ifu_lsu_alt_space_e(ifu_lsu_alt_space_e),
    .ifu_lsu_asi_ack(ifu_lsu_asi_ack),
    .ifu_lsu_asi_rd_unc(ifu_lsu_asi_rd_unc),
    .ifu_lsu_casa_e(ifu_lsu_casa_e),
    .ifu_lsu_destid_s(ifu_lsu_destid_s[2:0]),
    .ifu_lsu_fwd_data_vld(ifu_lsu_fwd_data_vld),
    .ifu_lsu_fwd_wr_ack(ifu_lsu_fwd_wr_ack),
    .ifu_lsu_ibuf_busy(ifu_lsu_ibuf_busy),
    .ifu_lsu_imm_asi_d(ifu_lsu_imm_asi_d[7:0]),
    .ifu_lsu_imm_asi_vld_d(ifu_lsu_imm_asi_vld_d),
    .ifu_lsu_inv_clear(ifu_lsu_inv_clear),
    .ifu_lsu_ld_inst_e(ifu_lsu_ld_inst_e),
    .ifu_lsu_ldst_dbl_e(ifu_lsu_ldst_dbl_e),
    .ifu_lsu_ldst_fp_e(ifu_lsu_ldst_fp_e),
    .ifu_lsu_ldst_size_e(ifu_lsu_ldst_size_e[1:0]),
    .ifu_lsu_ldstub_e(ifu_lsu_ldstub_e),
    .ifu_lsu_ldxa_data_vld_w2(ifu_lsu_ldxa_data_vld_w2),
    .ifu_lsu_ldxa_data_w2(ifu_lsu_ldxa_data_w2[63:0]),
    .ifu_lsu_ldxa_illgl_va_w2(ifu_lsu_ldxa_illgl_va_w2),
    .ifu_lsu_ldxa_tid_w2(ifu_lsu_ldxa_tid_w2[1:0]),
    .ifu_lsu_memref_d(ifu_lsu_memref_d),
    .ifu_lsu_nceen(ifu_lsu_nceen[3:0]),
    .ifu_lsu_pcxpkt_e(ifu_lsu_pcxpkt_e[51:0]),
    .ifu_lsu_pcxreq_d(ifu_lsu_pcxreq_d),
    .ifu_lsu_pref_inst_e(ifu_lsu_pref_inst_e),
    .ifu_lsu_rd_e(ifu_lsu_rd_e[4:0]),
    .ifu_lsu_sign_ext_e(ifu_lsu_sign_ext_e),
    .ifu_lsu_st_inst_e(ifu_lsu_st_inst_e),
    .ifu_lsu_swap_e(ifu_lsu_swap_e),
    .ifu_lsu_thrid_s(ifu_lsu_thrid_s[1:0]),
    .ifu_tlu_flsh_inst_e(ifu_tlu_flsh_inst_e),
    .ifu_tlu_flush_m(ifu_tlu_flush_m),
    .ifu_tlu_inst_vld_m(ifu_tlu_inst_vld_m),
    .ifu_tlu_mb_inst_e(ifu_tlu_mb_inst_e),
    .ifu_tlu_sraddr_d(ifu_tlu_sraddr_d[6:0]),
    .ifu_tlu_thrid_e(ifu_tlu_thrid_e[1:0]),
    .mbist_dcache_index(mbist_dcache_index[6:0]),
    .mbist_dcache_read(mbist_dcache_read),
    .mbist_dcache_way(mbist_dcache_way[1:0]),
    .mbist_dcache_word(mbist_dcache_word),
    .mbist_dcache_write(mbist_dcache_write),
    .mbist_write_data(mbist_write_data[7:0]),
    .mem_write_disable(mem_write_disable),
    .mux_drive_disable(mux_drive_disable),
    .pcx_spc_grant_px(pcx_spc_grant_px[4:0]),
    .se(se),
    .sehold(sehold),
    .spu_lsu_ldxa_data_vld_w2(1'b0),
    .spu_lsu_ldxa_data_w2(64'h0000000000000000),
    .spu_lsu_ldxa_illgl_va_w2(1'b0),
    .spu_lsu_ldxa_tid_w2(2'b00),
    .spu_lsu_stxa_ack(1'b0),
    .spu_lsu_stxa_ack_tid(2'b00),
    .spu_lsu_unc_error_w2(1'b0),
    .testmode_l(testmode_l),
    .tlu_dsfsr_flt_vld(tlu_dsfsr_flt_vld[3:0]),
    .tlu_dtlb_data_rd_g(tlu_dtlb_data_rd_g),
    .tlu_dtlb_dmp_actxt_g(tlu_dtlb_dmp_actxt_g),
    .tlu_dtlb_dmp_all_g(tlu_dtlb_dmp_all_g),
    .tlu_dtlb_dmp_nctxt_g(tlu_dtlb_dmp_nctxt_g),
    .tlu_dtlb_dmp_pctxt_g(tlu_dtlb_dmp_pctxt_g),
    .tlu_dtlb_dmp_sctxt_g(tlu_dtlb_dmp_sctxt_g),
    .tlu_dtlb_dmp_vld_g(tlu_dtlb_dmp_vld_g),
    .tlu_dtlb_invalidate_all_g(tlu_dtlb_invalidate_all_g),
    .tlu_dtlb_rw_index_g(tlu_dtlb_rw_index_g[5:0]),
    .tlu_dtlb_rw_index_vld_g(tlu_dtlb_rw_index_vld_g),
    .tlu_dtlb_tag_rd_g(tlu_dtlb_tag_rd_g),
    .tlu_dtlb_tte_data_w2(tlu_dtlb_tte_data_w2[42:0]),
    .tlu_dtlb_tte_tag_w2(tlu_dtlb_tte_tag_w2[58:0]),
    .tlu_early_flush_pipe2_w(tlu_early_flush_pipe2_w),
    .tlu_early_flush_pipe_w(tlu_early_flush_pipe_w),
    .tlu_exu_early_flush_pipe_w(tlu_exu_early_flush_pipe_w),
    .tlu_idtlb_dmp_key_g(tlu_idtlb_dmp_key_g[40:0]),
    .tlu_idtlb_dmp_thrid_g(tlu_idtlb_dmp_thrid_g[1:0]),
    .tlu_lsu_asi_m(tlu_lsu_asi_m[7:0]),
    .tlu_lsu_asi_update_m(tlu_lsu_asi_update_m),
    .tlu_lsu_int_ld_ill_va_w2(tlu_lsu_int_ld_ill_va_w2),
    .tlu_lsu_int_ldxa_data_w2(tlu_lsu_int_ldxa_data_w2[63:0]),
    .tlu_lsu_int_ldxa_vld_w2(tlu_lsu_int_ldxa_vld_w2),
    .tlu_lsu_ldxa_async_data_vld(tlu_lsu_ldxa_async_data_vld),
    .tlu_lsu_ldxa_tid_w2(tlu_lsu_ldxa_tid_w2[1:0]),
    .tlu_lsu_pcxpkt(tlu_lsu_pcxpkt[25:0]),
    .tlu_lsu_pstate_am(tlu_lsu_pstate_am[3:0]),
    .tlu_lsu_pstate_cle(tlu_lsu_pstate_cle[3:0]),
    .tlu_lsu_pstate_priv(tlu_lsu_pstate_priv[3:0]),
    .tlu_lsu_redmode(tlu_lsu_redmode[3:0]),
    .tlu_lsu_redmode_rst_d1(tlu_lsu_redmode_rst_d1[3:0]),
    .tlu_lsu_stxa_ack(tlu_lsu_stxa_ack),
    .tlu_lsu_stxa_ack_tid(tlu_lsu_stxa_ack_tid[1:0]),
    .tlu_lsu_tid_m(tlu_lsu_tid_m[1:0]),
    .tlu_lsu_tl_zero(tlu_lsu_tl_zero[3:0]),
    .spu_lsu_ldst_pckt(124'h0000000000000000000000000000000),
    .exu_lsu_ldst_va_e(exu_lsu_ldst_va_e[47:0]),
    .exu_lsu_early_va_e(exu_lsu_early_va_e[10:3]),
    .ffu_lsu_data(ffu_lsu_data[80:0])
  );


  sparc_exu
  exu
  (
    .short_si0(short_scan0_2),
    .short_so0(short_scan0_3),
    .short_si1(short_scan1_2),
    .short_so1(short_scan1_3),
    .si0(scan0_2),
    .so0(scan0_3),
    .grst_l(spc_grst_l),
    .arst_l(cmp_arst_l),
    .mul_exu_data_g(mul_data_out[63:0]),
    .ifu_tlu_wsr_inst_d(ifu_exu_wsr_inst_d),
    .exu_tlu_ue_trap_m(),
    .exu_ffu_wsr_inst_e(exu_ffu_wsr_inst_e),
    .exu_ifu_brpc_e(exu_ifu_brpc_e[47:0]),
    .exu_ifu_cc_d(exu_ifu_cc_d[7:0]),
    .exu_ifu_ecc_ce_m(exu_ifu_ecc_ce_m),
    .exu_ifu_ecc_ue_m(exu_ifu_ecc_ue_m),
    .exu_ifu_err_reg_m(exu_ifu_err_reg_m[7:0]),
    .exu_ifu_inj_ack(exu_ifu_inj_ack),
    .exu_ifu_longop_done_g(exu_ifu_longop_done_g[3:0]),
    .exu_ifu_oddwin_s(exu_ifu_oddwin_s[3:0]),
    .exu_ifu_regn_e(exu_ifu_regn_e),
    .exu_ifu_regz_e(exu_ifu_regz_e),
    .exu_ifu_spill_e(exu_ifu_spill_e),
    .exu_ifu_va_oor_m(exu_ifu_va_oor_m),
    .exu_lsu_early_va_e(exu_lsu_early_va_e[10:3]),
    .exu_lsu_ldst_va_e(exu_lsu_ldst_va_e[47:0]),
    .exu_lsu_priority_trap_m(exu_lsu_priority_trap_m),
    .exu_lsu_rs2_data_e(exu_lsu_rs2_data_e[63:0]),
    .exu_lsu_rs3_data_e(exu_lsu_rs3_data_e[63:0]),
    .exu_mmu_early_va_e(exu_mmu_early_va_e[7:0]),
    .exu_mul_input_vld(exu_mul_input_vld),
    .exu_mul_rs1_data(exu_mul_rs1_data[63:0]),
    .exu_mul_rs2_data(exu_mul_rs2_data[63:0]),
    .exu_spu_rs3_data_e(),
    .exu_tlu_ccr0_w(exu_tlu_ccr0_w[7:0]),
    .exu_tlu_ccr1_w(exu_tlu_ccr1_w[7:0]),
    .exu_tlu_ccr2_w(exu_tlu_ccr2_w[7:0]),
    .exu_tlu_ccr3_w(exu_tlu_ccr3_w[7:0]),
    .exu_tlu_cwp0_w(exu_tlu_cwp0_w[2:0]),
    .exu_tlu_cwp1_w(exu_tlu_cwp1_w[2:0]),
    .exu_tlu_cwp2_w(exu_tlu_cwp2_w[2:0]),
    .exu_tlu_cwp3_w(exu_tlu_cwp3_w[2:0]),
    .exu_tlu_cwp_cmplt(exu_tlu_cwp_cmplt),
    .exu_tlu_cwp_cmplt_tid(exu_tlu_cwp_cmplt_tid[1:0]),
    .exu_tlu_cwp_retry(exu_tlu_cwp_retry),
    .exu_tlu_misalign_addr_jmpl_rtn_m(exu_tlu_misalign_addr_jmpl_rtn_m),
    .exu_tlu_spill(exu_tlu_spill),
    .exu_tlu_spill_other(exu_tlu_spill_other),
    .exu_tlu_spill_tid(exu_tlu_spill_tid[1:0]),
    .exu_tlu_spill_wtype(exu_tlu_spill_wtype[2:0]),
    .exu_tlu_ttype_m(exu_tlu_ttype_m[8:0]),
    .exu_tlu_ttype_vld_m(exu_tlu_ttype_vld_m),
    .exu_tlu_va_oor_jl_ret_m(exu_tlu_va_oor_jl_ret_m),
    .exu_tlu_va_oor_m(exu_tlu_va_oor_m),
    .exu_tlu_wsr_data_m(exu_tlu_wsr_data_m[63:0]),
    .exu_ifu_err_synd_m(exu_ifu_err_synd_m[7:0]),
    .mux_drive_disable(mux_drive_disable),
    .mem_write_disable(mem_write_disable),
    .ffu_exu_rsr_data_m(ffu_exu_rsr_data_m[63:0]),
    .ifu_exu_addr_mask_d(ifu_exu_addr_mask_d),
    .ifu_exu_aluop_d(ifu_exu_aluop_d[2:0]),
    .ifu_exu_casa_d(ifu_exu_casa_d),
    .ifu_exu_dbrinst_d(ifu_exu_dbrinst_d),
    .ifu_exu_disable_ce_e(ifu_exu_disable_ce_e),
    .ifu_exu_dontmv_regz0_e(ifu_exu_dontmv_regz0_e),
    .ifu_exu_dontmv_regz1_e(ifu_exu_dontmv_regz1_e),
    .ifu_exu_ecc_mask(ifu_exu_ecc_mask[7:0]),
    .ifu_exu_enshift_d(ifu_exu_enshift_d),
    .ifu_exu_flushw_e(ifu_exu_flushw_e),
    .ifu_exu_ialign_d(ifu_exu_ialign_d),
    .ifu_exu_imm_data_d(ifu_exu_imm_data_d[31:0]),
    .ifu_exu_inj_irferr(ifu_exu_inj_irferr),
    .ifu_exu_inst_vld_e(ifu_exu_inst_vld_e),
    .ifu_exu_inst_vld_w(ifu_exu_inst_vld_w),
    .ifu_exu_invert_d(ifu_exu_invert_d),
    .ifu_exu_kill_e(ifu_exu_kill_e),
    .ifu_exu_muldivop_d(ifu_exu_muldivop_d[4:0]),
    .ifu_exu_muls_d(ifu_exu_muls_d),
    .ifu_exu_nceen_e(ifu_exu_nceen_e),
    .ifu_exu_pc_d(ifu_exu_pc_d[47:0]),
    .ifu_exu_pcver_e(ifu_exu_pcver_e[63:0]),
    .ifu_exu_range_check_jlret_d(ifu_exu_range_check_jlret_d),
    .ifu_exu_range_check_other_d(ifu_exu_range_check_other_d),
    .ifu_exu_rd_d(ifu_exu_rd_d[4:0]),
    .ifu_exu_rd_exusr_e(ifu_exu_rd_exusr_e),
    .ifu_exu_rd_ffusr_e(ifu_exu_rd_ffusr_e),
    .ifu_exu_rd_ifusr_e(ifu_exu_rd_ifusr_e),
    .ifu_exu_ren1_s(ifu_exu_ren1_s),
    .ifu_exu_ren2_s(ifu_exu_ren2_s),
    .ifu_exu_ren3_s(ifu_exu_ren3_s),
    .ifu_exu_restore_d(ifu_exu_restore_d),
    .ifu_exu_restored_e(ifu_exu_restored_e),
    .ifu_exu_return_d(ifu_exu_return_d),
    .ifu_exu_rs1_s(ifu_exu_rs1_s[4:0]),
    .ifu_exu_rs1_vld_d(ifu_exu_rs1_vld_d),
    .ifu_exu_rs2_s(ifu_exu_rs2_s[4:0]),
    .ifu_exu_rs2_vld_d(ifu_exu_rs2_vld_d),
    .ifu_exu_rs3_s(ifu_exu_rs3_s[4:0]),
    .ifu_exu_rs3e_vld_d(ifu_exu_rs3e_vld_d),
    .ifu_exu_rs3o_vld_d(ifu_exu_rs3o_vld_d),
    .ifu_exu_save_d(ifu_exu_save_d),
    .ifu_exu_saved_e(ifu_exu_saved_e),
    .ifu_exu_setcc_d(ifu_exu_setcc_d),
    .ifu_exu_sethi_inst_d(ifu_exu_sethi_inst_d),
    .ifu_exu_shiftop_d(ifu_exu_shiftop_d[2:0]),
    .ifu_exu_tagop_d(ifu_exu_tagop_d),
    .ifu_exu_tcc_e(ifu_exu_tcc_e),
    .ifu_exu_tid_s2(ifu_exu_tid_s2[1:0]),
    .ifu_exu_ttype_vld_m(ifu_exu_ttype_vld_m),
    .ifu_exu_tv_d(ifu_exu_tv_d),
    .ifu_exu_use_rsr_e_l(ifu_exu_use_rsr_e_l),
    .ifu_exu_usecin_d(ifu_exu_usecin_d),
    .ifu_exu_useimm_d(ifu_exu_useimm_d),
    .ifu_exu_wen_d(ifu_exu_wen_d),
    .ifu_tlu_flush_m(ifu_tlu_flush_m),
    .ifu_tlu_sraddr_d(ifu_tlu_sraddr_d[6:0]),
    .lsu_exu_dfill_data_g(lsu_exu_dfill_data_g[63:0]),
    .lsu_exu_dfill_vld_g(lsu_exu_dfill_vld_g),
    .lsu_exu_flush_pipe_w(lsu_exu_flush_pipe_w),
    .lsu_exu_ldst_miss_g2(lsu_exu_ldst_miss_g2),
    .lsu_exu_ldxa_data_g(lsu_exu_ldxa_data_g[63:0]),
    .lsu_exu_ldxa_m(lsu_exu_ldxa_m),
    .lsu_exu_rd_m(lsu_exu_rd_m[4:0]),
    .lsu_exu_st_dtlb_perr_g(lsu_exu_st_dtlb_perr_g),
    .lsu_exu_thr_m(lsu_exu_thr_m[1:0]),
    .mul_exu_ack(mul_exu_ack),
    .rclk(rclk),
    .se(se),
    .sehold(sehold),
    .tlu_exu_agp(tlu_exu_agp[1:0]),
    .tlu_exu_agp_swap(tlu_exu_agp_swap),
    .tlu_exu_agp_tid(tlu_exu_agp_tid[1:0]),
    .tlu_exu_ccr_m(tlu_exu_ccr_m[7:0]),
    .tlu_exu_cwp_m(tlu_exu_cwp_m[2:0]),
    .tlu_exu_cwp_retry_m(tlu_exu_cwp_retry_m),
    .tlu_exu_cwpccr_update_m(tlu_exu_cwpccr_update_m),
    .tlu_exu_pic_onebelow_m(tlu_exu_pic_onebelow_m),
    .tlu_exu_pic_twobelow_m(tlu_exu_pic_twobelow_m),
    .tlu_exu_priv_trap_m(tlu_exu_priv_trap_m),
    .tlu_exu_rsr_data_m(tlu_exu_rsr_data_m[63:0])
  );


  tlu
  tlu
  (
    .short_si0(short_scan0_3),
    .short_si1(short_scan1_3),
    .short_so0(short_scan0_4),
    .short_so1(short_scan1_4),
    .si0(scan0_4),
    .si1(scan1_1),
    .so0(scan0_5),
    .so1(scan1_2),
    .grst_l(spc_grst_l),
    .arst_l(cmp_arst_l),
    .tlu_sftint_vld(tlu_ifu_sftint_vld[3:0]),
    .ifu_tlu_swint_m(ifu_tlu_sftint_m),
    .exu_tlu_cwp0(exu_tlu_cwp0_w[2:0]),
    .exu_tlu_cwp1(exu_tlu_cwp1_w[2:0]),
    .exu_tlu_cwp2(exu_tlu_cwp2_w[2:0]),
    .exu_tlu_cwp3(exu_tlu_cwp3_w[2:0]),
    .exu_tlu_ue_trap_m(1'b0),
    .spu_tlu_rsrv_illgl_m(1'b0),
    .ifu_lsu_imm_asi_d(ifu_tlu_imm_asi_d[8:0]),
    .ifu_tlu_imiss_e(ifu_tlu_icmiss_e),
    .ifu_tlu_thrid_d(lsu_tlu_thrid_d[1:0]),
    .lsu_tlu_st_rs3_data_g(lsu_mmu_rs3_data_g[63:0]),
    .lsu_tlu_async_ttype_g(lsu_tlu_async_ttype_w2[6:0]),
    .lsu_tlu_async_tid_g(lsu_tlu_async_tid_w2[1:0]),
    .lsu_tlu_async_ttype_vld_g(lsu_tlu_async_ttype_vld_w2),
    .tlu_lsu_int_ldxa_data_w2(tlu_lsu_int_ldxa_data_w2[63:0]),
    .tlu_lsu_int_ld_ill_va_w2(tlu_lsu_int_ld_ill_va_w2),
    .tlu_lsu_int_ldxa_vld_w2(tlu_lsu_int_ldxa_vld_w2),
    .tlu_dtlb_data_rd_g(tlu_dtlb_data_rd_g),
    .tlu_dtlb_dmp_actxt_g(tlu_dtlb_dmp_actxt_g),
    .tlu_dtlb_dmp_all_g(tlu_dtlb_dmp_all_g),
    .tlu_dtlb_dmp_nctxt_g(tlu_dtlb_dmp_nctxt_g),
    .tlu_dtlb_dmp_pctxt_g(tlu_dtlb_dmp_pctxt_g),
    .tlu_dtlb_dmp_sctxt_g(tlu_dtlb_dmp_sctxt_g),
    .tlu_dtlb_dmp_vld_g(tlu_dtlb_dmp_vld_g),
    .tlu_dtlb_invalidate_all_g(tlu_dtlb_invalidate_all_g),
    .tlu_dtlb_rw_index_g(tlu_dtlb_rw_index_g[5:0]),
    .tlu_dtlb_rw_index_vld_g(tlu_dtlb_rw_index_vld_g),
    .tlu_dtlb_tag_rd_g(tlu_dtlb_tag_rd_g),
    .tlu_dtlb_tte_data_w2(tlu_dtlb_tte_data_w2[42:0]),
    .tlu_dtlb_tte_tag_w2(tlu_dtlb_tte_tag_w2[58:0]),
    .lsu_ifu_inj_ack(lsu_ifu_inj_ack[3:0]),
    .tlu_exu_agp(tlu_exu_agp[2-1:0]),
    .tlu_exu_agp_swap(tlu_exu_agp_swap),
    .tlu_exu_agp_tid(tlu_exu_agp_tid[1:0]),
    .tlu_exu_ccr_m(tlu_exu_ccr_m[7:0]),
    .tlu_exu_cwp_m(tlu_exu_cwp_m[2:0]),
    .tlu_exu_cwp_retry_m(tlu_exu_cwp_retry_m),
    .tlu_exu_cwpccr_update_m(tlu_exu_cwpccr_update_m),
    .tlu_exu_rsr_data_m(tlu_exu_rsr_data_m[64-1:0]),
    .tlu_idtlb_dmp_key_g(tlu_idtlb_dmp_key_g[40:0]),
    .tlu_idtlb_dmp_thrid_g(tlu_idtlb_dmp_thrid_g[1:0]),
    .tlu_ifu_hwint_i3(tlu_ifu_hwint_i3[3:0]),
    .tlu_ifu_nukeint_i2(tlu_ifu_nukeint_i2),
    .tlu_ifu_pstate_ie(tlu_ifu_pstate_ie[3:0]),
    .tlu_ifu_pstate_pef(tlu_ifu_pstate_pef[3:0]),
    .tlu_ifu_resumint_i2(tlu_ifu_resumint_i2),
    .tlu_ifu_rstint_i2(tlu_ifu_rstint_i2),
    .tlu_ifu_rstthr_i2(tlu_ifu_rstthr_i2[3:0]),
    .tlu_ifu_trap_tid_w1(tlu_ifu_trap_tid_w1[1:0]),
    .tlu_ifu_trapnpc_vld_w1(tlu_ifu_trapnpc_vld_w1),
    .tlu_ifu_trapnpc_w2(tlu_ifu_trapnpc_w2[48:0]),
    .tlu_ifu_trappc_w2(tlu_ifu_trappc_w2[48:0]),
    .tlu_ifu_trappc_vld_w1(tlu_ifu_trappc_vld_w1),
    .tlu_itlb_data_rd_g(tlu_itlb_data_rd_g),
    .tlu_itlb_dmp_actxt_g(tlu_itlb_dmp_actxt_g),
    .tlu_itlb_dmp_all_g(tlu_itlb_dmp_all_g),
    .tlu_itlb_dmp_nctxt_g(tlu_itlb_dmp_nctxt_g),
    .tlu_itlb_dmp_vld_g(tlu_itlb_dmp_vld_g),
    .tlu_itlb_invalidate_all_g(tlu_itlb_invalidate_all_g),
    .tlu_itlb_rw_index_g(tlu_itlb_rw_index_g[5:0]),
    .tlu_itlb_rw_index_vld_g(tlu_itlb_rw_index_vld_g),
    .tlu_itlb_tag_rd_g(tlu_itlb_tag_rd_g),
    .tlu_itlb_tte_data_w2(tlu_itlb_tte_data_w2[42:0]),
    .tlu_itlb_tte_tag_w2(tlu_itlb_tte_tag_w2[58:0]),
    .tlu_itlb_wr_vld_g(tlu_itlb_wr_vld_g),
    .tlu_lsu_asi_m(tlu_lsu_asi_m[7:0]),
    .tlu_lsu_asi_update_m(tlu_lsu_asi_update_m),
    .tlu_sscan_test_data(tlu_sscan_test_data[62:0]),
    .tlu_lsu_ldxa_tid_w2(tlu_lsu_ldxa_tid_w2[1:0]),
    .tlu_lsu_pcxpkt(tlu_lsu_pcxpkt[25:0]),
    .tlu_lsu_pstate_am(tlu_lsu_pstate_am[3:0]),
    .tlu_lsu_pstate_cle(tlu_lsu_pstate_cle[3:0]),
    .tlu_lsu_pstate_priv(tlu_lsu_pstate_priv[3:0]),
    .tlu_lsu_redmode(tlu_lsu_redmode[3:0]),
    .tlu_lsu_redmode_rst_d1(tlu_lsu_redmode_rst_d1[3:0]),
    .tlu_lsu_stxa_ack(tlu_lsu_stxa_ack),
    .tlu_lsu_stxa_ack_tid(tlu_lsu_stxa_ack_tid[1:0]),
    .tlu_lsu_tid_m(tlu_lsu_tid_m[1:0]),
    .tlu_lsu_tl_zero(tlu_lsu_tl_zero[4-1:0]),
    .tlu_hintp_vld(tlu_hintp_vld[4-1:0]),
    .tlu_rerr_vld(tlu_rerr_vld[4-1:0]),
    .tlu_early_flush_pipe_w(tlu_early_flush_pipe_w),
    .tlu_early_flush_pipe2_w(tlu_early_flush_pipe2_w),
    .tlu_exu_early_flush_pipe_w(tlu_exu_early_flush_pipe_w),
    .tlu_lsu_ldxa_async_data_vld(tlu_lsu_ldxa_async_data_vld),
    .tlu_hpstate_priv(tlu_hpstate_priv[4-1:0]),
    .tlu_hpstate_enb(tlu_hpstate_enb[4-1:0]),
    .tlu_hpstate_ibe(tlu_hpstate_ibe[4-1:0]),
    .tlu_exu_priv_trap_m(tlu_exu_priv_trap_m),
    .tlu_lsu_priv_trap_m(tlu_lsu_priv_trap_m),
    .tlu_exu_pic_onebelow_m(tlu_exu_pic_onebelow_m),
    .tlu_exu_pic_twobelow_m(tlu_exu_pic_twobelow_m),
    .lsu_exu_ldxa_m(lsu_exu_ldxa_m),
    .lsu_exu_ldxa_data_g(lsu_exu_ldxa_data_g[63:0]),
    .tlu_dsfsr_flt_vld(tlu_dsfsr_flt_vld[3:0]),
    .rclk(rclk),
    .const_cpuid(const_cpuid[3:0]),
    .exu_lsu_ldst_va_e(exu_lsu_ldst_va_e[48-1:0]),
    .lsu_tlu_ldst_va_m(lsu_tlu_ldst_va_m[10-1:0]),
    .exu_mmu_early_va_e(exu_mmu_early_va_e[7:0]),
    .exu_tlu_ccr0_w(exu_tlu_ccr0_w[7:0]),
    .exu_tlu_ccr1_w(exu_tlu_ccr1_w[7:0]),
    .exu_tlu_ccr2_w(exu_tlu_ccr2_w[7:0]),
    .exu_tlu_ccr3_w(exu_tlu_ccr3_w[7:0]),
    .exu_tlu_cwp_cmplt(exu_tlu_cwp_cmplt),
    .exu_tlu_cwp_cmplt_tid(exu_tlu_cwp_cmplt_tid[1:0]),
    .exu_tlu_cwp_retry(exu_tlu_cwp_retry),
    .exu_tlu_misalign_addr_jmpl_rtn_m(exu_tlu_misalign_addr_jmpl_rtn_m),
    .exu_tlu_spill(exu_tlu_spill),
    .exu_tlu_spill_tid(exu_tlu_spill_tid[1:0]),
    .exu_tlu_spill_other(exu_tlu_spill_other),
    .exu_tlu_spill_wtype(exu_tlu_spill_wtype[2:0]),
    .exu_tlu_ttype_m(exu_tlu_ttype_m[8:0]),
    .exu_tlu_ttype_vld_m(exu_tlu_ttype_vld_m),
    .exu_tlu_va_oor_jl_ret_m(exu_tlu_va_oor_jl_ret_m),
    .exu_tlu_va_oor_m(exu_tlu_va_oor_m),
    .ffu_tlu_ill_inst_m(ffu_tlu_ill_inst_m),
    .ffu_ifu_tid_w2(ffu_ifu_tid_w2[1:0]),
    .ffu_tlu_trap_ieee754(ffu_tlu_trap_ieee754),
    .ffu_tlu_trap_other(ffu_tlu_trap_other),
    .ffu_tlu_trap_ue(ffu_tlu_trap_ue),
    .ifu_lsu_ld_inst_e(ifu_lsu_ld_inst_e),
    .ifu_lsu_memref_d(ifu_lsu_memref_d),
    .ifu_lsu_st_inst_e(ifu_lsu_st_inst_e),
    .ifu_tlu_done_inst_d(ifu_tlu_done_inst_d),
    .ifu_tlu_flush_m(ifu_tlu_flush_m),
    .ifu_tlu_flush_fd_w(ifu_tlu_flush_fd_w),
    .ifu_tlu_flush_fd2_w(ifu_tlu_flush_fd2_w),
    .ifu_tlu_flush_fd3_w(ifu_tlu_flush_fd3_w),
    .lsu_tlu_early_flush_w(lsu_tlu_early_flush_w),
    .lsu_tlu_early_flush2_w(lsu_tlu_early_flush2_w),
    .ifu_tlu_hwint_m(ifu_tlu_hwint_m),
    .ifu_tlu_immu_miss_m(ifu_tlu_immu_miss_m),
    .ifu_tlu_pc_oor_e(ifu_tlu_pc_oor_e),
    .ifu_tlu_l2imiss(ifu_tlu_l2imiss[4-1:0]),
    .ifu_tlu_inst_vld_m(ifu_tlu_inst_vld_m),
    .ifu_tlu_inst_vld_m_bf1(ifu_tlu_inst_vld_m_bf1),
    .ifu_tlu_itlb_done(ifu_tlu_itlb_done),
    .ifu_tlu_npc_m(ifu_tlu_npc_m[48:0]),
    .ifu_tlu_pc_m(ifu_tlu_pc_m[48:0]),
    .ifu_tlu_priv_violtn_m(ifu_tlu_priv_violtn_m),
    .ifu_tlu_retry_inst_d(ifu_tlu_retry_inst_d),
    .ifu_tlu_rstint_m(ifu_tlu_rstint_m),
    .ifu_tlu_sir_inst_m(ifu_tlu_sir_inst_m),
    .ifu_lsu_thrid_s(ifu_lsu_thrid_s[1:0]),
    .ifu_tlu_ttype_m(ifu_tlu_ttype_m[8:0]),
    .ifu_tlu_ttype_vld_m(ifu_tlu_ttype_vld_m),
    .ifu_mmu_trap_m(ifu_mmu_trap_m),
    .ifu_tlu_trap_m(ifu_tlu_trap_m),
    .lsu_asi_reg0(lsu_asi_reg0[7:0]),
    .lsu_asi_reg1(lsu_asi_reg1[7:0]),
    .lsu_asi_reg2(lsu_asi_reg2[7:0]),
    .lsu_asi_reg3(lsu_asi_reg3[7:0]),
    .lsu_asi_state(lsu_asi_state[8-1:0]),
    .lsu_tlu_defr_trp_taken_g(lsu_tlu_defr_trp_taken_g),
    .lsu_mmu_defr_trp_taken_g(lsu_mmu_defr_trp_taken_g),
    .lsu_tlu_cpx_req(lsu_tlu_cpx_req[3:0]),
    .lsu_tlu_cpx_vld(lsu_tlu_cpx_vld),
    .lsu_tlu_daccess_excptn_g(lsu_tlu_daccess_excptn_g),
    .lsu_tlu_daccess_prot_g(lsu_tlu_daccess_prot_g),
    .lsu_tlu_dmmu_miss_g(lsu_tlu_dmmu_miss_g),
    .lsu_tlu_dside_ctxt_m(lsu_tlu_dside_ctxt_m[12:0]),
    .lsu_tlu_dtlb_done(lsu_tlu_dtlb_done),
    .lsu_tlu_intpkt(lsu_tlu_intpkt[17:0]),
    .ctu_sscan_tid(ctu_sscan_tid[4-1:0]),
    .lsu_tlu_misalign_addr_ldst_atm_m(lsu_tlu_misalign_addr_ldst_atm_m),
    .lsu_tlu_pctxt_m(lsu_tlu_pctxt_m[12:0]),
    .lsu_tlu_pcxpkt_ack(lsu_tlu_pcxpkt_ack),
    .lsu_tlu_priv_action_g(lsu_tlu_priv_action_g),
    .lsu_tlu_rs3_data_g(lsu_tlu_rs3_data_g[63:0]),
    .lsu_tlu_tlb_access_tid_m(lsu_tlu_tlb_access_tid_m[1:0]),
    .lsu_tlu_tlb_asi_state_m(lsu_tlu_tlb_asi_state_m[7:0]),
    .lsu_tlu_tlb_dmp_va_m(lsu_tlu_tlb_dmp_va_m[47:13]),
    .lsu_tlu_tlb_ld_inst_m(lsu_tlu_tlb_ld_inst_m),
    .lsu_tlu_tlb_ldst_va_m(lsu_tlu_tlb_ldst_va_m[10:0]),
    .lsu_tlu_tlb_st_inst_m(lsu_tlu_tlb_st_inst_m),
    .lsu_tlu_ttype_m2(lsu_tlu_ttype_m2[8:0]),
    .lsu_tlu_ttype_vld_m2(lsu_tlu_ttype_vld_m2),
    .lsu_tlu_wtchpt_trp_g(lsu_tlu_wtchpt_trp_g),
    .mem_write_disable(mem_write_disable),
    .mux_drive_disable(mux_drive_disable),
    .sehold(sehold),
    .se(se),
    .ifu_tlu_sraddr_d(ifu_tlu_sraddr_d[7-1:0]),
    .ifu_tlu_sraddr_d_v2(ifu_tlu_sraddr_d_v2[7-1:0]),
    .ifu_tlu_rsr_inst_d(ifu_tlu_rsr_inst_d),
    .lsu_tlu_wsr_inst_e(lsu_tlu_wsr_inst_e),
    .exu_tlu_wsr_data_m(exu_tlu_wsr_data_m[63:0]),
    .lsu_tlu_rsr_data_e(lsu_tlu_rsr_data_e[7:0]),
    .ifu_lsu_alt_space_e(ifu_lsu_alt_space_e),
    .ifu_tlu_alt_space_d(ifu_tlu_alt_space_d),
    .lsu_tlu_squash_va_oor_m(lsu_tlu_squash_va_oor_m),
    .lsu_tlu_dcache_miss_w2(lsu_tlu_dcache_miss_w2[3:0]),
    .lsu_tlu_l2_dmiss(lsu_tlu_l2_dmiss[3:0]),
    .lsu_tlu_stb_full_w2(lsu_tlu_stb_full_w2[3:0]),
    .ffu_tlu_fpu_tid(ffu_tlu_fpu_tid[1:0]),
    .ffu_tlu_fpu_cmplt(ffu_tlu_fpu_cmplt),
    .lsu_pid_state0(lsu_pid_state0[2:0]),
    .lsu_pid_state1(lsu_pid_state1[2:0]),
    .lsu_pid_state2(lsu_pid_state2[2:0]),
    .lsu_pid_state3(lsu_pid_state3[2:0]),
    .lsu_tlu_nucleus_ctxt_m(lsu_tlu_nucleus_ctxt_m),
    .lsu_tlu_tte_pg_sz_g(lsu_tlu_tte_pg_sz_g[2:0]),
    .ifu_lsu_error_inj(ifu_lsu_error_inj[3:0]),
    .ifu_lsu_imm_asi_vld_d(ifu_lsu_imm_asi_vld_d),
    .lsu_dsfsr_din_g(lsu_dsfsr_din_g[23:0]),
    .lsu_dmmu_sfsr_trp_wr(lsu_dmmu_sfsr_trp_wr[3:0]),
    .lsu_mmu_flush_pipe_w(lsu_mmu_flush_pipe_w),
    .exu_lsu_priority_trap_m(exu_lsu_priority_trap_m)
  );


  sparc_mul_top
  mul
  (
    .si(scan1_2),
    .so(scan1_4),
    .grst_l(spc_grst_l),
    .arst_l(cmp_arst_l),
    .mul_exu_ack(mul_exu_ack),
    .mul_spu_ack(),
    .mul_spu_shf_ack(),
    .mul_data_out(mul_data_out[63:0]),
    .rclk(rclk),
    .se(se),
    .exu_mul_input_vld(exu_mul_input_vld),
    .exu_mul_rs1_data(exu_mul_rs1_data[63:0]),
    .exu_mul_rs2_data(exu_mul_rs2_data[63:0]),
    .spu_mul_req_vld(1'b0),
    .spu_mul_acc(1'b0),
    .spu_mul_areg_shf(1'b0),
    .spu_mul_areg_rst(1'b0),
    .spu_mul_op1_data(64'h0000000000000000),
    .spu_mul_op2_data(64'h0000000000000000),
    .spu_mul_mulres_lshft(spu_mul_mulres_lshft)
  );


  sparc_ffu
  ffu
  (
    .short_si0(short_scan0_4),
    .short_so0(short_scan0_6),
    .si(scan0_5),
    .so(scan0_6),
    .grst_l(spc_grst_l),
    .arst_l(cmp_arst_l),
    .lsu_ffu_st_dtlb_perr_g(lsu_ffu_st_dtlb_perr_g),
    .exu_ffu_ist_e(ifu_lsu_st_inst_e),
    .ifu_ffu_tid_d(ifu_tlu_thrid_d[1:0]),
    .cpx_fpu_data(cpx_spc_data_cx2_buf[63:0]),
    .cpx_vld(cpx_spc_data_cx2_buf[144]),
    .cpx_fcmp(cpx_spc_data_cx2_buf[69]),
    .cpx_req(cpx_spc_data_cx2_buf[143:140]),
    .cpx_fccval(cpx_spc_data_cx2_buf[68:67]),
    .cpx_fpexc(cpx_spc_data_cx2_buf[76:72]),
    .exu_ffu_gsr_mask_m(exu_tlu_wsr_data_m[63:32]),
    .exu_ffu_gsr_scale_m(exu_tlu_wsr_data_m[7:3]),
    .exu_ffu_gsr_align_m(exu_tlu_wsr_data_m[2:0]),
    .exu_ffu_gsr_rnd_m(exu_tlu_wsr_data_m[27:25]),
    .ifu_ffu_ldst_single_d(ifu_ffu_ldst_size_d),
    .ffu_lsu_data(ffu_lsu_data[80:0]),
    .ffu_ifu_cc_vld_w2(ffu_ifu_cc_vld_w2[3:0]),
    .ffu_ifu_cc_w2(ffu_ifu_cc_w2[7:0]),
    .ffu_ifu_ecc_ce_w2(ffu_ifu_ecc_ce_w2),
    .ffu_ifu_ecc_ue_w2(ffu_ifu_ecc_ue_w2),
    .ffu_ifu_err_reg_w2(ffu_ifu_err_reg_w2[5:0]),
    .ffu_ifu_err_synd_w2(ffu_ifu_err_synd_w2[13:0]),
    .ffu_ifu_fpop_done_w2(ffu_ifu_fpop_done_w2),
    .ffu_ifu_fst_ce_w(ffu_ifu_fst_ce_w),
    .ffu_ifu_inj_ack(ffu_ifu_inj_ack),
    .ffu_ifu_stallreq(ffu_ifu_stallreq),
    .ffu_ifu_tid_w2(ffu_ifu_tid_w2[1:0]),
    .ffu_lsu_blk_st_e(ffu_lsu_blk_st_e),
    .ffu_lsu_blk_st_va_e(ffu_lsu_blk_st_va_e[5:3]),
    .ffu_lsu_fpop_rq_vld(ffu_lsu_fpop_rq_vld),
    .ffu_lsu_kill_fst_w(ffu_lsu_kill_fst_w),
    .ffu_tlu_fpu_cmplt(ffu_tlu_fpu_cmplt),
    .ffu_tlu_fpu_tid(ffu_tlu_fpu_tid[1:0]),
    .ffu_tlu_ill_inst_m(ffu_tlu_ill_inst_m),
    .ffu_tlu_trap_ieee754(ffu_tlu_trap_ieee754),
    .ffu_tlu_trap_other(ffu_tlu_trap_other),
    .ffu_tlu_trap_ue(ffu_tlu_trap_ue),
    .ffu_exu_rsr_data_m(ffu_exu_rsr_data_m[63:0]),
    .mux_drive_disable(mux_drive_disable),
    .mem_write_disable(mem_write_disable),
    .exu_ffu_wsr_inst_e(exu_ffu_wsr_inst_e),
    .ifu_exu_disable_ce_e(ifu_exu_disable_ce_e),
    .ifu_exu_ecc_mask(ifu_exu_ecc_mask[6:0]),
    .ifu_exu_nceen_e(ifu_exu_nceen_e),
    .ifu_ffu_fcc_num_d(ifu_ffu_fcc_num_d[1:0]),
    .ifu_ffu_fld_d(ifu_ffu_fld_d),
    .ifu_ffu_fpop1_d(ifu_ffu_fpop1_d),
    .ifu_ffu_fpop2_d(ifu_ffu_fpop2_d),
    .ifu_ffu_fpopcode_d(ifu_ffu_fpopcode_d[8:0]),
    .ifu_ffu_frd_d(ifu_ffu_frd_d[4:0]),
    .ifu_ffu_frs1_d(ifu_ffu_frs1_d[4:0]),
    .ifu_ffu_frs2_d(ifu_ffu_frs2_d[4:0]),
    .ifu_ffu_fst_d(ifu_ffu_fst_d),
    .ifu_ffu_inj_frferr(ifu_ffu_inj_frferr),
    .ifu_ffu_ldfsr_d(ifu_ffu_ldfsr_d),
    .ifu_ffu_ldxfsr_d(ifu_ffu_ldxfsr_d),
    .ifu_ffu_mvcnd_m(ifu_ffu_mvcnd_m),
    .ifu_ffu_quad_op_e(ifu_ffu_quad_op_e),
    .ifu_ffu_stfsr_d(ifu_ffu_stfsr_d),
    .ifu_ffu_visop_d(ifu_ffu_visop_d),
    .ifu_lsu_ld_inst_e(ifu_lsu_ld_inst_e),
    .ifu_tlu_flsh_inst_e(ifu_tlu_flsh_inst_e),
    .ifu_tlu_flush_w(ifu_tlu_flush_w),
    .ifu_tlu_inst_vld_w(ifu_tlu_inst_vld_w),
    .ifu_tlu_sraddr_d(ifu_tlu_sraddr_d[6:0]),
    .lsu_ffu_ack(lsu_ffu_ack),
    .lsu_ffu_bld_cnt_w(lsu_ffu_bld_cnt_w[2:0]),
    .lsu_ffu_blk_asi_e(lsu_ffu_blk_asi_e),
    .lsu_ffu_flush_pipe_w(lsu_ffu_flush_pipe_w),
    .lsu_ffu_ld_data(lsu_ffu_ld_data[63:0]),
    .lsu_ffu_ld_vld(lsu_ffu_ld_vld),
    .lsu_ffu_stb_full0(lsu_ffu_stb_full0),
    .lsu_ffu_stb_full1(lsu_ffu_stb_full1),
    .lsu_ffu_stb_full2(lsu_ffu_stb_full2),
    .lsu_ffu_stb_full3(lsu_ffu_stb_full3),
    .rclk(rclk),
    .se(se),
    .sehold(sehold)
  );


  test_stub_bist
  test_stub
  (
    .so_2(),
    .long_chain_so_2(1'b0),
    .short_chain_so_2(1'b0),
    .si(ctu_tst_scanmode),
    .so(scan1_5),
    .long_chain_so_0(scan0_7),
    .short_chain_so_0(short_scan0_6),
    .long_chain_so_1(scan1_5),
    .short_chain_so_1(short_scan1_4),
    .bist_ctl_reg_in(bist_ctl_reg_in[6:0]),
    .mux_drive_disable(mux_drive_disable),
    .mem_write_disable(mem_write_disable),
    .sehold(sehold),
    .se(se),
    .testmode_l(testmode_l),
    .mem_bypass(),
    .so_0(spc_scanout0),
    .so_1(spc_scanout1),
    .tst_ctu_mbist_done(tst_ctu_mbist_done),
    .tst_ctu_mbist_fail(tst_ctu_mbist_fail),
    .bist_ctl_reg_out(bist_ctl_reg_out[10:0]),
    .mbist_bisi_mode(mbist_bisi_mode),
    .mbist_stop_on_next_fail(mbist_stop_on_next_fail),
    .mbist_stop_on_fail(mbist_stop_on_fail),
    .mbist_loop_mode(mbist_loop_mode),
    .mbist_loop_on_addr(mbist_loop_on_addr),
    .mbist_data_mode(mbist_userdata_mode),
    .mbist_start(mbist_start),
    .ctu_tst_pre_grst_l(ctu_tst_pre_grst_l),
    .arst_l(cmp_arst_l),
    .cluster_grst_l(spc_grst_l),
    .global_shift_enable(global_shift_enable),
    .ctu_tst_scan_disable(ctu_tst_scan_disable),
    .ctu_tst_scanmode(scan1_4),
    .ctu_tst_macrotest(ctu_tst_macrotest),
    .ctu_tst_short_chain(ctu_tst_short_chain),
    .ctu_tst_mbist_enable(ctu_tst_mbist_enable),
    .rclk(rclk),
    .bist_ctl_reg_wr_en(bist_ctl_reg_wr_en),
    .mbist_done(mbist_done),
    .mbist_err({ 1'b0, mbist_dcache_fail, mbist_icache_fail })
  );


  bw_clk_cl_sparc_cmp
  spc_hdr
  (
    .cluster_grst_l(spc_grst_l),
    .dbginit_l(spc_dbginit_l),
    .rclk(rclk),
    .so(scan0_7),
    .adbginit_l(adbginit_l),
    .arst_l(cmp_arst_l),
    .cluster_cken(cluster_cken),
    .gclk(gclk),
    .gdbginit_l(gdbginit_l),
    .grst_l(cmp_grst_l),
    .se(se),
    .si(scan0_6)
  );


endmodule

