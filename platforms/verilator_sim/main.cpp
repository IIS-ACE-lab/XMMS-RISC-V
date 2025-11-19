#include VMURAX_H

#include VMURAX_MURAX_H

#include "verilated.h"
#include "verilated_vcd_c.h"

#include "common/framework.h"
#include "common/jtag.h"
#include "common/uart.h"

#define PERIOD 100000
#define BAUDRATE 9600

class MuraxWorkspace : public Workspace<VMURAX>{
public:
	MuraxWorkspace() : Workspace("Murax"){
		//ClockDomain *mainClk = new ClockDomain(&top->io_mainClk,NULL,100000,100000);
		//AsyncReset *asyncReset = new AsyncReset(&top->io_asyncReset,1000000);
		//UartRx *uartRx = new UartRx(&top->io_uart_txd,1.0e10/9600);
		//UartTx *uartTx = new UartTx(&top->io_uart_rxd,1.0e10/9600);

      ClockDomain *mainClk = new ClockDomain(&top->io_mainClk,NULL,PERIOD,PERIOD);
      AsyncReset *asyncReset = new AsyncReset(&top->io_asyncReset,PERIOD*10);
      UartRx *uartRx = new UartRx(&top->io_uart_txd,1.0e12/BAUDRATE);
      UartTx *uartTx = new UartTx(&top->io_uart_rxd,1.0e12/BAUDRATE);


//		UartRx *uartRx = new UartRx(&top->io_uart_txd,1.0e12/9600);
//		UartTx *uartTx = new UartTx(&top->io_uart_rxd,1.0e12/9600);

		timeProcesses.push_back(mainClk);
		timeProcesses.push_back(asyncReset);
		timeProcesses.push_back(uartRx);
		timeProcesses.push_back(uartTx);

		Jtag *jtag = new Jtag(&top->io_jtag_tms,&top->io_jtag_tdi,&top->io_jtag_tdo,&top->io_jtag_tck,PERIOD*4);
		timeProcesses.push_back(jtag);

		#ifdef TRACE
		//speedFactor = 10e-3;
		//cout << "Simulation caped to " << speedFactor << " of real time"<< endl;
		#endif
	}
};


struct timespec timer_start(){
    struct timespec start_time;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &start_time);
    return start_time;
}

long timer_end(struct timespec start_time){
    struct timespec end_time;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end_time);
    uint64_t diffInNanos = end_time.tv_sec*1e9 + end_time.tv_nsec -  start_time.tv_sec*1e9 - start_time.tv_nsec;
    return diffInNanos;
}



int main(int argc, char **argv, char **env) {

	Verilated::randReset(2);
	Verilated::commandArgs(argc, argv);

	printf("BOOT\n");
	timespec startedAt = timer_start();

	MuraxWorkspace().run(100e6);

	uint64_t duration = timer_end(startedAt);
	cout << endl << "****************************************************************" << endl;
	cout << "Had simulate " << workspaceCycles << " clock cycles in " << duration*1e-9 << " s (" << workspaceCycles / (duration*1e-9) << " Khz)" << endl;
	cout << "****************************************************************" << endl << endl;


	exit(0);
}
