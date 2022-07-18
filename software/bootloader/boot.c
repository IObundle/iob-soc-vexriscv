#include "system.h"
#include "iob-uart.h"

#ifdef RUN_EXTMEM
#include "iob-cache.h"
#endif

//defined here (and not in periphs.h) because it is the only peripheral used
//by the bootloader
#define UART16550_BASE (1<<P) |(UART16550<<(ADDR_W-2-N_SLAVES_W))

#define PROGNAME "IOb-Bootloader"

#define DC1 17 // Device Control 1 (used to indicate end of bootloader)

int main() {

  //init uart
  uart_init(UART16550_BASE, FREQ/(16*BAUD));

  //connect with console
  do {
    if(uart_txready())
      uart_putc((char) ENQ);
  } while(!uart_rxready());

  //welcome message
  uart_puts (PROGNAME);
  uart_puts (": connected!\n");

#ifdef USE_DDR
    uart_puts (PROGNAME);
    uart_puts(": DDR in use\n");
#endif

#ifdef RUN_EXTMEM
    uart_puts (PROGNAME);
    uart_puts(": program to run from DDR\n");
#endif

  // address to copy firmware to
  char *prog_start_addr;
#ifdef RUN_EXTMEM
    prog_start_addr = (char *) EXTRA_BASE;
#else
    prog_start_addr = (char *) (1<<BOOTROM_ADDR_W);
#endif

#ifdef RUN_LINUX
  //receive firmware from host
  int  file_size = 0;
  char opensbi[] = "fw_jump.bin";
  char kernel[]  = "Image";
  char dtb[]     = "iob_soc.dtb";
  char rootfs[]  = "rootfs.cpio.gz";
  if (uart_getc() == FRX) {//file receive: load firmware
    file_size = uart_recvfile(opensbi, prog_start_addr);
    prog_start_addr = (char *)(EXTRA_BASE + 0x00400000);
    file_size = uart_recvfile(kernel, prog_start_addr);
    prog_start_addr = (char *)(EXTRA_BASE + 0x00F80000);
    file_size = uart_recvfile(dtb, prog_start_addr);
    prog_start_addr = (char *)(EXTRA_BASE + 0x01000000);
    file_size = uart_recvfile(rootfs, prog_start_addr);
    uart_puts (PROGNAME);
    uart_puts (": Loading firmware...\n");
  }
#else
  //receive firmware from host
  int file_size = 0;
  char r_fw[] = "firmware.bin";
  if (uart_getc() == FRX) {//file receive: load firmware
    file_size = uart_recvfile(r_fw, prog_start_addr);
    uart_puts (PROGNAME);
    uart_puts (": Loading firmware...\n");
  }
  //sending firmware back for debug
  char s_fw[] = "s_fw.bin";
  if(file_size)
    uart_sendfile(s_fw, file_size, prog_start_addr);
#endif

#ifdef RUN_EXTMEM
  while( !cache_wtb_empty() );
#endif

  // Clear CPU registers, to not pass arguments to the next
  asm volatile("and     a0,a0,zero");
  asm volatile("and     a1,a1,zero");
  asm volatile("and     a2,a2,zero");
  asm volatile("and     a3,a3,zero");
  asm volatile("and     a4,a4,zero");
  asm volatile("and     a5,a5,zero");
  asm volatile("and     a6,a6,zero");
  asm volatile("and     a7,a7,zero");

  //run firmware
  uart_puts (PROGNAME);
  uart_puts (": Restart CPU to run user program...\n");
  uart_putc(DC1);
  uart_txwait();
  //reboot and run firmware (not bootloader)
  *((int *) BOOTCTR_BASE) = 0b10;

}
