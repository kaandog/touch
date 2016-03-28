/** @file rf.h
 *  @brief rf header file
 */

#include "rf_defs.h"

void rf_trx_cmd(uint16_t cmd); 
void rf_trx_cmd_safe(uint16_t cmd); 
void rf_rx_packet(uint8_t *buffer, uint8_t *len);
int rf_tx_packet_nonblocking(uint8_t *buf, uint8_t buf_len);
void rf_init(void *rx_callback, void *tx_callback);
