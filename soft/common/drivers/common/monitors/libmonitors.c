#include "monitors.h"

void mem_barrier()
{
#ifdef __riscv
		__asm__ __volatile__("fence\n");
#else
		__asm__ __volatile__("stbar\n");
#endif

}

#ifdef LINUX
void *mon_alloc_head = NULL;
void *monitor_base_ptr = NULL;
int mapped = 0;

void mmap_monitors()
{
	int fd = open("/dev/mem", O_RDWR);
	monitor_base_ptr = mmap(NULL, SOC_ROWS * SOC_COLS * MONITOR_TILE_SIZE
							, PROT_READ | PROT_WRITE, MAP_SHARED, fd, MONITOR_BASE_ADDR);
	close(fd);
}

void munmap_monitors()
{
	munmap(monitor_base_ptr, SOC_ROWS * SOC_COLS * MONITOR_TILE_SIZE);
}
#endif

unsigned int read_monitor(int tile_no, int mon_no)
{
	unsigned int offset = (MONITOR_TILE_SIZE / sizeof(unsigned int)) * tile_no;
#ifdef LINUX
	unsigned int *addr = ((unsigned int *) monitor_base_ptr) + offset + mon_no + 1;
#else
	unsigned int *addr = ((unsigned int *) MONITOR_BASE_ADDR) + offset + mon_no + 1;
#endif
	return *addr;
}

void write_burst_reg(int tile_no, int val)
{
	unsigned int offset = (MONITOR_TILE_SIZE / sizeof(unsigned int)) * tile_no;
#ifdef LINUX
	unsigned int *addr = ((unsigned int *) monitor_base_ptr) + offset;
#else
	unsigned int *addr = ((unsigned int *) MONITOR_BASE_ADDR) + offset;
#endif
	*addr = val;
}

unsigned int esp_monitor(esp_monitor_args_t args, esp_monitor_vals_t *vals)
{
#include "soc_locs.h"

	int tile, t, p, q;

#ifdef LINUX
	if (!mapped) {
		mmap_monitors();
		mapped = 1;
	}
#endif

	if (args.read_mode == ESP_MON_READ_SINGLE){

		return read_monitor(args.tile_index, args.mon_index);

	} else if (args.read_mode == ESP_MON_READ_ALL){

		for (t = 0; t < SOC_NTILES; t++)
			write_burst_reg(t, 1);

		mem_barrier();

		//ddr accesses
		for (t = 0; t < SOC_NMEM; t++)
			vals->ddr_accesses[t] =
				read_monitor(mem_locs[t].row * SOC_COLS + mem_locs[t].col, MON_DDR_WORD_TRANSFER_INDEX);

		//mem_reqs
		for (t = 0; t < SOC_NMEM; t++){
			tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
			vals->mem_reqs[t].coh_reqs = read_monitor(tile, MON_MEM_COH_REQ_INDEX);
			vals->mem_reqs[t].coh_fwds = read_monitor(tile, MON_MEM_COH_FWD_INDEX);
			vals->mem_reqs[t].coh_rsps_rcv = read_monitor(tile, MON_MEM_COH_RSP_RCV_INDEX);
			vals->mem_reqs[t].coh_rsps_snd = read_monitor(tile, MON_MEM_COH_RSP_SND_INDEX);
			vals->mem_reqs[t].dma_reqs = read_monitor(tile, MON_MEM_DMA_REQ_INDEX);
			vals->mem_reqs[t].dma_rsps = read_monitor(tile, MON_MEM_DMA_RSP_INDEX);
			vals->mem_reqs[t].coh_dma_reqs = read_monitor(tile, MON_MEM_COH_DMA_REQ_INDEX);
			vals->mem_reqs[t].coh_dma_rsps = read_monitor(tile, MON_MEM_COH_DMA_RSP_INDEX);
		}

		//l2 stats
		for (t = 0; t < SOC_NCPU; t++) {
			tile = cpu_locs[t].row * SOC_COLS + cpu_locs[t].col;
			vals->l2_stats[tile].hits = read_monitor(tile, MON_L2_HIT_INDEX);
			vals->l2_stats[tile].misses = read_monitor(tile, MON_L2_MISS_INDEX);
		}
#ifdef ACCS_PRESENT
		for (t = 0; t < SOC_NACC; t++) {
			if (acc_has_l2[t]) {
				tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
				vals->l2_stats[tile].hits = read_monitor(tile, MON_L2_HIT_INDEX);
				vals->l2_stats[tile].misses = read_monitor(tile, MON_L2_MISS_INDEX);
			}
		}
#endif

		//llc stats
		for (t = 0; t < SOC_NMEM; t++) {
			tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
			vals->l2_stats[tile].hits = read_monitor(tile, MON_LLC_HIT_INDEX);
			vals->l2_stats[tile].misses = read_monitor(tile, MON_LLC_MISS_INDEX);
		}

		//acc stats
#ifdef ACCS_PRESENT
		for (t = 0; t < SOC_NACC; t++) {
			tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
			vals->acc_stats[t].acc_tlb = read_monitor(tile, MON_ACC_TLB_INDEX);
			vals->acc_stats[t].acc_mem_lo = read_monitor(tile, MON_ACC_MEM_LO_INDEX);
			vals->acc_stats[t].acc_mem_hi = read_monitor(tile, MON_ACC_MEM_HI_INDEX);
			vals->acc_stats[t].acc_tot_lo = read_monitor(tile, MON_ACC_TOT_LO_INDEX);
			vals->acc_stats[t].acc_tot_hi = read_monitor(tile, MON_ACC_TOT_HI_INDEX);
			vals->acc_stats[t].acc_roundtrip_time = read_monitor(tile, MON_ACC_ROUNDTRIP_TIME); //GM change
		}

#endif

		//dvfs
		for (p = 0; p < DVFS_OP_POINTS; p++)
			for (t = 0; t < SOC_NTILES; t++)
			vals->dvfs_op[t][p] = read_monitor(t, MON_DVFS_BASE_INDEX + p);

		//noc inject
		for (p = 0; p < NOC_PLANES; p++)
			for (t = 0; t < SOC_NTILES; t++)
			vals->noc_injects[t][p] = read_monitor(t, MON_NOC_TILE_INJECT_BASE_INDEX + p);

		//GM change: noc eject
		for (p = 0; p < NOC_PLANES; p++)
			for (t = 0; t < SOC_NTILES; t++)
			vals->noc_ejects[t][p] = read_monitor(t, MON_NOC_TILE_EJECT_BASE_INDEX + p);

		//noc queue full tile
		for (p = 0; p < NOC_PLANES; p++)
			for (q = 0; q < NOC_QUEUES; q++)
				for (t = 0; t < SOC_NTILES; t++)
					vals->noc_queue_full[t][p][q] =
						read_monitor(t, MON_NOC_QUEUES_FULL_BASE_INDEX + p * NOC_QUEUES + q);

		mem_barrier();

		for (t = 0; t < SOC_NTILES; t++)
			write_burst_reg(t, 0);

		return 0;

	} else {

		memset(vals, 0, sizeof(esp_monitor_vals_t));
		for (t = 0; t < SOC_NTILES; t++)
			write_burst_reg(t, 1);

		mem_barrier();

		//ddr accesses
		if (args.read_mask & (1 << ESP_MON_READ_DDR_ACCESSES))
			for (t = 0; t < SOC_NMEM; t++)
				vals->ddr_accesses[t] =
					read_monitor(mem_locs[t].row * SOC_COLS + mem_locs[t].col, MON_DDR_WORD_TRANSFER_INDEX);

		//mem_reqs
		if (args.read_mask & (1 << ESP_MON_READ_MEM_REQS))
			for (t = 0; t < SOC_NMEM; t++){
				tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
				vals->mem_reqs[t].coh_reqs = read_monitor(tile, MON_MEM_COH_REQ_INDEX);
				vals->mem_reqs[t].coh_fwds = read_monitor(tile, MON_MEM_COH_FWD_INDEX);
				vals->mem_reqs[t].coh_rsps_rcv = read_monitor(tile, MON_MEM_COH_RSP_RCV_INDEX);
				vals->mem_reqs[t].coh_rsps_snd = read_monitor(tile, MON_MEM_COH_RSP_SND_INDEX);
				vals->mem_reqs[t].dma_reqs = read_monitor(tile, MON_MEM_DMA_REQ_INDEX);
				vals->mem_reqs[t].dma_rsps = read_monitor(tile, MON_MEM_DMA_RSP_INDEX);
				vals->mem_reqs[t].coh_dma_reqs = read_monitor(tile, MON_MEM_COH_DMA_REQ_INDEX);
				vals->mem_reqs[t].coh_dma_rsps = read_monitor(tile, MON_MEM_COH_DMA_RSP_INDEX);
			}

		//l2 stats
		if (args.read_mask & (1 << ESP_MON_READ_L2_STATS)) {
			for (t = 0; t < SOC_NCPU; t++) {
				tile = cpu_locs[t].row * SOC_COLS + cpu_locs[t].col;
				vals->l2_stats[tile].hits = read_monitor(tile, MON_L2_HIT_INDEX);
				vals->l2_stats[tile].misses = read_monitor(tile, MON_L2_MISS_INDEX);
			}
#ifdef ACCS_PRESENT
			for (t = 0; t < SOC_NACC; t++) {
				if (acc_has_l2[t]) {
					tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
					vals->l2_stats[tile].hits = read_monitor(tile, MON_L2_HIT_INDEX);
					vals->l2_stats[tile].misses = read_monitor(tile, MON_L2_MISS_INDEX);
				}
			}
#endif
		}

		//llc stats
		if (args.read_mask & (1 << ESP_MON_READ_LLC_STATS))
			for (t = 0; t < SOC_NMEM; t++) {
				tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
				vals->l2_stats[tile].hits = read_monitor(tile, MON_LLC_HIT_INDEX);
				vals->l2_stats[tile].misses = read_monitor(tile, MON_LLC_MISS_INDEX);
			}

		//acc stats
#ifdef ACCS_PRESENT
		if (args.read_mask & (1 << ESP_MON_READ_ACC_STATS)) {
			tile = acc_locs[args.acc_index].row * SOC_COLS + acc_locs[args.acc_index].col;
			vals->acc_stats[args.acc_index].acc_tlb = read_monitor(tile, MON_ACC_TLB_INDEX);
			vals->acc_stats[args.acc_index].acc_mem_lo = read_monitor(tile, MON_ACC_MEM_LO_INDEX);
			vals->acc_stats[args.acc_index].acc_mem_hi = read_monitor(tile, MON_ACC_MEM_HI_INDEX);
			vals->acc_stats[args.acc_index].acc_tot_lo = read_monitor(tile, MON_ACC_TOT_LO_INDEX);
			vals->acc_stats[args.acc_index].acc_tot_hi = read_monitor(tile, MON_ACC_TOT_HI_INDEX);
			vals->acc_stats[args.acc_index].acc_roundtrip_time = read_monitor(tile, MON_ACC_ROUNDTRIP_TIME); //GM change
		}
#endif

		//dvfs
		if (args.read_mask & (1 << ESP_MON_READ_DVFS_OP))
			for (p = 0; p < DVFS_OP_POINTS; p++)
				vals->dvfs_op[args.tile_index][p] = read_monitor(args.tile_index, MON_DVFS_BASE_INDEX + p);

		//noc inject
		if (args.read_mask & (1 << ESP_MON_READ_NOC_INJECTS))
			for (p = 0; p < NOC_PLANES; p++)
				vals->noc_injects[args.tile_index][p] =
					read_monitor(args.tile_index, MON_NOC_TILE_INJECT_BASE_INDEX + p);

		//GM change: noc eject
		if (args.read_mask & (1 << ESP_MON_READ_NOC_EJECTS))
			for (p = 0; p < NOC_PLANES; p++)
				vals->noc_ejects[args.tile_index][p] =
					read_monitor(args.tile_index, MON_NOC_TILE_EJECT_BASE_INDEX + p);

		//noc queue full tile
		if (args.read_mask & (1 << ESP_MON_READ_NOC_QUEUE_FULL_TILE))
			for (p = 0; p < NOC_PLANES; p++)
				for (q = 0; q < NOC_QUEUES; q++)
					vals->noc_queue_full[args.tile_index][p][q] =
						read_monitor(args.tile_index, MON_NOC_QUEUES_FULL_BASE_INDEX + p * NOC_QUEUES + q);

		if (args.read_mask & (1 << ESP_MON_READ_NOC_QUEUE_FULL_PLANE))
			for (q = 0; q < NOC_QUEUES; q++)
				for (t = 0; t < SOC_NTILES; t++)
					vals->noc_queue_full[t][args.noc_index][q] =
						read_monitor(t, MON_NOC_QUEUES_FULL_BASE_INDEX + args.noc_index * NOC_QUEUES + q);

		mem_barrier();

		for (t = 0; t < SOC_NTILES; t++)
			write_burst_reg(t, 0);

		 return 0;

	}
}

//GM change: custom function to measure only the injection/ejection statistics, on all tiles and all planes
unsigned int esp_monitor_transit_all(esp_monitor_vals_t *vals)
{
	int t, p;
	for (t = 0; t < SOC_NTILES; t++)
			write_burst_reg(t, 1);

	mem_barrier();

	//noc inject
	for (p = 0; p < NOC_PLANES; p++)
		for (t = 0; t < SOC_NTILES; t++)
		vals->noc_injects[t][p] = read_monitor(t, MON_NOC_TILE_INJECT_BASE_INDEX + p);

	//GM change: noc eject
	for (p = 0; p < NOC_PLANES; p++)
		for (t = 0; t < SOC_NTILES; t++)
		vals->noc_ejects[t][p] = read_monitor(t, MON_NOC_TILE_EJECT_BASE_INDEX + p);

	mem_barrier();

	for (t = 0; t < SOC_NTILES; t++)
		write_burst_reg(t, 0);

	return 0;
}

//GM change: custom function to monitor injection/ejection statistics only on the first plane
unsigned int esp_monitor_transit_1plane(esp_monitor_vals_t *vals)
{
	int t;
	for (t = SOC_NTILES-1; t >= 0; t--)
		write_burst_reg(t, 1);

	mem_barrier();

	//noc inject

	for (t = 0; t < SOC_NTILES; t++)
		vals->noc_injects[t][0] = read_monitor(t, MON_NOC_TILE_INJECT_BASE_INDEX);

	//GM change: noc eject
	for (t = 0; t < SOC_NTILES; t++)
		vals->noc_ejects[t][0] = read_monitor(t, MON_NOC_TILE_EJECT_BASE_INDEX);

	mem_barrier();

	for (t = 0; t < SOC_NTILES; t++)
		write_burst_reg(t, 0);

	return 0;
}

//GM change: custom function to measure only the backpressure, on all tiles and all planes
unsigned int esp_monitor_backpressure_all(esp_monitor_vals_t *vals)
{
	int t, p, q;

	for (t = 0; t < SOC_NTILES; t++)
		write_burst_reg(t, 1);

	mem_barrier();
	//noc queue full tile
	for (p = 0; p < NOC_PLANES; p++)
		for (q = 0; q < NOC_QUEUES; q++)
			for (t = 0; t < SOC_NTILES; t++)
				vals->noc_queue_full[t][p][q] =
					read_monitor(t, MON_NOC_QUEUES_FULL_BASE_INDEX + p * NOC_QUEUES + q);

	mem_barrier();

	for (t = 0; t < SOC_NTILES; t++)
		write_burst_reg(t, 0);

	return 0;
}

//GM change: custom function to measure only the injection/ejection statistics, on one tile and all planes
unsigned int esp_monitor_transit_1tile(esp_monitor_vals_t *vals, int tile)
{
	int p;
	write_burst_reg(tile, 1);

	mem_barrier();

	//noc inject
	for (p = 0; p < NOC_PLANES; p++)
		vals->noc_injects[tile][p] = read_monitor(tile, MON_NOC_TILE_INJECT_BASE_INDEX + p);

	//GM change: noc eject
	for (p = 0; p < NOC_PLANES; p++)
		vals->noc_ejects[tile][p] = read_monitor(tile, MON_NOC_TILE_EJECT_BASE_INDEX + p);

	mem_barrier();

	write_burst_reg(tile, 0);

	return 0;
}

//GM change: custom function to monitor the roundtrip time on just one tile
unsigned int esp_monitor_rtt_1tile(int tile)
{
	return read_monitor(tile, MON_ACC_ROUNDTRIP_TIME);
}


uint32_t sub_monitor_vals (uint32_t val_start, uint32_t val_end)
{
	if (val_end >= val_start)
		return val_end - val_start;
	else
		return (0xFFFFFFFF - val_start + val_end);
}

esp_monitor_vals_t esp_monitor_diff(esp_monitor_vals_t vals_start, esp_monitor_vals_t vals_end)
{
#include "soc_locs.h"

	esp_monitor_vals_t vals_diff;
	int t, p, q, tile;

	for (t = 0; t < SOC_NMEM; t++)
		vals_diff.ddr_accesses[t] = sub_monitor_vals(vals_start.ddr_accesses[t], vals_end.ddr_accesses[t]);

	//mem_reqs
	for (t = 0; t < SOC_NMEM; t++){
		tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
		vals_diff.mem_reqs[t].coh_reqs =
			sub_monitor_vals(vals_start.mem_reqs[t].coh_reqs, vals_end.mem_reqs[t].coh_reqs);
		vals_diff.mem_reqs[t].coh_fwds =
			sub_monitor_vals(vals_start.mem_reqs[t].coh_fwds, vals_end.mem_reqs[t].coh_fwds);
		vals_diff.mem_reqs[t].coh_rsps_rcv =
			sub_monitor_vals(vals_start.mem_reqs[t].coh_rsps_rcv, vals_end.mem_reqs[t].coh_rsps_rcv);
		vals_diff.mem_reqs[t].coh_rsps_snd =
			sub_monitor_vals(vals_start.mem_reqs[t].coh_rsps_snd, vals_end.mem_reqs[t].coh_rsps_snd);
		vals_diff.mem_reqs[t].dma_reqs =
			sub_monitor_vals(vals_start.mem_reqs[t].dma_reqs, vals_end.mem_reqs[t].dma_reqs);
		vals_diff.mem_reqs[t].dma_rsps =
			sub_monitor_vals(vals_start.mem_reqs[t].dma_rsps, vals_end.mem_reqs[t].dma_rsps);
		vals_diff.mem_reqs[t].coh_dma_reqs =
			sub_monitor_vals(vals_start.mem_reqs[t].coh_dma_reqs, vals_end.mem_reqs[t].coh_dma_reqs);
		vals_diff.mem_reqs[t].coh_dma_rsps =
			sub_monitor_vals(vals_start.mem_reqs[t].coh_dma_rsps, vals_end.mem_reqs[t].coh_dma_rsps);
	}

	//l2 stats
	for (t = 0; t < SOC_NCPU; t++) {
		tile = cpu_locs[t].row * SOC_COLS + cpu_locs[t].col;
		vals_diff.l2_stats[tile].hits =
			sub_monitor_vals(vals_start.l2_stats[tile].hits, vals_end.l2_stats[tile].hits);
		vals_diff.l2_stats[tile].misses =
			sub_monitor_vals(vals_start.l2_stats[tile].misses, vals_end.l2_stats[tile].misses);
	}
#ifdef ACCS_PRESENT
	for (t = 0; t < SOC_NACC; t++) {
		if (acc_has_l2[t]) {
			tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
			vals_diff.l2_stats[tile].hits =
				sub_monitor_vals(vals_start.l2_stats[tile].hits, vals_end.l2_stats[tile].hits);
			vals_diff.l2_stats[tile].misses =
				sub_monitor_vals(vals_start.l2_stats[tile].misses, vals_end.l2_stats[tile].misses);
		}
	}
#endif

	//llc stats
	for (t = 0; t < SOC_NMEM; t++) {
		tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
		vals_diff.l2_stats[tile].hits =
			sub_monitor_vals(vals_start.l2_stats[tile].hits, vals_end.l2_stats[tile].hits);
		vals_diff.l2_stats[tile].misses =
			sub_monitor_vals(vals_start.l2_stats[tile].misses, vals_end.l2_stats[tile].misses);
	}

	//acc stats
#ifdef ACCS_PRESENT
	for (t = 0; t < SOC_NACC; t++) {
		tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
		//accelerator counters are cleared at the start of an invocation, so merely report the final count
		vals_diff.acc_stats[t].acc_tlb = sub_monitor_vals(vals_start.acc_stats[t].acc_tlb, vals_end.acc_stats[t].acc_tlb);
		vals_diff.acc_stats[t].acc_mem_lo = sub_monitor_vals(vals_start.acc_stats[t].acc_mem_lo, vals_end.acc_stats[t].acc_mem_lo);
		vals_diff.acc_stats[t].acc_mem_hi = sub_monitor_vals(vals_start.acc_stats[t].acc_mem_hi, vals_end.acc_stats[t].acc_mem_hi);
		vals_diff.acc_stats[t].acc_tot_lo = sub_monitor_vals(vals_start.acc_stats[t].acc_tot_lo, vals_end.acc_stats[t].acc_tot_lo);
		vals_diff.acc_stats[t].acc_tot_hi = sub_monitor_vals(vals_start.acc_stats[t].acc_tot_hi, vals_end.acc_stats[t].acc_tot_hi);
	}

#endif

	//dvfs
	for (p = 0; p < DVFS_OP_POINTS; p++)
		for (t = 0; t < SOC_NTILES; t++)
		vals_diff.dvfs_op[t][p] =
			sub_monitor_vals(vals_start.dvfs_op[t][p], vals_end.dvfs_op[t][p]);

	//noc inject
	for (p = 0; p < NOC_PLANES; p++)
		for (t = 0; t < SOC_NTILES; t++)
		vals_diff.noc_injects[t][p] =
			sub_monitor_vals(vals_start.noc_injects[t][p], vals_end.noc_injects[t][p]);

	//GM change: noc eject
	for (p = 0; p < NOC_PLANES; p++)
		for (t = 0; t < SOC_NTILES; t++)
		vals_diff.noc_ejects[t][p] =
			sub_monitor_vals(vals_start.noc_ejects[t][p], vals_end.noc_ejects[t][p]);

	//noc queue full tile
	for (p = 0; p < NOC_PLANES; p++)
		for (q = 0; q < NOC_QUEUES; q++)
			for (t = 0; t < SOC_NTILES; t++)
				vals_diff.noc_queue_full[t][p][q] =
					sub_monitor_vals(vals_start.noc_queue_full[t][p][q], vals_end.noc_queue_full[t][p][q]);

	return vals_diff;
}

#ifdef LINUX
void esp_monitor_print(esp_monitor_args_t args, esp_monitor_vals_t vals, FILE *fp)
#else
void esp_monitor_print(esp_monitor_args_t args, esp_monitor_vals_t vals)
#endif
{
#include "soc_locs.h"

	int t, p, q, tile;

#ifdef LINUX
	printf("\tWriting esp_monitor stats to specified file...\n");
#endif

	print_mon( "\n***************************************************\n");
	print_mon( "******************ESP MONITOR STATS****************\n");
	print_mon( "***************************************************\n");

	print_mon( "\n********************MEMORY STATS*******************\n");
	if (args.read_mode == ESP_MON_READ_ALL || (args.read_mask & (1 << ESP_MON_READ_DDR_ACCESSES)))
		for (t = 0; t < SOC_NMEM; t++)
			print_mon( "Off-chip memory accesses at mem tile %d: %d\n", t, vals.ddr_accesses[t]);

	//mem_reqs
	if (args.read_mode == ESP_MON_READ_ALL || (args.read_mask & (1 << ESP_MON_READ_MEM_REQS)))
		for (t = 0; t < SOC_NMEM; t++){
			tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
			print_mon( "Coherence requests to LLC %d: %d\n", t, vals.mem_reqs[t].coh_reqs);
			print_mon( "Coherence forwards from LLC %d: %d\n", t, vals.mem_reqs[t].coh_fwds);
			print_mon( "Coherence responses received by LLC %d: %d\n", t, vals.mem_reqs[t].coh_rsps_rcv);
			print_mon( "Coherence responses sent by LLC %d: %d\n", t, vals.mem_reqs[t].coh_rsps_snd);
			print_mon( "DMA requests to mem tile %d: %d\n", t, vals.mem_reqs[t].dma_reqs);
			print_mon( "DMA responses from mem tile %d: %d\n", t, vals.mem_reqs[t].dma_rsps);
			print_mon( "Coherent DMA requests to LLC %d: %d\n", t, vals.mem_reqs[t].coh_dma_reqs);
			print_mon( "Coherent DMA responses from LLC %d: %d\n", t, vals.mem_reqs[t].coh_dma_rsps);
		}

	print_mon( "\n********************CACHE STATS********************\n");
	//l2 stats
	if (args.read_mode == ESP_MON_READ_ALL || (args.read_mask & (1 << ESP_MON_READ_L2_STATS))){
		for (t = 0; t < SOC_NCPU; t++) {
			tile = cpu_locs[t].row * SOC_COLS + cpu_locs[t].col;
			print_mon( "L2 hits for CPU %d: %d\n", t, vals.l2_stats[tile].hits);
			print_mon( "L2 misses for CPU %d: %d\n", t, vals.l2_stats[tile].misses);
		}
#ifdef ACCS_PRESENT
		for (t = 0; t < SOC_NACC; t++) {
			if (acc_has_l2[t]) {
				tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
				print_mon( "L2 hits for acc %d: %d\n", t, vals.l2_stats[tile].hits);
				print_mon( "L2 misses for acc %d: %d\n", t, vals.l2_stats[tile].misses);
			}
		}
#endif
	}

	//llc stats
	if (args.read_mode == ESP_MON_READ_ALL || (args.read_mask & (1 << ESP_MON_READ_LLC_STATS)))
		for (t = 0; t < SOC_NMEM; t++) {
			tile = mem_locs[t].row * SOC_COLS + mem_locs[t].col;
			print_mon( "Hits at LLC %d: %d\n", t, vals.l2_stats[tile].hits);
			print_mon( "Misses at LLC %d: %d\n", t, vals.l2_stats[tile].misses);
		}

	print_mon( "\n****************ACCELERATOR STATS******************\n");
	//acc stats
#ifdef ACCS_PRESENT
	if (args.read_mode == ESP_MON_READ_ALL){
		for (t = 0; t < SOC_NACC; t++) {
			tile = acc_locs[t].row * SOC_COLS + acc_locs[t].col;
			print_mon( "Accelerator %d TLB-loading cycles: %d\n", t, vals.acc_stats[t].acc_tlb);
			print_mon( "Accelerator %d mem cycles: %llu\n", t
					, ((unsigned long long) vals.acc_stats[t].acc_mem_lo)
					+ (((unsigned long long) vals.acc_stats[t].acc_mem_hi) << 32));
			print_mon( "Accelerator %d total cycles: %llu\n", t
					, ((unsigned long long) vals.acc_stats[t].acc_tot_lo)
					+ (((unsigned long long) vals.acc_stats[t].acc_tot_hi) << 32));
		}
	} else if (args.read_mask & (1 << ESP_MON_READ_LLC_STATS)) {
		print_mon( "Accelerator %d TLB-loading cycles: %d\n", t, vals.acc_stats[args.acc_index].acc_tlb);
		print_mon( "Accelerator %d mem cycles: %llu\n", t
				, ((unsigned long long) vals.acc_stats[args.acc_index].acc_mem_lo)
				+ (((unsigned long long) vals.acc_stats[args.acc_index].acc_mem_hi) << 32));
		print_mon( "Accelerator %d total cycles: %llu\n", t
				, ((unsigned long long) vals.acc_stats[args.acc_index].acc_tot_lo)
				+ (((unsigned long long) vals.acc_stats[args.acc_index].acc_tot_hi) << 32));
	}
#endif

	print_mon( "\n*********************DVFS STATS********************\n");
	//dvfs
	if (args.read_mode == ESP_MON_READ_ALL) {
		for (t = 0; t < SOC_NTILES; t++)
			for (p = 0; p < DVFS_OP_POINTS; p++)
				print_mon( "DVFS Cycles for tile %d at operating point %d: %d\n"
						, t, p, vals.dvfs_op[t][p]);
	} else if (args.read_mask & (1 << ESP_MON_READ_DVFS_OP)) {
		for (p = 0; p < DVFS_OP_POINTS; p++)
			print_mon( "DVFS Cycles for tile %d at operating point %d: %d\n"
					, args.tile_index, p, vals.dvfs_op[args.tile_index][p]);
   }

	print_mon( "\n*********************NOC STATS*********************\n");
	//noc inject
	if (args.read_mode == ESP_MON_READ_ALL) {
		for (t = 0; t < SOC_NTILES; t++)
			for (p = 0; p < NOC_PLANES; p++)
				print_mon( "NoC packets injected at tile %d on plane %d: %d\n"
						, t, p, vals.noc_injects[t][p]);
	} else if (args.read_mask & (1 << ESP_MON_READ_NOC_INJECTS)) {
		for (p = 0; p < NOC_PLANES; p++)
			print_mon( "NoC packets injected at tile %d on plane %d: %d\n"
					, args.tile_index, p, vals.noc_injects[args.tile_index][p]);
	}
	//GM change: noc eject
	if (args.read_mode == ESP_MON_READ_ALL) {
		for (t = 0; t < SOC_NTILES; t++)
			for (p = 0; p < NOC_PLANES; p++)
				print_mon( "NoC packets ejected at tile %d on plane %d: %d\n"
						, t, p, vals.noc_ejects[t][p]);
	} else if (args.read_mask & (1 << ESP_MON_READ_NOC_EJECTS)) {
		for (p = 0; p < NOC_PLANES; p++)
			print_mon( "NoC packets ejected at tile %d on plane %d: %d\n"
					, args.tile_index, p, vals.noc_ejects[args.tile_index][p]);
	}
	//noc queue full tile
	if (args.read_mode == ESP_MON_READ_ALL) {
		for (t = 0; t < SOC_NTILES; t++)
			for (p = 0; p < NOC_PLANES; p++)
				for (q = 0; q < NOC_QUEUES; q++)
					print_mon( "NoC backpressure cycles at tile %d on plane %d for queue %d: %d\n"
							, t, p, q, vals.noc_queue_full[t][p][q]);
	} else if (args.read_mask & (1 << ESP_MON_READ_NOC_QUEUE_FULL_TILE)) {
		 for (p = 0; p < NOC_PLANES; p++)
			for (q = 0; q < NOC_QUEUES; q++)
				print_mon( "NoC backpressure cycles at tile %d on plane %d for queue %d: %d\n"
						, args.tile_index, p, q, vals.noc_queue_full[args.tile_index][p][q]);
	} else if (args.read_mask & (1 << ESP_MON_READ_NOC_QUEUE_FULL_PLANE)) {
		for (t = 0; t < SOC_NTILES; t++)
			for (q = 0; q < NOC_QUEUES; q++)
				print_mon( "NoC backpressure cycles at tile %d on plane %d for queue %d: %d\n"
						, t, args.noc_index, q, vals.noc_queue_full[t][args.noc_index][q]);
	}
}

#ifdef LINUX
esp_monitor_vals_t* esp_monitor_vals_alloc()
{
	esp_monitor_vals_t *ptr = malloc(sizeof(esp_monitor_vals_t));
	esp_mon_alloc_node_t *node = malloc(sizeof(esp_mon_alloc_node_t));
	node->vals = ptr;
	node->next = mon_alloc_head;
	mon_alloc_head = node;
	return ptr;
}

void esp_monitor_free()
{
	munmap_monitors();

	esp_mon_alloc_node_t *cur = mon_alloc_head;
	esp_mon_alloc_node_t *next;
	while (cur) {
		next = cur->next;
		free(cur->vals);
		free(cur);
		cur = next;
	}
}
#endif