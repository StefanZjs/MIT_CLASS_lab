/*
 * Generated by Bluespec Compiler, version 2023.01 (build 52adafa5)
 * 
 * On Tue Oct 29 11:10:23 UTC 2024
 * 
 */
#include "bluesim_primitives.h"
#include "model_mkTbEx5.h"

#include <cstdlib>
#include <time.h>
#include "bluesim_kernel_api.h"
#include "bs_vcd.h"
#include "bs_reset.h"


/* Constructor */
MODEL_mkTbEx5::MODEL_mkTbEx5()
{
  mkTbEx5_instance = NULL;
}

/* Function for creating a new model */
void * new_MODEL_mkTbEx5()
{
  MODEL_mkTbEx5 *model = new MODEL_mkTbEx5();
  return (void *)(model);
}

/* Schedule functions */

static void schedule_posedge_CLK(tSimStateHdl simHdl, void *instance_ptr)
       {
	 MOD_mkTbEx5 &INST_top = *((MOD_mkTbEx5 *)(instance_ptr));
	 tUInt8 DEF_INST_top_DEF_tb_randomA_initialized__h4660;
	 tUInt8 DEF_INST_top_DEF_tb_randomB_initialized__h5036;
	 INST_top.DEF_x__h4071 = INST_top.INST_dut_i.METH_read();
	 INST_top.DEF_CAN_FIRE_RL_dut_mulStep = (INST_top.DEF_x__h4071) < (tUInt8)16u;
	 INST_top.DEF_WILL_FIRE_RL_dut_mulStep = INST_top.DEF_CAN_FIRE_RL_dut_mulStep;
	 INST_top.DEF_CAN_FIRE_RL_tb_monitor_test = (tUInt8)1u;
	 INST_top.DEF_WILL_FIRE_RL_tb_monitor_test = INST_top.DEF_CAN_FIRE_RL_tb_monitor_test;
	 INST_top.DEF_CAN_FIRE_RL_tb_randomA_every = (tUInt8)1u;
	 INST_top.DEF_WILL_FIRE_RL_tb_randomA_every = INST_top.DEF_CAN_FIRE_RL_tb_randomA_every;
	 DEF_INST_top_DEF_tb_randomA_initialized__h4660 = INST_top.INST_tb_randomA_initialized.METH_read();
	 INST_top.DEF_CAN_FIRE_RL_tb_randomA_every_1 = !DEF_INST_top_DEF_tb_randomA_initialized__h4660;
	 INST_top.DEF_WILL_FIRE_RL_tb_randomA_every_1 = INST_top.DEF_CAN_FIRE_RL_tb_randomA_every_1;
	 DEF_INST_top_DEF_tb_randomB_initialized__h5036 = INST_top.INST_tb_randomB_initialized.METH_read();
	 INST_top.DEF_CAN_FIRE_RL_tb_randomB_every_1 = !DEF_INST_top_DEF_tb_randomB_initialized__h5036;
	 INST_top.DEF_WILL_FIRE_RL_tb_randomB_every_1 = INST_top.DEF_CAN_FIRE_RL_tb_randomB_every_1;
	 INST_top.DEF_CAN_FIRE_RL_tb_randomB_every = (tUInt8)1u;
	 INST_top.DEF_WILL_FIRE_RL_tb_randomB_every = INST_top.DEF_CAN_FIRE_RL_tb_randomB_every;
	 INST_top.DEF_x__h67109 = INST_top.INST_tb_read_count.METH_read();
	 INST_top.DEF_dut_i_EQ_16___d171 = (INST_top.DEF_x__h4071) == (tUInt8)16u;
	 INST_top.DEF_tb_read_count_68_EQ_128___d169 = (INST_top.DEF_x__h67109) == 128u;
	 INST_top.DEF_CAN_FIRE_RL_tb_read = INST_top.INST_tb_operands_fifo.METH_i_notEmpty() && (!(INST_top.DEF_tb_read_count_68_EQ_128___d169) && INST_top.DEF_dut_i_EQ_16___d171);
	 INST_top.DEF_WILL_FIRE_RL_tb_read = INST_top.DEF_CAN_FIRE_RL_tb_read;
	 if (INST_top.DEF_WILL_FIRE_RL_dut_mulStep)
	   INST_top.RL_dut_mulStep();
	 if (INST_top.DEF_WILL_FIRE_RL_tb_randomA_every)
	   INST_top.RL_tb_randomA_every();
	 if (INST_top.DEF_WILL_FIRE_RL_tb_randomA_every_1)
	   INST_top.RL_tb_randomA_every_1();
	 if (INST_top.DEF_WILL_FIRE_RL_tb_randomB_every)
	   INST_top.RL_tb_randomB_every();
	 INST_top.DEF_x__h5455 = INST_top.INST_tb_feed_count.METH_read();
	 INST_top.DEF_x_wget__h4912 = INST_top.INST_tb_randomB_zaz.METH_wget();
	 INST_top.DEF_x_wget__h4535 = INST_top.INST_tb_randomA_zaz.METH_wget();
	 INST_top.DEF_v__h5042 = INST_top.INST_tb_randomB_zaz.METH_whas() ? INST_top.DEF_x_wget__h4912 : 0u;
	 INST_top.DEF_v__h4666 = INST_top.INST_tb_randomA_zaz.METH_whas() ? INST_top.DEF_x_wget__h4535 : 0u;
	 INST_top.DEF_IF_tb_randomA_zaz_whas__39_THEN_tb_randomA_zaz_ETC___d149 = (INST_top.DEF_v__h4666) == 32768u;
	 INST_top.DEF_IF_tb_randomB_zaz_whas__46_THEN_tb_randomB_zaz_ETC___d150 = (INST_top.DEF_v__h5042) == 32768u;
	 INST_top.DEF_CAN_FIRE_RL_tb_feed = ((DEF_INST_top_DEF_tb_randomA_initialized__h4660 && (DEF_INST_top_DEF_tb_randomB_initialized__h5036 && ((INST_top.DEF_IF_tb_randomA_zaz_whas__39_THEN_tb_randomA_zaz_ETC___d149 || INST_top.DEF_IF_tb_randomB_zaz_whas__46_THEN_tb_randomB_zaz_ETC___d150) || INST_top.INST_tb_operands_fifo.METH_i_notFull()))) && (!((INST_top.DEF_x__h5455) == 128u) && (INST_top.DEF_x__h4071) == (tUInt8)17u)) && !(INST_top.DEF_CAN_FIRE_RL_tb_randomA_every_1 || INST_top.DEF_CAN_FIRE_RL_dut_mulStep);
	 INST_top.DEF_WILL_FIRE_RL_tb_feed = INST_top.DEF_CAN_FIRE_RL_tb_feed;
	 if (INST_top.DEF_WILL_FIRE_RL_tb_feed)
	   INST_top.RL_tb_feed();
	 if (INST_top.DEF_WILL_FIRE_RL_tb_randomB_every_1)
	   INST_top.RL_tb_randomB_every_1();
	 if (INST_top.DEF_WILL_FIRE_RL_tb_monitor_test)
	   INST_top.RL_tb_monitor_test();
	 if (INST_top.DEF_WILL_FIRE_RL_tb_read)
	   INST_top.RL_tb_read();
	 INST_top.INST_tb_randomB_zaz.clk((tUInt8)1u, (tUInt8)1u);
	 INST_top.INST_tb_randomB_ignore.clk((tUInt8)1u, (tUInt8)1u);
	 INST_top.INST_tb_randomA_zaz.clk((tUInt8)1u, (tUInt8)1u);
	 INST_top.INST_tb_randomA_ignore.clk((tUInt8)1u, (tUInt8)1u);
	 if (do_reset_ticks(simHdl))
	 {
	   INST_top.INST_dut_i.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_tb_cycle.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_tb_feed_count.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_tb_read_count.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_tb_operands_fifo.rst_tick_clk((tUInt8)1u);
	   INST_top.INST_tb_randomA_initialized.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_tb_randomB_initialized.rst_tick__clk__1((tUInt8)1u);
	 }
       };

/* Model creation/destruction functions */

void MODEL_mkTbEx5::create_model(tSimStateHdl simHdl, bool master)
{
  sim_hdl = simHdl;
  init_reset_request_counters(sim_hdl);
  mkTbEx5_instance = new MOD_mkTbEx5(sim_hdl, "top", NULL);
  bk_get_or_define_clock(sim_hdl, "CLK");
  if (master)
  {
    bk_alter_clock(sim_hdl, bk_get_clock_by_name(sim_hdl, "CLK"), CLK_LOW, false, 0llu, 5llu, 5llu);
    bk_use_default_reset(sim_hdl);
  }
  bk_set_clock_event_fn(sim_hdl,
			bk_get_clock_by_name(sim_hdl, "CLK"),
			schedule_posedge_CLK,
			NULL,
			(tEdgeDirection)(POSEDGE));
  (mkTbEx5_instance->INST_tb_operands_fifo.set_clk_0)("CLK");
  (mkTbEx5_instance->INST_tb_randomA_ignore.set_clk_0)("CLK");
  (mkTbEx5_instance->INST_tb_randomA_zaz.set_clk_0)("CLK");
  (mkTbEx5_instance->INST_tb_randomB_ignore.set_clk_0)("CLK");
  (mkTbEx5_instance->INST_tb_randomB_zaz.set_clk_0)("CLK");
  (mkTbEx5_instance->set_clk_0)("CLK");
}
void MODEL_mkTbEx5::destroy_model()
{
  delete mkTbEx5_instance;
  mkTbEx5_instance = NULL;
}
void MODEL_mkTbEx5::reset_model(bool asserted)
{
  (mkTbEx5_instance->reset_RST_N)(asserted ? (tUInt8)0u : (tUInt8)1u);
}
void * MODEL_mkTbEx5::get_instance()
{
  return mkTbEx5_instance;
}

/* Fill in version numbers */
void MODEL_mkTbEx5::get_version(char const **name, char const **build)
{
  *name = "2023.01";
  *build = "52adafa5";
}

/* Get the model creation time */
time_t MODEL_mkTbEx5::get_creation_time()
{
  
  /* Tue Oct 29 11:10:23 UTC 2024 */
  return 1730200223llu;
}

/* State dumping function */
void MODEL_mkTbEx5::dump_state()
{
  (mkTbEx5_instance->dump_state)(0u);
}

/* VCD dumping functions */
MOD_mkTbEx5 & mkTbEx5_backing(tSimStateHdl simHdl)
{
  static MOD_mkTbEx5 *instance = NULL;
  if (instance == NULL)
  {
    vcd_set_backing_instance(simHdl, true);
    instance = new MOD_mkTbEx5(simHdl, "top", NULL);
    vcd_set_backing_instance(simHdl, false);
  }
  return *instance;
}
void MODEL_mkTbEx5::dump_VCD_defs()
{
  (mkTbEx5_instance->dump_VCD_defs)(vcd_depth(sim_hdl));
}
void MODEL_mkTbEx5::dump_VCD(tVCDDumpType dt)
{
  (mkTbEx5_instance->dump_VCD)(dt, vcd_depth(sim_hdl), mkTbEx5_backing(sim_hdl));
}
