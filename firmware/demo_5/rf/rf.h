/** @file rf.h
 *  @brief rf header file
 */

#include "rf_defs.h"
#include <stdio.h>
#include <inttypes.h>
#include <avr/io.h>

#define DEBUG 0
#define DEBUG_PRINT(fmt, ...) \
    do { if (DEBUG) printf(fmt, __VA_ARGS__); } while (0)


void rf_sleep(void);
void rf_wake(void);
void rf_rx_on(void);
void rf_trx_cmd(uint16_t cmd);
void rf_trx_cmd_safe(uint16_t cmd);
int rf_tx_packet_nonblocking(uint8_t *buf, uint8_t buf_len);
void rf_init(void *rx_callback, void *tx_callback);
